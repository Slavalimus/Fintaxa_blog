# Публикация истории №3 (Пять ступенек налога) в Telegram двумя сообщениями:
#   1) sendPhoto: картинка + часть 1 (подпись, лимит 1024)
#   2) sendMessage: часть 2 (текст, лимит 4096)
# Запуск: powershell -File scripts\tg_publish_story3.ps1
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Net.Http

$root    = Split-Path -Parent $PSScriptRoot
$cfg     = Get-Content "$root\config\telegram.secure.json" -Raw | ConvertFrom-Json
$token   = $cfg.bot_token
$chat    = $cfg.channel          # @fintaxa_explains
$apiBase = "https://api.telegram.org/bot$token"

$imgPath  = "$root\images\Прогрессивная шкала НДФЛ с ФинТаксой.png"
$part1    = Get-Content "$root\posts\2026-11-01_pyat-stavok-ndfl_tg_part1.txt" -Raw -Encoding UTF8
$part2    = Get-Content "$root\posts\2026-11-01_pyat-stavok-ndfl_tg_part2.txt" -Raw -Encoding UTF8

Write-Output ("caption_len=" + $part1.Length + " part2_len=" + $part2.Length)

# --- сообщение 1: фото + подпись (multipart через HttpClient) ---
$client = New-Object System.Net.Http.HttpClient
$client.Timeout = [TimeSpan]::FromSeconds(60)

$mp = New-Object System.Net.Http.MultipartFormDataContent
$mp.Add((New-Object System.Net.Http.StringContent($chat, [System.Text.Encoding]::UTF8, "text/plain")), "chat_id")
$mp.Add((New-Object System.Net.Http.StringContent($part1, [System.Text.Encoding]::UTF8, "text/plain")), "caption")
$mp.Add((New-Object System.Net.Http.StringContent("HTML", [System.Text.Encoding]::UTF8, "text/plain")), "parse_mode")
$bytes = [System.IO.File]::ReadAllBytes($imgPath)
$bc = New-Object System.Net.Http.ByteArrayContent (,$bytes)
$bc.Headers.ContentType = New-Object System.Net.Http.Headers.MediaTypeHeaderValue "image/png"
$mp.Add($bc, "photo", [System.IO.Path]::GetFileName($imgPath))

$resp1 = $client.PostAsync("$apiBase/sendPhoto", $mp).Result
$j1 = $resp1.Content.ReadAsStringAsync().Result
Write-Output "sendPhoto: $j1"
$client.Dispose()

# --- сообщение 2: текст (multipart через HttpClient, в PS 5.1 JSON-POST падает в 413) ---
$client2 = New-Object System.Net.Http.HttpClient
$client2.Timeout = [TimeSpan]::FromSeconds(60)
$mp2 = New-Object System.Net.Http.MultipartFormDataContent
$mp2.Add((New-Object System.Net.Http.StringContent($chat, [System.Text.Encoding]::UTF8, "text/plain")), "chat_id")
$mp2.Add((New-Object System.Net.Http.StringContent($part2, [System.Text.Encoding]::UTF8, "text/plain")), "text")
$mp2.Add((New-Object System.Net.Http.StringContent("HTML", [System.Text.Encoding]::UTF8, "text/plain")), "parse_mode")
$resp2 = $client2.PostAsync("$apiBase/sendMessage", $mp2).Result
$j2 = $resp2.Content.ReadAsStringAsync().Result
Write-Output "sendMessage: $j2"
$client2.Dispose()
