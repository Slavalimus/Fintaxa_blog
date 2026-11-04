# Переделка истории №5 в Telegram: новый расклад текста.
#   msg 19 (фото) — editMessageCaption: подпись ~26% текста (лимит 1024)
#   msg 20 (текст) — editMessageText: остальное
# Тексты берутся из posts/2026-11-04_porfiriy-vychety_tg_part1.txt и _tg_part2.txt
# Запуск: powershell -File scripts\tg_resplit_story5.ps1
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Net.Http

$root  = Split-Path -Parent $PSScriptRoot
$cfg   = Get-Content "$root\config\telegram.secure.json" -Raw | ConvertFrom-Json
$token = $cfg.bot_token

$part1 = (Get-Content "$root\posts\2026-11-04_porfiriy-vychety_tg_part1.txt" -Raw -Encoding UTF8).TrimEnd()
$part2 = (Get-Content "$root\posts\2026-11-04_porfiriy-vychety_tg_part2.txt" -Raw -Encoding UTF8).TrimEnd()

Write-Output "caption: $($part1.Length) симв., text: $($part2.Length) симв."
if ($part1.Length -gt 1024) { throw "Подпись превышает 1024 символа: $($part1.Length)" }
if ($part2.Length -gt 4096) { throw "Текст превышает 4096 символа: $($part2.Length)" }

function Invoke-TelegramMultipart([string]$method, [hashtable]$fields) {
    $client = New-Object System.Net.Http.HttpClient
    $client.Timeout = [TimeSpan]::FromSeconds(60)
    try {
        $mp = New-Object System.Net.Http.MultipartFormDataContent
        foreach ($k in $fields.Keys) {
            $mp.Add((New-Object System.Net.Http.StringContent([string]$fields[$k], [System.Text.Encoding]::UTF8, "text/plain")), $k)
        }
        $resp = $client.PostAsync("https://api.telegram.org/bot$token/$method", $mp).Result
        return $resp.Content.ReadAsStringAsync().Result
    } finally {
        $client.Dispose()
    }
}

# --- msg 19: новая подпись к фото ---
$j1 = Invoke-TelegramMultipart "editMessageCaption" @{
    chat_id    = "@fintaxa_explains"
    message_id = 19
    caption    = $part1
}
Write-Output "editMessageCaption: $j1"
if ($j1 -notmatch '"ok":true') { throw "editMessageCaption не сработал" }

# --- msg 20: новый текст ---
$j2 = Invoke-TelegramMultipart "editMessageText" @{
    chat_id    = "@fintaxa_explains"
    message_id = 20
    text       = $part2
}
Write-Output "editMessageText: $j2"
if ($j2 -notmatch '"ok":true') { throw "editMessageText не сработал" }