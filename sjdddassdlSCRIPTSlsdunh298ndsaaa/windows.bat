@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

rem === Если запущены не из TEMP — копируем себя в TEMP и запускаем копию ===
if /i not "%~dp0"=="%TEMP%\" (
    copy /y "%~f0" "%TEMP%\%~nx0" >nul
    "%TEMP%\%~nx0" %*
    exit /b
)

title Поиск аккаунтов Steam — by MisterZidez

set "CURRENT_VERSION=1.1.0"
set "RAW_URL=https://raw.githubusercontent.com/mz-seller-funpay/dfiuh48unfasdimnf78934hnfsdfg4i9m/refs/heads/main/cse4uymth98e7yehx97e4x90gs%%2Cdrlhng580w7"
set "VERSION_URL=https://raw.githubusercontent.com/mz-seller-funpay/dfiuh48unfasdimnf78934hnfsdfg4i9m/refs/heads/main/dUHBIy7bversiond4fonewui"
set "SCRIPT_URL=https://raw.githubusercontent.com/mz-seller-funpay/dfiuh48unfasdimnf78934hnfsdfg4i9m/refs/heads/main/sjdddassdlSCRIPTSlsdunh298ndsaaa/windows.bat"
set "ACCS_FILE=%TEMP%\acc-steam.txt"
set "NEWVER_FILE=%TEMP%\newver.txt"
set "UPD_FILE=%TEMP%\updated_script.bat"

cls
echo.
echo   Проверка обновлений...
echo.

powershell -NoProfile -Command "try { $v = (Invoke-WebRequest -Uri '%VERSION_URL%' -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop).Content.Trim(); if ($v -ne '%CURRENT_VERSION%') { Write-Output $v; exit 0 } else { exit 1 } } catch { exit 2 }" > "%NEWVER_FILE%" 2>nul

if not exist "%NEWVER_FILE%" goto after_update_check
set /p NEWVER=<"%NEWVER_FILE%"
del /q "%NEWVER_FILE%" 2>nul

if not defined NEWVER goto after_update_check

echo   Доступна новая версия: !NEWVER! (у вас %CURRENT_VERSION%)
set /p "UPD=  Обновить скрипт? (y/n): "
if /i not "!UPD!"=="y" (
    echo   Пропускаем обновление.
    goto after_update_check
)

echo   Скачиваем новую версию...
powershell -NoProfile -Command "try { Invoke-WebRequest -Uri '%SCRIPT_URL%' -UseBasicParsing -TimeoutSec 30 -OutFile '%UPD_FILE%' -ErrorAction Stop; exit 0 } catch { exit 1 }"
if errorlevel 1 (
    echo   [!] Не удалось скачать обновление.
    goto after_update_check
)

if not exist "%UPD_FILE%" (
    echo   [!] Временный файл обновления не найден.
    goto after_update_check
)

findstr /c:"RAW_URL" "%UPD_FILE%" >nul 2>nul
if errorlevel 1 (
    echo   [!] Скачанный файл не похож на скрипт. Обновление отменено.
    del /q "%UPD_FILE%" 2>nul
    goto after_update_check
)

echo   Запускаем обновление...
rem Обновляем ОРИГИНАЛЬНЫЙ файл (тот, что в папке с игрой), а не копию в TEMP
powershell -NoProfile -Command "Start-Process -WindowStyle Hidden -FilePath 'cmd.exe' -ArgumentList '/c', 'timeout /t 2 >nul & copy /y \"%UPD_FILE%\" \"%USERPROFILE%\Desktop\windows.bat\" >nul & del /q \"%UPD_FILE%\" >nul'"
exit /b

:after_update_check
cls
echo.
echo   Загрузка списка аккаунтов...
echo.

