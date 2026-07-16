#!/usr/bin/env bash
set -euo pipefail

ZBX_SERVER_HOST="${ZBX_SERVER_HOST:-zabbix-server}"
ZBX_SERVER_PORT="${ZBX_SERVER_PORT:-10051}"
ZBX_AGENT_HOSTNAME="${ZBX_AGENT_HOSTNAME:-$(hostname)}"
NODE_EXPORTER_LISTEN_ADDRESS="${NODE_EXPORTER_LISTEN_ADDRESS:-:9100}"

sed -i "s/^Server=.*/Server=${ZBX_SERVER_HOST}/" /etc/zabbix/zabbix_agentd.conf
sed -i "s/^ServerActive=.*/ServerActive=${ZBX_SERVER_HOST}:${ZBX_SERVER_PORT}/" /etc/zabbix/zabbix_agentd.conf
sed -i "s/^Hostname=.*/Hostname=${ZBX_AGENT_HOSTNAME}/" /etc/zabbix/zabbix_agentd.conf

mkdir -p /var/run/zabbix /var/log/zabbix
chown -R zabbix:zabbix /var/run/zabbix /var/log/zabbix

_term() {
  echo "[entrypoint] Encerrando agentes..."
  kill -TERM "${ZBX_PID:-0}" 2>/dev/null || true
  kill -TERM "${NODE_PID:-0}" 2>/dev/null || true
  wait "${ZBX_PID:-0}" 2>/dev/null || true
  wait "${NODE_PID:-0}" 2>/dev/null || true
}
trap _term TERM INT

echo "[entrypoint] Iniciando Zabbix Agent: hostname=${ZBX_AGENT_HOSTNAME}, server=${ZBX_SERVER_HOST}:${ZBX_SERVER_PORT}"
zabbix_agentd -f -c /etc/zabbix/zabbix_agentd.conf &
ZBX_PID=$!

echo "[entrypoint] Iniciando Prometheus Node Exporter em ${NODE_EXPORTER_LISTEN_ADDRESS}"
/usr/local/bin/node_exporter --web.listen-address="${NODE_EXPORTER_LISTEN_ADDRESS}" &
NODE_PID=$!

wait -n "$ZBX_PID" "$NODE_PID"
EXIT_CODE=$?
_term
exit "$EXIT_CODE"
