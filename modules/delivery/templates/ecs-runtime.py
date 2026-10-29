#!/usr/bin/env python3
"""Root-only ECS runtime preparation. Never serialize secret values in logs."""
from __future__ import annotations

import argparse
import importlib.util
import json
import logging
import os
import secrets
import subprocess
import sys
from pathlib import Path
from urllib.parse import quote

import psycopg
from psycopg import sql

BASE = Path("/opt/rag-qa-deploy")
logging.disable(logging.CRITICAL)


def private_write(path: Path, text: str) -> None:
    temporary = path.with_name(path.name + ".new")
    descriptor = os.open(temporary, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(descriptor, "w", encoding="utf-8") as stream:
        stream.write(text)
    os.chmod(temporary, 0o600)
    os.replace(temporary, path)


def database_url(config, username, password):
    return (
        f"postgresql://{quote(username, safe='')}:{quote(password, safe='')}"
        f"@{config['postgres_private_domain']}:{config['postgres_private_port']}"
        f"/{quote(config['postgres_database_name'], safe='')}"
    )


def environment(config, stored):
    values = {
        "DATABASE_URL": database_url(config, "ragapp", stored["db_password"]),
        "DB_SCHEMA_MANAGED": "1",
        "ARK_API_KEY": config["ark_api_key"],
        **{name.upper(): config[name] for name in [
            "ark_base_url", "llm_endpoint_id", "embedding_endpoint_id",
            "embedding_dimensions", "chunk_size", "chunk_overlap", "default_top_k",
            "max_upload_bytes", "max_cosine_distance",
        ]},
    }
    for value in values.values():
        if any(char in str(value) for char in "\r\n\x00"):
            raise ValueError("Invalid environment value")
    return "".join(
        name + '="' + str(value).replace("\\", "\\\\").replace('"', '\\"') + '"\n'
        for name, value in values.items()
    )


def prepare(config):
    runtime = BASE / ".runtime"
    runtime.mkdir(mode=0o700, exist_ok=True)
    os.chmod(runtime, 0o700)
    secret_path = runtime / "secrets.json"
    stored = json.loads(secret_path.read_text()) if secret_path.exists() else None
    if stored and stored["postgres_instance_id"] != config["postgres_instance_id"]:
        raise RuntimeError("Saved credentials belong to a different RDS instance")
    if stored is None:
        stored = {
            "postgres_instance_id": config["postgres_instance_id"],
            "db_password": secrets.token_hex(12) + "Aa1!",
            "web_username": "ragadmin",
            "web_password": secrets.token_urlsafe(24),
        }
        # Save before database changes; retries retain the application password.
        private_write(secret_path, json.dumps(stored, indent=2) + "\n")
    hashed = subprocess.run(
        ["openssl", "passwd", "-apr1", "-stdin"], input=stored["web_password"] + "\n",
        text=True, check=True, capture_output=True,
    ).stdout.strip()
    private_write(runtime / "nginx.htpasswd", f"{stored['web_username']}:{hashed}\n")
    private_write(runtime / "runtime.env", environment(config, stored))


def initialize(config):
    stored = json.loads((BASE / ".runtime/secrets.json").read_text())
    admin_url = database_url(config, config["postgres_admin_username"], config["postgres_admin_password"])
    # Only the initialization process sees admin credentials.
    os.environ.update({
        "DATABASE_URL": admin_url, "EMBEDDING_DIMENSIONS": str(config["embedding_dimensions"]),
        "EMBEDDING_ENDPOINT_ID": config["embedding_endpoint_id"], "DB_SCHEMA_MANAGED": "0",
    })
    spec = importlib.util.spec_from_file_location("qa_schema", BASE / "source/app/main.py")
    application = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(application)
    application.init_db()
    with psycopg.connect(admin_url, autocommit=True, connect_timeout=10) as connection:
        with connection.transaction(), connection.cursor() as cursor:
            cursor.execute("SELECT 1 FROM pg_roles WHERE rolname = 'ragapp'")
            if not cursor.fetchone():
                cursor.execute(sql.SQL("CREATE ROLE ragapp LOGIN PASSWORD {}").format(sql.Literal(stored["db_password"])))
            cursor.execute("ALTER ROLE ragapp NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION")
            cursor.execute(sql.SQL("REVOKE ALL ON DATABASE {} FROM PUBLIC").format(sql.Identifier(config["postgres_database_name"])))
            cursor.execute(sql.SQL("GRANT CONNECT ON DATABASE {} TO ragapp").format(sql.Identifier(config["postgres_database_name"])))
            cursor.execute("REVOKE CREATE ON SCHEMA public FROM PUBLIC")
            cursor.execute("GRANT USAGE ON SCHEMA public TO ragapp")
            cursor.execute("GRANT SELECT, INSERT, UPDATE, DELETE ON knowledge_chunks TO ragapp")
            cursor.execute("GRANT SELECT ON rag_settings TO ragapp")
            cursor.execute("GRANT USAGE, SELECT ON SEQUENCE knowledge_chunks_id_seq TO ragapp")
    # Verify saved password and basic permissions; never reset existing passwords.
    with psycopg.connect(database_url(config, "ragapp", stored["db_password"]), connect_timeout=10) as connection:
        connection.execute("SELECT count(*) FROM knowledge_chunks").fetchone()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=["prepare", "initialize"])
    args = parser.parse_args()
    try:
        if os.geteuid() != 0:
            raise RuntimeError("Root required")
        os.umask(0o077)
        config = json.loads((BASE / "config.json").read_text())
        if args.action == "initialize":
            initialize(config)
        else:
            prepare(config)
        print(f"Runtime {args.action}: ready", flush=True)
    except Exception as error:
        print(f"Runtime {args.action} failed ({type(error).__name__}); credential values omitted.", file=sys.stderr)
        sys.exit(1)
