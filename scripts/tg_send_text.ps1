# Отправка одного текстового сообщения в Telegram-канал через sendMessage (multipart/form-data).
# Запуск: powershell -File scripts\tg_send_text.ps1 -PostFile <путь к txt>
param([Parameter(Mandatory = $true)][string]$PostFile)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Net.Http

$root  = Split-Path -Parent $PSScriptRoot
$cfg   = Get-Content "$root\config\telegram.secure.json" -Raw | ConvertFrom-Json
$token = $cfg.bot_token
$chat  = $cfg.channel
$api   = "https://api.telegram.org/bot$token/sendMessage"

$text = Get-Content $PostFile -Raw -Encoding UTF8

$client = New-Object System.Net.Http.HttpClient
$client.Timeout = [TimeSpan]::FromSeconds(60)

$mp = New-Object System.Net.Http.MultipartFormDataContent
$mp.Add((New-Object System.Net.Http.StringContent($chat, [System.Text.Encoding]::UTF8, "text/plain")), "chat_id")
$mp.Add((New-Object System.Net.Http.StringContent($text, [System.Text.Encoding]::UTF8, "text/plain")), "text")

$resp = $client.PostAsync($api, $mp).Result
Write-Output $resp.Content.ReadAsStringAsync().Result
