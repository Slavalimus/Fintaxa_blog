# Публикация истории №2 в Telegram двумя сообщениями:
#   1) sendPhoto: картинка + часть 1 (подпись)
#   2) sendMessage: часть 2 (текст)
# Запуск: powershell -File scripts\tg_publish_story2.ps1
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Net.Http

$root    = Split-Path -Parent $PSScriptRoot
$cfg     = Get-Content "$root\config\telegram.secure.json" -Raw | ConvertFrom-Json
$token   = $cfg.bot_token
$chat    = $cfg.channel          # @fintaxa_explains
$apiBase = "https://api.telegram.org/bot$token"

$imgPath  = "$root\images\Налоги с FinTaxa_ всё понятно.png"
$part1    = Get-Content "$root\posts\2026-10-31_nalogi-ne-strashno_tg_part1.txt" -Raw -Encoding UTF8
$part2    = Get-Content "$root\posts\2026-10-31_nalogi-ne-strashno_tg_part2.txt" -Raw -Encoding UTF8

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

# --- сообщение 2: текст ---
$body = @{ chat_id = $chat; text = $part2; parse_mode = "HTML" } | ConvertTo-Json -Compress -Depth 5
$utf8 = [System.Text.Encoding]::UTF8.GetBytes($body)
$req = [System.Net.HttpWebRequest]::Create("$apiBase/sendMessage")
$req.Method = "POST"
$req.ContentType = "application/json; charset=utf-8"
$req.ContentLength = $utf8.Length
$stream = $req.GetRequestStream()
$stream.Write($utf8, 0, $utf8.Length)
$stream.Close()
$resp2 = $req.GetResponse()
$reader = New-Object System.IO.StreamReader $resp2.GetResponseStream()
$j2 = $reader.ReadToEnd()
$reader.Close()
Write-Output "sendMessage: $j2"