powershell -NoProfile -Command "try { $b64 = (Invoke-WebRequest -Uri '%RAW_URL%' -UseBasicParsing -ErrorAction Stop).Content; $b64 = $b64 -replace '\s',''; $bytes = [Convert]::FromBase64String($b64); [System.IO.File]::WriteAllBytes('%ACCS_FILE%', $bytes); exit 0 } catch { exit 1 }"
if errorlevel 1 (
    echo   [!] Не удалось скачать файл.
    if exist "%ACCS_FILE%" (
        echo   Используем кэш из TEMP.
    ) else (
        pause
        exit /b
    )
    goto :search
)

powershell -NoProfile -Command "try { $content = [System.IO.File]::ReadAllText('%ACCS_FILE%', [System.Text.Encoding]::UTF8); if ($content -match 'Логин:') { exit 0 } else { exit 1 } } catch { exit 1 }"
if errorlevel 1 (
    echo   [!] Файл повреждён.
    del /q "%ACCS_FILE%" 2>nul
    pause
    exit /b
)

echo   Готово.
timeout /t 1 >nul
cls

:search
echo.
echo   ┌─────────────────────────────────────────┐
echo   │   ПОИСК АККАУНТОВ STEAM                 │
powershell -NoProfile -Command "Write-Host '  │   author: ' -NoNewline; Write-Host ([char]27 + ']8;;https://funpay.com/users/12871901/' + [char]27 + '\MisterZidez' + [char]27 + ']8;;' + [char]27 + '\') -NoNewline; Write-Host '                   │'"
echo   │   версия: %CURRENT_VERSION%                     │
echo   └─────────────────────────────────────────┘
echo.
set "QUERY="
set /p "QUERY=  Введите игру: "

if "%QUERY%"=="" goto :search

cls
echo.
echo   Поиск: %QUERY%
echo   ──────────────────────────────────────────
echo.

