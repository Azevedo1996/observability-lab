# Observability Lab

Laboratório completo de observabilidade para rodar em **Docker no Windows**, construído em etapas com foco em práticas de **DevOps**, **SRE**, containers Linux e ecossistema RHEL/Rocky Linux.

O projeto entrega uma stack local com **Zabbix**, **PostgreSQL**, **Prometheus**, **Grafana**, targets baseados em **Rocky Linux 9** e scripts para simulação de incidentes reais, como gargalo de CPU, pressão de memória, latência de rede, perda de pacotes e geração contínua de logs de erro.

---

## Sumário

- [Objetivo do projeto](#objetivo-do-projeto)
- [Arquitetura](#arquitetura)
- [Serviços incluídos](#serviços-incluídos)
- [Portas utilizadas](#portas-utilizadas)
- [Estrutura de diretórios](#estrutura-de-diretórios)
- [Pré-requisitos](#pré-requisitos)
- [Como subir o laboratório](#como-subir-o-laboratório)
- [Como acessar as ferramentas](#como-acessar-as-ferramentas)
- [Como usar o Prometheus](#como-usar-o-prometheus)
- [Como usar o Grafana](#como-usar-o-grafana)
- [Como configurar o Zabbix](#como-configurar-o-zabbix)
- [Como usar os targets Rocky Linux 9](#como-usar-os-targets-rocky-linux-9)
- [Simulação de incidentes](#simulação-de-incidentes)
- [Exemplos de uso](#exemplos-de-uso)
- [Comandos de operação](#comandos-de-operação)
- [Instruções de restauração](#instruções-de-restauração)
- [Publicação no GitHub usando Git](#publicação-no-github-usando-git)
- [Como o código está organizado](#como-o-código-está-organizado)
- [Troubleshooting](#troubleshooting)
- [Roadmap de melhorias futuras](#roadmap-de-melhorias-futuras)

---

## Objetivo do projeto

O **Observability Lab** foi criado para simular um ambiente realista de observabilidade local, permitindo estudar e praticar:

- monitoramento tradicional com Zabbix;
- métricas em tempo real com Prometheus;
- dashboards e visualização com Grafana;
- coleta de métricas Linux via Node Exporter;
- monitoramento de containers Rocky Linux 9 via Zabbix Agent;
- simulação controlada de incidentes;
- análise de sintomas em CPU, memória, rede e logs;
- operação básica de uma stack Docker Compose no Windows.

O laboratório é útil para estudos de **DevOps**, **SRE**, **infraestrutura Linux**, **observabilidade**, **monitoramento**, **capacidade**, **resposta a incidentes** e **demonstrações técnicas**.

---

## Arquitetura

A stack roda em uma rede Docker bridge customizada chamada `obs-network`.

Fluxo geral:

```text
Windows Host
│
├── Docker Compose
│   │
│   ├── PostgreSQL Zabbix
│   ├── PostgreSQL App/Lab
│   ├── Zabbix Server
│   ├── Zabbix Web Nginx PostgreSQL
│   ├── Prometheus
│   ├── Grafana
│   ├── node-app-01 - Rocky Linux 9 + Zabbix Agent + Node Exporter
│   └── node-app-02 - Rocky Linux 9 + Zabbix Agent + Node Exporter
│
└── Acessos locais
    ├── Zabbix Web: http://localhost:8089
    ├── Prometheus: http://localhost:9090
    └── Grafana: http://localhost:3000
```

Prometheus coleta métricas dos exporters em:

```text
node-app-01:9100
node-app-02:9100
```

Zabbix Server se comunica com os agents em:

```text
node-app-01:10050
node-app-02:10050
```

Grafana é provisionado automaticamente com:

- datasource Prometheus;
- datasource Zabbix;
- plugin Zabbix para Grafana.

---

## Serviços incluídos

| Serviço | Função |
|---|---|
| `postgres-zabbix` | Banco PostgreSQL dedicado ao Zabbix |
| `postgres-app` | Banco PostgreSQL livre para aplicações de teste |
| `zabbix-server` | Backend principal do Zabbix |
| `zabbix-web-nginx-pgsql` | Interface web/API do Zabbix com Nginx e PostgreSQL |
| `prometheus` | Coleta e armazenamento de métricas time-series |
| `grafana` | Dashboards e visualização |
| `node-app-01` | Target Rocky Linux 9 com Zabbix Agent e Node Exporter |
| `node-app-02` | Target Rocky Linux 9 com Zabbix Agent e Node Exporter |

---

## Portas utilizadas

| Porta local | Serviço | URL/uso |
|---:|---|---|
| `3000` | Grafana | `http://localhost:3000` |
| `5432` | PostgreSQL Zabbix | conexão local/administração |
| `5433` | PostgreSQL App | conexão local/administração |
| `8089` | Zabbix Web | `http://localhost:8089` |
| `8443` | Zabbix Web HTTPS | reservado para HTTPS local |
| `9090` | Prometheus | `http://localhost:9090` |
| `10051` | Zabbix Server | trapper/server port |

As portas dos targets não são publicadas no host por padrão. Elas ficam expostas apenas dentro da rede Docker:

```text
node-app-01:10050
node-app-01:9100
node-app-02:10050
node-app-02:9100
```

---

## Estrutura de diretórios

```text
observability-lab/
├── .env
├── .env.example
├── .gitignore
├── README.md
├── docker-compose.yml
├── config/
│   ├── prometheus/
│   │   └── prometheus.yml
│   └── grafana/
│       └── provisioning/
│           ├── dashboards/
│           ├── datasources/
│           │   └── datasources.yml
│           └── plugins/
│               └── zabbix-app.yml
├── docker/
│   ├── custom-images/
│   │   └── rockylinux9/
│   │       └── Dockerfile
│   └── targets/
│       └── rocky-node/
│           ├── Dockerfile
│           ├── config/
│           │   ├── node-exporter/
│           │   │   └── node-exporter.env
│           │   └── zabbix/
│           │       └── zabbix_agentd.conf
│           └── scripts/
│               └── entrypoint.sh
├── incident_simulations/
│   ├── README.md
│   ├── cpu_memory_stress.sh
│   ├── fake_log_generator.py
│   └── network_chaos.sh
├── scripts/
│   ├── build-targets.ps1
│   ├── find-observability-ports.ps1
│   ├── git-push-template.ps1
│   └── reset-lab.ps1
└── volumes/
    ├── grafana/
    ├── postgres-app/
    ├── postgres-zabbix/
    ├── prometheus/
    ├── zabbix-server/
    └── zabbix-web/
```

---

## Pré-requisitos

No Windows:

- Docker Desktop instalado e em execução;
- Docker Compose v2;
- Git instalado;
- PowerShell;
- acesso à internet no primeiro build/pull das imagens.

Verifique:

```powershell
docker version
docker compose version
git --version
```

---

## Como subir o laboratório

Na raiz do projeto:

```powershell
docker compose up -d --build
```

Esse comando:

- cria a rede `obs-network`;
- baixa as imagens oficiais necessárias;
- constrói a imagem customizada dos targets Rocky Linux 9;
- sobe PostgreSQL, Zabbix, Prometheus, Grafana e os dois nodes.

Verificar status:

```powershell
docker compose ps
```

Ver logs gerais:

```powershell
docker compose logs -f
```

Ver logs de um serviço específico:

```powershell
docker compose logs -f prometheus
docker compose logs -f grafana
docker compose logs -f zabbix-server
docker compose logs -f node-app-01
```

---

## Como acessar as ferramentas

### Zabbix

```text
http://localhost:8089
```

Credenciais padrão:

```text
Usuário: Admin
Senha: zabbix
```

### Prometheus

```text
http://localhost:9090
```

Página de targets:

```text
http://localhost:9090/targets
```

### Grafana

```text
http://localhost:3000
```

Credenciais padrão:

```text
Usuário: admin
Senha: admin_lab_password
```

---

## Como usar o Prometheus

O arquivo principal de configuração fica em:

```text
config/prometheus/prometheus.yml
```

Targets configurados:

```yaml
scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets:
          - localhost:9090

  - job_name: rocky-node-targets
    metrics_path: /metrics
    static_configs:
      - targets:
          - node-app-01:9100
          - node-app-02:9100
        labels:
          lab: observability-lab
          os_family: rhel
          base_image: rockylinux9
```

Exemplos de consultas PromQL:

```promql
up
```

```promql
rate(node_cpu_seconds_total{mode!="idle"}[1m])
```

```promql
node_memory_MemAvailable_bytes
```

```promql
rate(node_network_receive_bytes_total[1m])
```

```promql
rate(node_network_transmit_bytes_total[1m])
```

```promql
node_filesystem_avail_bytes
```

---

## Como usar o Grafana

O Grafana já sobe com provisionamento automático.

Arquivo de datasources:

```text
config/grafana/provisioning/datasources/datasources.yml
```

Datasources existentes:

- `Prometheus`
- `Zabbix`

Plugin Zabbix:

```text
alexanderzobnin-zabbix-app
```

### Criar dashboard simples de CPU

1. Acesse `http://localhost:3000`.
2. Entre com `admin / admin_lab_password`.
3. Vá em **Dashboards**.
4. Clique em **New dashboard**.
5. Adicione um painel.
6. Use o datasource `Prometheus`.
7. Use a query:

```promql
100 * avg by (instance) (rate(node_cpu_seconds_total{mode!="idle"}[1m]))
```

### Criar painel de memória disponível

```promql
node_memory_MemAvailable_bytes
```

### Criar painel de tráfego de rede

```promql
rate(node_network_receive_bytes_total[1m])
```

---

## Como configurar o Zabbix

O Zabbix Server e o Zabbix Web já sobem conectados ao PostgreSQL `postgres-zabbix`.

Acesse:

```text
http://localhost:8089
```

Login padrão:

```text
Admin / zabbix
```

### Cadastrar o host `node-app-01`

No frontend do Zabbix:

1. Acesse **Data collection**.
2. Acesse **Hosts**.
3. Clique em **Create host**.
4. Configure:

```text
Host name: node-app-01
Visible name: node-app-01
Groups: Linux servers
```

5. Em **Interfaces**, adicione uma interface do tipo **Agent**:

```text
DNS name: node-app-01
Connect to: DNS
Port: 10050
```

6. Em **Templates**, associe um template Linux compatível, por exemplo:

```text
Linux by Zabbix agent
```

7. Salve.

### Cadastrar o host `node-app-02`

Repita o processo com:

```text
Host name: node-app-02
Visible name: node-app-02
DNS name: node-app-02
Port: 10050
```

Template sugerido:

```text
Linux by Zabbix agent
```

### Observações sobre DNS interno

Os nomes `node-app-01` e `node-app-02` resolvem dentro da rede Docker `obs-network`. Por isso, ao configurar a interface Agent no Zabbix, use **DNS name** em vez de IP fixo.

### Verificar disponibilidade do agent

Dentro do container do Zabbix Server:

```powershell
docker exec -it obs-zabbix-server bash
```

Teste conexão TCP:

```bash
nc -vz node-app-01 10050
nc -vz node-app-02 10050
```

Se `nc` não estiver disponível no container do Zabbix, valide pelo próprio frontend em **Monitoring > Hosts** após alguns minutos.

---

## Como usar os targets Rocky Linux 9

Os targets são construídos a partir de:

```dockerfile
FROM rockylinux:9
```

Dockerfile:

```text
docker/targets/rocky-node/Dockerfile
```

Cada target executa:

- `zabbix_agentd` em foreground;
- `node_exporter` em background controlado pelo entrypoint.

Entrypoint:

```text
docker/targets/rocky-node/scripts/entrypoint.sh
```

Configuração do Zabbix Agent:

```text
docker/targets/rocky-node/config/zabbix/zabbix_agentd.conf
```

Configuração do Node Exporter:

```text
docker/targets/rocky-node/config/node-exporter/node-exporter.env
```

Entrar no container:

```powershell
docker exec -it obs-node-app-01 bash
```

Ver processos:

```bash
ps aux
```

Testar Node Exporter dentro do container:

```bash
curl http://localhost:9100/metrics | head
```

---

## Simulação de incidentes

Os scripts ficam no host em:

```text
incident_simulations/
```

E são montados nos targets em:

```text
/opt/incident_simulations
```

### CPU e memória

Script:

```text
incident_simulations/cpu_memory_stress.sh
```

Executar:

```powershell
docker exec -it obs-node-app-01 bash -lc "cd /opt/incident_simulations && DURATION=180 CPU_WORKERS=2 MEMORY_BYTES=256M ./cpu_memory_stress.sh run"
```

Modo agressivo:

```powershell
docker exec -it obs-node-app-01 bash -lc "cd /opt/incident_simulations && DURATION=300 CPU_WORKERS=4 MEMORY_WORKERS=2 MEMORY_BYTES=512M ./cpu_memory_stress.sh heavy"
```

Parar stress:

```powershell
docker exec -it obs-node-app-01 bash -lc "cd /opt/incident_simulations && ./cpu_memory_stress.sh stop"
```

### Caos de rede

Script:

```text
incident_simulations/network_caos.sh
```

Aplicar latência e perda por 120 segundos:

```powershell
docker exec -it obs-node-app-01 bash -lc "cd /opt/incident_simulations && DURATION=120 LATENCY=700ms JITTER=150ms LOSS=10% ./network_chaos.sh start"
```

Ver status:

```powershell
docker exec -it obs-node-app-01 bash -lc "cd /opt/incident_simulations && ./network_chaos.sh status"
```

Remover regras:

```powershell
docker exec -it obs-node-app-01 bash -lc "cd /opt/incident_simulations && ./network_chaos.sh stop"
```

### Logs falsos de erro

Script:

```text
incident_simulations/fake_log_generator.py
```

Gerar 100 logs:

```powershell
docker exec -it obs-node-app-01 bash -lc "cd /opt/incident_simulations && python3 fake_log_generator.py --lines 100 --interval 0.5"
```

Gerar continuamente:

```powershell
docker exec -it obs-node-app-01 bash -lc "cd /opt/incident_simulations && python3 fake_log_generator.py --interval 1"
```

Acompanhar arquivo:

```powershell
docker exec -it obs-node-app-01 bash -lc "tail -f /var/log/app_errors.log"
```

---

## Exemplos de uso

### Exemplo 1: Validar a stack inteira

```powershell
docker compose up -d --build
docker compose ps
```

Abra:

```text
http://localhost:9090/targets
```

Espere estes targets como `UP`:

```text
prometheus
node-app-01:9100
node-app-02:9100
```

### Exemplo 2: Simular alto consumo de CPU no node-app-01

```powershell
docker exec -it obs-node-app-01 bash -lc "cd /opt/incident_simulations && DURATION=300 CPU_WORKERS=2 ./cpu_memory_stress.sh run"
```

No Prometheus:

```promql
100 * avg by (instance) (rate(node_cpu_seconds_total{mode!="idle"}[1m]))
```

### Exemplo 3: Simular problema de rede no node-app-02

```powershell
docker exec -it obs-node-app-02 bash -lc "cd /opt/incident_simulations && DURATION=180 LATENCY=900ms LOSS=20% ./network_chaos.sh start"
```

Depois veja se há impacto em scrapes do Prometheus:

```text
http://localhost:9090/targets
```

### Exemplo 4: Gerar logs de erro para futura coleta

```powershell
docker exec -it obs-node-app-01 bash -lc "cd /opt/incident_simulations && python3 fake_log_generator.py --lines 500 --interval 0.2"
```

Ver conteúdo:

```powershell
docker exec -it obs-node-app-01 bash -lc "tail -n 20 /var/log/app_errors.log"
```

---

## Comandos de operação

Subir:

```powershell
docker compose up -d --build
```

Parar sem remover dados:

```powershell
docker compose stop
```

Iniciar novamente:

```powershell
docker compose start
```

Parar e remover containers/rede:

```powershell
docker compose down
```

Ver containers:

```powershell
docker compose ps
```

Ver logs:

```powershell
docker compose logs -f
```

Build apenas dos targets:

```powershell
docker compose build --no-cache --progress=plain node-app-01 node-app-02
```

Ver portas em uso no Windows:

```powershell
.\scripts\find-observability-ports.ps1
```

Reset completo do laboratório:

```powershell
.\scripts\reset-lab.ps1
```

---

## Instruções de restauração

### Restauração simples depois de parar o ambiente

Se o ambiente foi parado com `docker compose stop`, restaure com:

```powershell
docker compose start
```

Se foi removido com `docker compose down`, restaure com:

```powershell
docker compose up -d
```

Os dados persistem nas pastas `volumes/`.

### Restauração completa a partir do projeto versionado

1. Clone o repositório:

```powershell
git clone https://github.com/SEU_USUARIO/observability-lab.git
cd observability-lab
```

2. Copie `.env.example` para `.env`, se necessário:

```powershell
Copy-Item .env.example .env
```

3. Suba a stack:

```powershell
docker compose up -d --build
```

### Restaurar dados persistentes

Os dados locais ficam em:

```text
volumes/postgres-zabbix/data/
volumes/postgres-app/data/
volumes/prometheus/data/
volumes/grafana/data/
```

Para backup manual, pare a stack:

```powershell
docker compose down
```

Compacte a pasta `volumes/`:

```powershell
Compress-Archive -Path .\volumes -DestinationPath .\backup-volumes.zip -Force
```

Para restaurar, extraia o backup na raiz do projeto mantendo a estrutura:

```text
observability-lab/volumes/...
```

Depois suba novamente:

```powershell
docker compose up -d
```

### Reset total do laboratório

Atenção: remove dados locais dos bancos, Prometheus e Grafana.

```powershell
.\scripts\reset-lab.ps1
```

Ou manualmente:

```powershell
docker compose down
Remove-Item -Recurse -Force .\volumes\postgres-zabbix\data\* -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force .\volumes\postgres-app\data\* -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force .\volumes\prometheus\data\* -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force .\volumes\grafana\data\* -ErrorAction SilentlyContinue
docker compose up -d --build
```

---

## Como o código está organizado

### `docker-compose.yml`

Arquivo principal da stack. Define:

- rede Docker `obs-network`;
- serviços de banco;
- serviços Zabbix;
- Prometheus;
- Grafana;
- targets Rocky Linux 9;
- permissões `NET_ADMIN` para chaos de rede;
- volumes e portas.

### `config/prometheus/prometheus.yml`

Define os jobs de scrape:

- Prometheus monitorando si mesmo;
- Node Exporter dos containers Rocky Linux 9.

### `config/grafana/provisioning/datasources/datasources.yml`

Provisiona automaticamente:

- datasource Prometheus;
- datasource Zabbix.

### `docker/targets/rocky-node/Dockerfile`

Constrói a imagem dos targets com base em:

```dockerfile
FROM rockylinux:9
```

Instala:

- Zabbix Agent;
- Node Exporter;
- Python 3;
- ferramentas de rede para `tc`/iptables.

### `docker/targets/rocky-node/scripts/entrypoint.sh`

Responsável por iniciar e manter rodando:

- `zabbix_agentd`;
- `node_exporter`.

### `incident_simulations/`

Scripts práticos para gerar incidentes controlados.

---

## Troubleshooting

### Porta já está em uso

Erro comum:

```text
Bind for 0.0.0.0:8080 failed: port is already allocated
```

Este projeto usa Zabbix Web na porta `8089` para evitar conflito com `8080`.

Verificar portas:

```powershell
.\scripts\find-observability-ports.ps1
```

### PostgreSQL unhealthy

Se o PostgreSQL não inicializar, confira se as pastas abaixo estão vazias no primeiro start:

```text
volumes/postgres-zabbix/data/
volumes/postgres-app/data/
```

Não coloque `.gitkeep` nem outros arquivos dentro dessas pastas.

### Build dos targets falha no DNF

Rode com logs detalhados:

```powershell
docker compose build --no-cache --progress=plain node-app-01
```

Se o erro for temporário de mirror/rede, tente novamente após alguns minutos:

```powershell
docker compose build --no-cache node-app-01 node-app-02
```

### Prometheus não mostra targets UP

Verifique:

```powershell
docker compose ps
docker compose logs -f prometheus
docker compose logs -f node-app-01
```

Acesse:

```text
http://localhost:9090/targets
```

### Grafana não instala plugin Zabbix

Verifique os logs:

```powershell
docker compose logs -f grafana
```

Se necessário, remova o volume do Grafana e suba novamente:

```powershell
docker compose down
Remove-Item -Recurse -Force .\volumes\grafana\data\* -ErrorAction SilentlyContinue
docker compose up -d grafana
```

---

## Roadmap de melhorias futuras

### Curto prazo

- Criar dashboards Grafana versionados em JSON.
- Provisionar dashboards automaticamente no Grafana.
- Criar templates Zabbix customizados para os containers Rocky Linux 9.
- Automatizar cadastro de `node-app-01` e `node-app-02` no Zabbix via API.
- Adicionar healthchecks mais detalhados para Zabbix Web, Grafana e Prometheus.
- Criar Makefile ou Taskfile para simplificar comandos.
- Adicionar script único `lab.ps1` com ações `up`, `down`, `reset`, `logs`, `status` e `simulate`.

### Médio prazo

- Adicionar Alertmanager ao Prometheus.
- Criar regras de alerta Prometheus para CPU, memória, disponibilidade e scrape failures.
- Integrar Grafana Alerting com alertas simulados.
- Adicionar Loki e Promtail para ingestão dos logs de `/var/log/app_errors.log`.
- Criar dashboards correlacionando métricas e logs.
- Adicionar Blackbox Exporter para testes HTTP/TCP.
- Adicionar cAdvisor para métricas de containers.
- Adicionar Postgres Exporter para monitorar os bancos PostgreSQL.
- Adicionar Zabbix Agent 2 como alternativa ao Zabbix Agent clássico.

### Longo prazo

- Criar pipeline GitHub Actions para validar YAML e Docker Compose.
- Criar testes automatizados de laboratório usando scripts PowerShell.
- Criar release versionada no GitHub com artefatos `.zip`.
- Adicionar suporte opcional a Docker Swarm.
- Adicionar suporte opcional a Kubernetes com Helm.
- Criar documentação com diagramas de arquitetura.
- Criar playbooks de incident response.
- Criar relatórios de pós-incidente simulados.
- Adicionar autenticação e boas práticas de secrets para uso fora de laboratório.
- Criar modo de observabilidade distribuída com múltiplos hosts.

### Ideias de evolução SRE

- Definir SLIs e SLOs para os serviços do laboratório.
- Criar error budgets simulados.
- Criar runbooks para incidentes de CPU, memória, rede e logs.
- Simular degradação progressiva e recuperação automática.
- Criar exercícios de GameDay.
- Criar cenários de chaos engineering controlados.

---

## Segurança e escopo

Este projeto é para uso local/laboratorial.

Não use as senhas padrão em ambiente real.

Antes de usar fora do laboratório:

- altere todas as senhas;
- revise portas expostas;
- configure TLS;
- configure secrets adequados;
- limite permissões de containers;
- avalie a necessidade de `NET_ADMIN`;
- não exponha Zabbix, Prometheus ou Grafana diretamente na internet.

---

## Licença


```text
MIT License
```
---

## Status do projeto

Versão final inicial do laboratório:

```text
Parte 1: Infraestrutura base e bancos
Parte 2: Zabbix
Parte 3: Prometheus e Grafana
Parte 4: Targets Rocky Linux 9
Parte 5: Simulação de incidentes SRE
```

