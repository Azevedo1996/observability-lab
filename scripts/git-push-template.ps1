# Template para publicar o Observability Lab no GitHub usando Git.
# Execute dentro da raiz do projeto.

param(
    [string]$RepoUrl = "https://github.com/SEU_USUARIO/observability-lab.git",
    [string]$Branch = "main"
)

Write-Host "Inicializando repositório Git..." -ForegroundColor Cyan
git init

git branch -M $Branch

Write-Host "Adicionando arquivos..." -ForegroundColor Cyan
git add .

git commit -m "feat: add complete docker observability lab"

Write-Host "Configurando remote origin..." -ForegroundColor Cyan
git remote remove origin 2>$null
git remote add origin $RepoUrl

Write-Host "Enviando para o GitHub..." -ForegroundColor Cyan
git push -u origin $Branch
