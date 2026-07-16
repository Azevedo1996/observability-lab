#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-start}"
IFACE="${IFACE:-eth0}"
LATENCY="${LATENCY:-500ms}"
JITTER="${JITTER:-100ms}"
LOSS="${LOSS:-10%}"
DURATION="${DURATION:-0}"

usage() {
  cat <<USAGE
Observability Lab - Network Chaos

Uso:
  ./network_chaos.sh [start|stop|status]

Variáveis opcionais:
  IFACE=eth0       Interface de rede do container
  LATENCY=500ms    Latência artificial
  JITTER=100ms     Variação da latência
  LOSS=10%         Perda de pacotes
  DURATION=0       Se maior que zero, remove automaticamente após N segundos

Exemplos:
  LATENCY=800ms LOSS=15% ./network_chaos.sh start
  DURATION=120 LATENCY=300ms LOSS=5% ./network_chaos.sh start
  ./network_chaos.sh status
  ./network_chaos.sh stop
USAGE
}

require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "[network_chaos] Execute como root dentro do container."
    exit 1
  fi
}

require_tc() {
  if ! command -v tc >/dev/null 2>&1; then
    echo "[network_chaos] Comando tc não encontrado. Instale o pacote iproute-tc na imagem."
    exit 1
  fi
}

start_chaos() {
  echo "[network_chaos] Aplicando netem em ${IFACE}: delay=${LATENCY} jitter=${JITTER} loss=${LOSS}"
  tc qdisc del dev "$IFACE" root 2>/dev/null || true
  tc qdisc add dev "$IFACE" root netem delay "$LATENCY" "$JITTER" loss "$LOSS"
  tc qdisc show dev "$IFACE"

  if [ "$DURATION" -gt 0 ] 2>/dev/null; then
    echo "[network_chaos] Duração configurada: ${DURATION}s. Removendo automaticamente ao final."
    sleep "$DURATION"
    stop_chaos
  fi
}

stop_chaos() {
  echo "[network_chaos] Removendo regras netem de ${IFACE}..."
  tc qdisc del dev "$IFACE" root 2>/dev/null || true
  tc qdisc show dev "$IFACE"
}

status_chaos() {
  tc qdisc show dev "$IFACE"
}

case "$ACTION" in
  start)
    require_root
    require_tc
    start_chaos
    ;;
  stop)
    require_root
    require_tc
    stop_chaos
    ;;
  status)
    require_tc
    status_chaos
    ;;
  help|-h|--help)
    usage
    ;;
  *)
    usage
    exit 1
    ;;
esac
