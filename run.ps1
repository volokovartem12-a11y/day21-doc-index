# run.ps1 — индексация документов и сравнение стратегий chunking (день 21).
#
#   .\run.ps1                                  # индексация + сравнение, эмбеддинги локально (ключ не нужен)
#   .\run.ps1 -Backend aitunnel                # то же с эмбеддингами AITunnel (ключ спросит скрыто)
#   .\run.ps1 -Mode search -Query "как защититься от записи за пределы output"
#
# Свои документы (.md, .txt, .py, .pdf) можно положить в папку docs\.
# Если Windows блокирует запуск:
#   powershell -ExecutionPolicy Bypass -File .\run.ps1

param(
    [ValidateSet("all", "build", "compare", "search")]
    [string]$Mode = "all",
    [ValidateSet("local", "aitunnel")]
    [string]$Backend = "local",
    [string]$Model = "",
    [string]$Query = ""
)

Set-Location $PSScriptRoot

function Find-Python {
    foreach ($candidate in @("py", "python",
        "$env:LOCALAPPDATA\Microsoft\WindowsApps\PythonSoftwareFoundation.Python.3.12_qbz5n2kfra8p0\python.exe")) {
        try {
            $output = & $candidate --version 2>&1
            if ($output -match "Python \d") { return $candidate }
        }
        catch { }
    }
    return $null
}

$py = Find-Python
if (-not $py) {
    Write-Host "Python не найден. Установите Python 3 с python.org или из Microsoft Store." -ForegroundColor Red
    exit 1
}
Write-Host "Использую Python: $py" -ForegroundColor Green

Write-Host "Устанавливаю зависимости..." -ForegroundColor Cyan
& $py -m pip install -r requirements.txt --quiet --disable-pip-version-check

if ($Backend -eq "aitunnel" -and -not $env:AITUNNEL_API_KEY) {
    $secureKey = Read-Host "Введите ваш AITUNNEL_API_KEY" -AsSecureString
    $env:AITUNNEL_API_KEY = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKey)
    )
}
if ($Model) { $env:AITUNNEL_EMBED_MODEL = $Model }

if ($Mode -eq "search") {
    if (-not $Query) { Write-Host "Укажите -Query ""текст запроса""" -ForegroundColor Yellow; exit 1 }
    & $py .\search.py $Query --backend $Backend
    exit
}
if ($Mode -in @("all", "build"))   { & $py .\build_index.py --backend $Backend; if ($LASTEXITCODE -ne 0) { exit 1 } }
if ($Mode -in @("all", "compare")) { & $py .\compare.py --backend $Backend }
