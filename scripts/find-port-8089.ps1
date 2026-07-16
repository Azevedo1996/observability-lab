# Mostra qual processo esta usando a porta 8089 no Windows, caso exista conflito.
Get-NetTCPConnection -LocalPort 8089 -ErrorAction SilentlyContinue | Select-Object LocalAddress,LocalPort,State,OwningProcess
Get-Process -Id (Get-NetTCPConnection -LocalPort 8089 -ErrorAction SilentlyContinue).OwningProcess -ErrorAction SilentlyContinue | Select-Object Id,ProcessName,Path
