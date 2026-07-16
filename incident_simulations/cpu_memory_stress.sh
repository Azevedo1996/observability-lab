#!/usr/bin/env bash
set -euo pipefail

DURATION="${DURATION:-300}"
CPU_WORKERS="${CPU_WORKERS:-2}"
MEMORY_WORKERS="${MEMORY_WORKERS:-1}"
MEMORY_BYTES="${MEMORY_BYTES:-256M}"
MODE="${1:-run}"

usage() {
  cat <<USAGE
Observability Lab - CPU/Memory Stress

Uso:
  ./cpu_memory_stress.sh [run|light|heavy|stop]

Variáveis opcionais:
  DURATION=300          Duração em segundos
  CPU_WORKERS=2         Quantidade de workers de CPU
  MEMORY_WORKERS=1      Quantidade de workers de memória
  MEMORY_BYTES=256M     Memória por worker

Exemplos:
  DURATION=180 CPU_WORKERS=2 MEMORY_BYTES=256M ./cpu_memory_stress.sh run
  ./cpu_memory_stress.sh heavy
  ./cpu_memory_stress.sh stop
USAGE
}

stop_stress() {
  echo "[cpu_memory_stress] Encerrando processos de stress existentes..."
  pkill -f "stress-ng" 2>/dev/null || true
  pkill -f "observability-lab-cpu-fallback" 2>/dev/null || true
  pkill -f "observability-lab-memory-fallback" 2>/dev/null || true
}

fallback_cpu() {
  local end=$((SECONDS + DURATION))
  exec -a observability-lab-cpu-fallback bash -c "while [ \$SECONDS -lt $end ]; do :; done"
}

fallback_memory() {
  exec -a observability-lab-memory-fallback python3 - <<PY
import time
import re
import os

duration = int(os.environ.get('DURATION', '$DURATION'))
mem = os.environ.get('MEMORY_BYTES', '$MEMORY_BYTES').strip().upper()
match = re.match(r'^(\d+)([KMG]?)$', mem)
if not match:
    size = 256 * 1024 * 1024
else:
    value = int(match.group(1))
    unit = match.group(2)
    factor = {'': 1, 'K': 1024, 'M': 1024**2, 'G': 1024**3}[unit]
    size = value * factor
block = bytearray(size)
for i in range(0, len(block), 4096):
    block[i] = 1
time.sleep(duration)
PY
}

run_fallback() {
  echo "[cpu_memory_stress] stress-ng não encontrado. Usando fallback com bash/python3."
  for _ in $(seq 1 "$CPU_WORKERS"); do
    fallback_cpu &
  done
  for _ in $(seq 1 "$MEMORY_WORKERS"); do
    fallback_memory &
  done
  wait
}

case "$MODE" in
  help|-h|--help)
    usage
    exit 0
    ;;
  stop)
    stop_stress
    exit 0
    ;;
  light)
    DURATION="${DURATION:-180}"
    CPU_WORKERS=1
    MEMORY_WORKERS=1
    MEMORY_BYTES=128M
    ;;
  heavy)
    DURATION="${DURATION:-300}"
    CPU_WORKERS="${CPU_WORKERS:-4}"
    MEMORY_WORKERS="${MEMORY_WORKERS:-2}"
    MEMORY_BYTES="${MEMORY_BYTES:-512M}"
    ;;
  run)
    ;;
  *)
    usage
    exit 1
    ;;
esac

echo "[cpu_memory_stress] Iniciando stress: duration=${DURATION}s cpu=${CPU_WORKERS} mem-workers=${MEMORY_WORKERS} mem=${MEMORY_BYTES}"

if command -v stress-ng >/dev/null 2>&1; then
  stress-ng \
    --cpu "$CPU_WORKERS" \
    --vm "$MEMORY_WORKERS" \
    --vm-bytes "$MEMORY_BYTES" \
    --timeout "${DURATION}s" \
    --metrics-brief
else
  run_fallback
fi

echo "[cpu_memory_stress] Finalizado."
