# Деплой статических файлов сайта fintaxa.ru на хостинг Reg.ru через FTPS.
# Выгружает только то, что нужно на хостинге: index.html + assets (css/js/img/favicon).
# config/hosting.secure.json — хост, логин, пароль (секрет, в .gitignore).
# Запуск:  powershell -File scripts\deploy_site.ps1
#          powershell -File scripts\deploy_site.ps1 -Build   # сначала пересобрать (python site/build.py)

param([switch]$Build)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$cfg  = Get-Content "$root\config\hosting.secure.json" -Raw | ConvertFrom-Json

if ($cfg.password -match 'ВСТАВЬТЕ_ПАРОЛЬ|^$') {
    throw "Файл config\hosting.secure.json пуст. Вставьте пароль FTP в поле password."
}

if ($Build) { python "$root\site\build.py" }

$site = "$root\site"
curl.exe --version | Out-Null

# --- файлы для выгрузки ---
$files  = @("$site\index.html", "$site\assets\style.css", "$site\assets\script.js")
$files += Get-ChildItem "$site\assets\img\*.webp", "$site\assets\img\*.png" | ForEach-Object { $_.FullName }

Write-Output "Хост: $($cfg.host), корень: $($cfg.remote_root), файлов: $($files.Count)"
$okCount = 0
foreach ($f in $files) {
    $rel = $f.Substring($site.Length + 1).Replace('\', '/')
    $remote = "ftp://$($cfg.host)$($cfg.remote_root)/$rel"
    & curl.exe -sS --ftp-create-dirs --ssl-reqd --fail --max-time 120 `
        -u "$($cfg.login):$($cfg.password)" -T $f $remote
    if ($LASTEXITCODE -eq 0) { $okCount++; Write-Output "  OK  $rel" }
    else { throw "Ошибка выгрузки $rel (curl exit $LASTEXITCODE)" }
}

# --- сверка размеров после выгрузки ---
Write-Output "Сверка размеров с сервером:"
$remoteRoot = "ftp://$($cfg.host)$($cfg.remote_root)/"
$listing = & curl.exe -sS --ssl-reqd -u "$($cfg.login):$($cfg.password)" $remoteRoot 2>$null
$bad = 0
foreach ($line in $listing) {
    # формат листинга: "права N группа размер дата файла"
    $size = ($line -split '\s+')[4]
    $name = ($line -split '\s+')[-1]
    if ($name -in @('.', '..') -or -not $size) { continue }
    $local = ($files | Where-Object { (Split-Path $_ -Leaf) -eq $name } | Select-Object -First 1)
    if ($local) {
        $ok = [int]$size -eq (Get-Item $local).Length
        if (-not $ok) { $bad++ }
        Write-Output ("  {0}: сервер {1} / локально {2} {3}" -f $name, $size, (Get-Item $local).Length, $(if ($ok) { '' } else { '< РАЗЛИЧИЕ!' }))
    }
}
if ($bad -gt 0) { Write-Warning "$bad файл(ов) различаются — перепроверьте" }

Write-Output "Деплой завершён: $okCount из $($files.Count) файлов выгружены."