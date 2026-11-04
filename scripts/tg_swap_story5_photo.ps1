# Замена фото в сообщении 19 истории №5 (editMessageMedia, multipart/form-data).
# Подпись сохраняется — caption не передаётся.
# Запуск: powershell -File scripts\tg_swap_story5_photo.ps1
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Net.Http

$root    = Split-Path -Parent $PSScriptRoot
$cfg     = Get-Content "$root\config\telegram.secure.json" -Raw | ConvertFrom-Json
$token   = $cfg.bot_token

$imgPath = "$root\images\ФинТакса объясняет жилищные вычеты.png"
$messageId = 19

$media = '{"type":"photo","media":"attach://photo"}'

$client = New-Object System.Net.Http.HttpClient
$client.Timeout = [TimeSpan]::FromSeconds(60)
try {
    $mp = New-Object System.Net.Http.MultipartFormDataContent
    $mp.Add((New-Object System.Net.Http.StringContent("@fintaxa_explains", [System.Text.Encoding]::UTF8, "text/plain")), "chat_id")
    $mp.Add((New-Object System.Net.Http.StringContent("$messageId", [System.Text.Encoding]::UTF8, "text/plain")), "message_id")
    $mp.Add((New-Object System.Net.Http.StringContent($media, [System.Text.Encoding]::UTF8, "text/plain")), "media")
    $bytes = [System.IO.File]::ReadAllBytes($imgPath)
    $bc = New-Object System.Net.Http.ByteArrayContent (,$bytes)
    $bc.Headers.ContentType = New-Object System.Net.Http.Headers.MediaTypeHeaderValue "image/png"
    $mp.Add($bc, "photo", [System.IO.Path]::GetFileName($imgPath))
    $resp = $client.PostAsync("https://api.telegram.org/bot$token/editMessageMedia", $mp).Result
    Write-Output "editMessageMedia: $($resp.Content.ReadAsStringAsync().Result)"
} finally {
    $client.Dispose()
}