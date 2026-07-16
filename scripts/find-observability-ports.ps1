# Verifica as portas usadas pelo Observability Lab no Windows.
$ports = 3000, 5432, 5433, 8089, 8443, 9090, 10051
foreach ($port in $ports) {
    Write-Host "`nPorta $port" -ForegroundColor Cyan
    $conn = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
    if ($conn) {
        $conn | Select-Object LocalAddress, LocalPort, State, OwningProcess
        $conn | ForEach-Object {
            Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue | Select-Object Id, ProcessName, Path
        }
    } else {
        Write-Host "Livre ou sem conexao TCP ativa."
    }
}
