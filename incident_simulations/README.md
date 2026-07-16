# Incident Simulations - Observability Lab

Scripts para simular incidentes nos containers Rocky Linux 9:

- `node-app-01`
- `node-app-02`

Os scripts ficam montados dentro dos containers em:

```text
/opt/incident_simulations
```

## 1. Stress de CPU e memória

Executar por 5 minutos no `node-app-01`:

```bash
docker exec -it obs-node-app-01 bash
cd /opt/incident_simulations
DURATION=300 CPU_WORKERS=2 MEMORY_WORKERS=1 MEMORY_BYTES=256M ./cpu_memory_stress.sh run
```

Modo mais agressivo:

```bash
DURATION=300 CPU_WORKERS=4 MEMORY_WORKERS=2 MEMORY_BYTES=512M ./cpu_memory_stress.sh heavy
```

Parar processos de stress:

```bash
./cpu_memory_stress.sh stop
```

## 2. Latência e perda de pacotes

O container precisa de `NET_ADMIN`, já configurado no `docker-compose.yml` para `node-app-01` e `node-app-02`.

Aplicar latência e perda por 2 minutos:

```bash
docker exec -it obs-node-app-01 bash
cd /opt/incident_simulations
DURATION=120 LATENCY=700ms JITTER=150ms LOSS=10% ./network_chaos.sh start
```

Ver status:

```bash
./network_chaos.sh status
```

Remover manualmente:

```bash
./network_chaos.sh stop
```

## 3. Gerador de logs falsos de erro

Gerar logs continuamente em `/var/log/app_errors.log`:

```bash
docker exec -it obs-node-app-01 bash
cd /opt/incident_simulations
python3 fake_log_generator.py --interval 1
```

Gerar 100 linhas e encerrar:

```bash
python3 fake_log_generator.py --lines 100 --interval 0.5
```

Acompanhar logs:

```bash
tail -f /var/log/app_errors.log
```

## Validação no Prometheus

Acesse:

```text
http://localhost:9090/targets
```

Targets esperados:

```text
node-app-01:9100
node-app-02:9100
```

## Validação no Grafana

Acesse:

```text
http://localhost:3000
```

Credenciais padrão:

```text
admin / admin_lab_password
```

Use o datasource `Prometheus` para consultar métricas como:

```promql
rate(node_cpu_seconds_total{mode!="idle"}[1m])
node_memory_MemAvailable_bytes
node_network_receive_errs_total
```

## Observação importante

Esses scripts são destinados apenas ao laboratório local. Não execute em ambientes produtivos.