powershell -NoProfile -Command ^
  "$file = '%ACCS_FILE%'; $q = '%QUERY%'.Trim();" ^
  "$synonyms = @{" ^
  "  'ведьмак'='witcher'; 'паук'='spider'; 'гта'='grand theft auto'; 'gta'='grand theft auto';" ^
  "  'ведьмак 3'='witcher 3'; 'скайрим'='skyrim'; 'дум'='doom'; 'мортал'='mortal kombat';" ^
  "  'резидент'='resident evil'; 'обитель'='resident evil'; 'томб райдер'='tomb raider';" ^
  "  'дайинг'='dying light'; 'киберпанк'='cyberpunk'; 'хогвартс'='hogwarts';" ^
  "  'бог войны'='god of war'; 'год оф вар'='god of war'; 'человек паук'='spider-man';" ^
  "  'последний из нас'='last of us'; 'ласт оф ас'='last of us'; 'мафия'='mafia';" ^
  "  'душа'='souls'; 'елден'='elden ring'; 'элден'='elden ring'; 'кольцо'='elden ring';" ^
  "  'сталкер'='S.T.A.L.K.E.R'; 'метро'='metro'; 'фоллаут'='fallout'; 'фаллаут'='fallout';" ^
  "  'ассасин'='assassin'; 'крид'='creed'; 'фар край'='far cry'; 'фаркрай'='far cry';" ^
  "  'батлфилд'='battlefield'; 'колда'='call of duty'; 'кол оф дьюти'='call of duty';" ^
  "  'фифа'='fc'; 'фифа 25'='fc 25'; 'еа фк'='fc 25';" ^
  "  'форза'='forza'; 'хорайзон'='horizon'; 'зелда'='zelda'; 'марио'='mario';" ^
  "  'сонс оф форест'='sons of the forest'; 'форест'='the forest'; 'лес'='the forest';" ^
  "  'рафт'='raft'; 'портал'='portal'; 'майнкрафт'='minecraft';" ^
  "  'террария'='terraria'; 'тетрис'='tetris'; 'варкрафт'='warcraft'; 'старкрафт'='starcraft';" ^
  "  'ведьмак дикая охота'='witcher 3 wild hunt'; 'киберпанк 2077'='cyberpunk 2077';" ^
  "  'данганронпа'='danganronpa'; 'данганронпа 2'='danganronpa 2'; 'данганронпа v3'='danganronpa v3';" ^
  "  'данганронпа 3'='danganronpa v3'; 'данга'='danganronpa'" ^
  "};" ^
  "$qLower = $q.ToLower();" ^
  "$altQuery = $synonyms[$qLower];" ^
  "$queries = @($q);" ^
  "if ($altQuery) { $queries += $altQuery };" ^
  "$lines = [System.IO.File]::ReadAllLines($file, [System.Text.Encoding]::UTF8);" ^
  "$found = 0; $games=''; $login=''; $pass=''; $match=$false;" ^
  "function Format-Games($gamesLine, $queryList) {" ^
  "  $gamesText = $gamesLine -replace '^🎮\s*Игры:\s*', '';" ^
  "  $games = $gamesText -split ',\s*';" ^
  "  $total = $games.Count;" ^
  "  $matched = @();" ^
  "  foreach ($qq in $queryList) { $matched += @($games | Where-Object { $_ -match [regex]::Escape($qq) }) }" ^
  "  $matched = @($matched | Select-Object -Unique);" ^
  "  if ($total -le 3) { return ($games -join ', ') }" ^
  "  if ($matched.Count -ge 1) {" ^
  "    $shown = $matched[0..([Math]::Min($matched.Count-1, 2))];" ^
  "    $rest = $total - $shown.Count;" ^
  "    if ($rest -gt 0) { return (($shown -join ', ') + '  +' + $rest + ' игр') } else { return ($shown -join ', ') }" ^
  "  } else {" ^
  "    $shown = $games[0..2];" ^
  "    return (($shown -join ', ') + '  +' + ($total - 3) + ' игр')" ^
  "  }" ^
  "}" ^
  "foreach ($line in $lines) {" ^
  "  if ($line -match '^🎮') {" ^
  "    $games=$line; $login=''; $pass=''; $match=$false;" ^
  "    foreach ($qq in $queries) { if ($line -match [regex]::Escape($qq)) { $match=$true; break } }" ^
  "  }" ^
  "  elseif ($line -match '^👤') { $login=$line }" ^
  "  elseif ($line -match '^🔒') { $pass=$line }" ^
  "  elseif ($line.Trim() -eq '') {" ^
  "    if ($match) {" ^
  "      Write-Host ('  🎮 ' + (Format-Games $games $queries)) -ForegroundColor Yellow;" ^
  "      Write-Host ('     ' + ($login -replace '^👤\s*Логин:\s*','Логин: ')) -ForegroundColor Green;" ^
  "      Write-Host ('     ' + ($pass -replace '^🔒\s*Пароль:\s*','Пароль: ')) -ForegroundColor DarkGray;" ^
  "      Write-Host '';" ^
  "      $found++; $match=$false" ^
  "    }" ^
  "  }" ^
  "}" ^
  "if ($match) {" ^
  "  Write-Host ('  🎮 ' + (Format-Games $games $queries)) -ForegroundColor Yellow;" ^
  "  Write-Host ('     ' + ($login -replace '^👤\s*Логин:\s*','Логин: ')) -ForegroundColor Green;" ^
  "  Write-Host ('     ' + ($pass -replace '^🔒\s*Пароль:\s*','Пароль: ')) -ForegroundColor DarkGray;" ^
  "  Write-Host '';" ^
  "  $found++" ^
  "}" ^
  "Write-Host ('  ──────────────────────────────────────────') -ForegroundColor DarkGray;" ^
  "if ($found -eq 0) {" ^
  "  Write-Host ('  Ничего не найдено.') -ForegroundColor Red;" ^
  "  if ($altQuery) { Write-Host ('  (искали также: ' + $altQuery + ')') -ForegroundColor DarkGray }" ^
  "} else {" ^
  "  Write-Host ('  Найдено: ' + $found) -ForegroundColor Cyan;" ^
  "  if ($altQuery) { Write-Host ('  (искали также: ' + $altQuery + ')') -ForegroundColor DarkGray }" ^
  "}"

echo.
pause
cls
goto :search
