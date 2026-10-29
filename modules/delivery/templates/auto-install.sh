#!/usr/bin/env bash
set -euo pipefail
umask 077
export DEBIAN_FRONTEND=noninteractive
BASE_DIR=/opt/rag-qa-deploy
[[ "$(id -u)" == 0 ]] || exit 1
cd "$BASE_DIR"
exec 9>/run/rag-qa-install.lock
flock -n 9 || exit 0
stage=starting
trap 'printf "failed: %s\n" "$stage" > "$BASE_DIR/STATUS"; echo "Installation failed at $stage; systemd will retry." >&2' ERR
progress() { stage="$1"; printf '%s\n' "$stage" > STATUS; echo "[install] $stage"; }

# Successful boots are idempotent; a failed health check triggers recovery.
if [[ -f installed.sha256 ]] && cmp -s installed.sha256 source.sha256 &&
   [[ -f installed-config.sha256 ]] &&
   [[ "$(sha256sum config.json | cut -d ' ' -f 1)" == "$(cat installed-config.sha256)" ]] &&
  systemctl is-active --quiet nginx rag-qa.service &&
   curl -fsS --max-time 10 http://127.0.0.1:8000/healthz >/dev/null 2>&1; then
  progress ready
  exit 0
fi
progress packages
apt-get update
apt-get install -y ca-certificates curl nginx openssh-server openssl python3 python3-venv
id ragqa >/dev/null 2>&1 || useradd --system --home-dir "$BASE_DIR" --shell /usr/sbin/nologin ragqa
progress dependencies
version="$(cat source.sha256)"
install -d -m 0755 releases
target="$BASE_DIR/releases/$version"
if [[ ! -f "$target/dependencies.ready" ]]; then
  rm -rf "$target"
  install -d -m 0755 "$target"
  cp -R source/app "$target/app"
  python3 -m venv "$target/.venv"
  "$target/.venv/bin/python" -m pip install --disable-pip-version-check \
    -r source/app/requirements.txt
  touch "$target/dependencies.ready"
  chmod -R u=rwX,go=rX "$target"
fi
progress credentials
"$target/.venv/bin/python" source/scripts/ecs-runtime.py prepare
progress database
"$target/.venv/bin/python" source/scripts/ecs-runtime.py initialize
install -o root -g www-data -m 0640 .runtime/nginx.htpasswd /etc/nginx/.htpasswd

progress services
cat > /etc/nginx/sites-available/rag-qa <<'NGINX'
server {
    listen 80 default_server;
    server_name _;
    client_max_body_size 21m;
    server_tokens off;
    location / {
        auth_basic "Enterprise QA";
        auth_basic_user_file /etc/nginx/.htpasswd;
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 600s;
    }
}
NGINX
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/rag-qa /etc/nginx/sites-enabled/rag-qa
nginx -t
cat > /etc/systemd/system/rag-qa.service <<'UNIT'
[Unit]
Description=Enterprise knowledge QA service
After=network-online.target
Wants=network-online.target
[Service]
Type=simple
User=ragqa
Group=ragqa
WorkingDirectory=/opt/rag-qa-deploy/release/app
EnvironmentFile=/opt/rag-qa-deploy/.runtime/runtime.env
Environment=PYTHONDONTWRITEBYTECODE=1
ExecStart=/opt/rag-qa-deploy/release/.venv/bin/python -m uvicorn main:app --host 127.0.0.1 --port 8000 --no-access-log
Restart=on-failure
RestartSec=5
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
UMask=0077
# Only the root credential service may access instance metadata.
IPAddressDeny=100.96.0.96/32
[Install]
WantedBy=multi-user.target
UNIT
systemctl stop rag-qa.service 2>/dev/null || true
# Stable version paths avoid broken venv shebangs; preserve prior versions.
if [[ -d release && ! -L release ]]; then
  mv release "release-legacy-$(date +%s)"
fi
ln -sfn "$target" release-next
mv -Tf release-next release
systemctl daemon-reload
systemctl enable --now nginx ssh rag-qa.service
systemctl restart rag-qa.service
systemctl reload nginx
progress health
for _ in $(seq 1 40); do
  if curl -fsS --max-time 10 http://127.0.0.1:8000/healthz >/dev/null 2>&1; then
    systemctl is-active --quiet nginx rag-qa.service
    cp source.sha256 installed.sha256
    sha256sum config.json | cut -d ' ' -f 1 > installed-config.sha256
    progress ready
    exit 0
  fi
  sleep 3
done
echo "Database health check timed out." >&2
false
