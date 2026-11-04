# Публикация истории №5 «Финтакса и ипотека Порфирия Сергеевича» в Telegram двумя сообщениями:
#   1) sendPhoto: картинка + часть 1 (подпись)
#   2) sendMessage: часть 2 (текст)
# Обе отправки — multipart/form-data через System.Net.Http.HttpClient.
# Запуск: powershell -File scripts\tg_publish_story5.ps1
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Net.Http

$root    = Split-Path -Parent $PSScriptRoot
$cfg     = Get-Content "$root\config\telegram.secure.json" -Raw | ConvertFrom-Json
$token   = $cfg.bot_token
$chat    = $cfg.channel          # @fintaxa_explains
$apiBase = "https://api.telegram.org/bot$token"

$imgPath = "$root\images\FinTaxa объясняет имущественный вычет.png"
$part1   = Get-Content "$root\posts\2026-11-04_porfiriy-vychety_tg_part1.txt" -Raw -Encoding UTF8
$part2   = Get-Content "$root\posts\2026-11-04_porfiriy-vychety_tg_part2.txt" -Raw -Encoding UTF8

if ($part1.Length -gt 1024) { throw "Подпись превышает 1024 символа: $($part1.Length)" }
if ($part2.Length -gt 4096) { throw "Текст превышает 4096 символов: $($part2.Length)" }

function Invoke-TelegramMultipart([string]$method, [hashtable]$fields, [hashtable]$files) {
    $client = New-Object System.Net.Http.HttpClient
    $client.Timeout = [TimeSpan]::FromSeconds(60)
    try {
        $mp = New-Object System.Net.Http.MultipartFormDataContent
        foreach ($k in $fields.Keys) {
            $mp.Add((New-Object System.Net.Http.StringContent([string]$fields[$k], [System.Text.Encoding]::UTF8, "text/plain")), $k)
        }
        foreach ($k in $files.Keys) {
            $bytes = [System.IO.File]::ReadAllBytes($files[$k])
            $bc = New-Object System.Net.Http.ByteArrayContent (,$bytes)
            $bc.Headers.ContentType = New-Object System.Net.Http.Headers.MediaTypeHeaderValue "image/png"
            $mp.Add($bc, $k, [System.IO.Path]::GetFileName($files[$k]))
        }
        $resp = $client.PostAsync("https://api.telegram.org/bot$token/$method", $mp).Result
        return $resp.Content.ReadAsStringAsync().Result
    } finally {
        $client.Dispose()
    }
}

# --- сообщение 1: фото + подпись ---
$j1 = Invoke-TelegramMultipart "sendPhoto" @{
    chat_id = $chat
    caption = $part1
} @{ photo = $imgPath }
Write-Output "sendPhoto: $j1"

# --- сообщение 2: текст (без parse_mode — чистый текст) ---
$j2 = Invoke-TelegramMultipart "sendMessage" @{
    chat_id = $chat
    text    = $part2
} @{}
Write-Output "sendMessage: $j2"