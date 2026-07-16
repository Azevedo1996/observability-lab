#!/usr/bin/env python3
import argparse
import datetime as dt
import json
import os
import random
import signal
import socket
import sys
import time

RUNNING = True

ERROR_MESSAGES = [
    "database connection timeout",
    "payment gateway returned HTTP 503",
    "cache miss storm detected",
    "failed to process job from queue",
    "unexpected null pointer in request handler",
    "upstream dependency latency threshold exceeded",
    "authentication provider unavailable",
    "disk write retry limit reached",
]

SEVERITIES = ["ERROR", "CRITICAL", "WARN"]


def handle_stop(signum, frame):
    global RUNNING
    RUNNING = False


def build_event(app_name: str) -> dict:
    now = dt.datetime.now(dt.timezone.utc).astimezone().isoformat()
    severity = random.choices(SEVERITIES, weights=[70, 10, 20], k=1)[0]
    return {
        "timestamp": now,
        "level": severity,
        "app": app_name,
        "host": socket.gethostname(),
        "event_id": random.randint(1000, 9999),
        "message": random.choice(ERROR_MESSAGES),
        "request_id": f"req-{random.randint(100000, 999999)}",
        "latency_ms": random.randint(250, 5000),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Gerador simples de logs falsos de erro para o Observability Lab.")
    parser.add_argument("--file", default="/var/log/app_errors.log", help="Arquivo de destino dos logs")
    parser.add_argument("--interval", type=float, default=float(os.getenv("LOG_INTERVAL", "1.0")), help="Intervalo entre logs em segundos")
    parser.add_argument("--app", default=os.getenv("APP_NAME", "demo-rocky-app"), help="Nome lógico da aplicação")
    parser.add_argument("--lines", type=int, default=0, help="Quantidade de linhas. 0 = contínuo")
    args = parser.parse_args()

    signal.signal(signal.SIGTERM, handle_stop)
    signal.signal(signal.SIGINT, handle_stop)

    os.makedirs(os.path.dirname(args.file), exist_ok=True)
    count = 0

    print(f"[fake_log_generator] Gerando logs em {args.file}. interval={args.interval}s lines={args.lines or 'infinito'}", flush=True)

    with open(args.file, "a", encoding="utf-8") as fp:
        while RUNNING:
            event = build_event(args.app)
            fp.write(json.dumps(event, ensure_ascii=False) + "\n")
            fp.flush()
            count += 1
            if args.lines and count >= args.lines:
                break
            time.sleep(args.interval)

    print(f"[fake_log_generator] Finalizado. Linhas geradas: {count}", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
