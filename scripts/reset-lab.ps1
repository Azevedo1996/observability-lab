# Reset completo dos dados locais do Observability Lab.
# Execute dentro da pasta do projeto, no PowerShell.

docker compose down

Remove-Item -Recurse -Force .\volumes\postgres-zabbix\data\* -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force .\volumes\postgres-app\data\* -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force .\volumes\prometheus\data\* -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force .\volumes\grafana\data\* -ErrorAction SilentlyContinue

docker compose up -d --build
