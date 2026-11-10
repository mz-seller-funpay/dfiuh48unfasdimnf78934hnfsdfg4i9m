@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
title Поиск аккаунтов Steam — by MisterZidez

set "CURRENT_VERSION=1.2.0"
set "RAW_URL=https://raw.githubusercontent.com/mz-seller-funpay/dfiuh48unfasdimnf78934hnfsdfg4i9m/refs/heads/main/cse4uymth98e7yehx97e4x90gs%%2Cdrlhng580w7"
set "VERSION_URL=https://raw.githubusercontent.com/mz-seller-funpay/dfiuh48unfasdimnf78934hnfsdfg4i9m/refs/heads/main/dUHBIy7bversiond4fonewui"
set "SCRIPT_URL=https://raw.githubusercontent.com/mz-seller-funpay/dfiuh48unfasdimnf78934hnfsdfg4i9m/refs/heads/main/sjdddassdlSCRIPTSlsdunh298ndsaaa/windows.bat"
set "ACCS_FILE=%TEMP%\acc-steam.txt"
set "B64_FILE=%TEMP%\acc-steam.b64"
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
powershell -NoProfile -Command "Start-Process -WindowStyle Hidden -FilePath 'cmd.exe' -ArgumentList '/c', 'timeout /t 2 >nul & copy /y \"%UPD_FILE%\" \"%~f0\" >nul & del /q \"%UPD_FILE%\" >nul & start \"\" \"%~f0\"'"
exit /b

:after_update_check
cls
echo.
echo   Загрузка списка аккаунтов...
echo.

powershell -NoProfile -Command "try { Invoke-WebRequest -Uri '%RAW_URL%' -UseBasicParsing -TimeoutSec 30 -OutFile '%B64_FILE%' -ErrorAction Stop; exit 0 } catch { exit 1 }"
if errorlevel 1 (
    echo   [!] Не удалось скачать файл.
    if exist "%ACCS_FILE%" (
        echo   Используем кэш из TEMP.
    ) else (
        pause
        exit /b
    )
    goto search
)

certutil -decode "%B64_FILE%" "%ACCS_FILE%" >nul 2>nul
del /q "%B64_FILE%" 2>nul

if not exist "%ACCS_FILE%" (
    echo   [!] Не удалось декодировать файл.
    pause
    exit /b
)

findstr /c:"Логин:" "%ACCS_FILE%" >nul 2>nul
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
echo   │   автор: MisterZidez                    │
echo   │   версия: %CURRENT_VERSION%                   │
echo   └─────────────────────────────────────────┘
echo.
set "QUERY="
set /p "QUERY=  Введите игру: "

if "%QUERY%"=="" goto search

cls
echo.
echo   Поиск: %QUERY%
echo   ──────────────────────────────────────────
echo.

rem === Определяем синоним ===
set "ALT="
call :get_synonym "%QUERY%"

rem === Собираем список запросов для поиска ===
set "Q1=%QUERY%"
set "Q2=%ALT%"
set "Q3="
set "Q4="

rem Обрезаем запрос до 5 символов для нечёткого поиска
set "QTRIM=!QUERY:~0,5!"
if not "!QTRIM!"=="%QUERY%" set "Q3=!QTRIM!"

rem Если запрос из нескольких слов — берём первое слово
for /f "tokens=1 delims= " %%W in ("%QUERY%") do (
    if not "%%W"=="%QUERY%" set "Q4=%%W"
)

set "FOUND=0"
set "MATCH=0"
set "GAMES="
set "LOGIN="
set "PASS="

for /f "usebackq delims=" %%L in ("%ACCS_FILE%") do (
    set "LINE=%%L"

    echo !LINE! | findstr /c:"Игры:" >nul
    if !errorlevel!==0 (
        set "GAMES=!LINE!"
        set "LOGIN="
        set "PASS="
        set "MATCH=0"

        echo !LINE! | findstr /i /c:"!Q1!" >nul
        if !errorlevel!==0 set "MATCH=1"
        if "!MATCH!"=="0" if defined Q2 (
            echo !LINE! | findstr /i /c:"!Q2!" >nul
            if !errorlevel!==0 set "MATCH=1"
        )
        if "!MATCH!"=="0" if defined Q3 (
            echo !LINE! | findstr /i /c:"!Q3!" >nul
            if !errorlevel!==0 set "MATCH=1"
        )
        if "!MATCH!"=="0" if defined Q4 (
            echo !LINE! | findstr /i /c:"!Q4!" >nul
            if !errorlevel!==0 set "MATCH=1"
        )
    ) else (
        echo !LINE! | findstr /c:"Логин:" >nul
        if !errorlevel!==0 (
            set "LOGIN=!LINE!"
        ) else (
            echo !LINE! | findstr /c:"Пароль:" >nul
            if !errorlevel!==0 (
                set "PASS=!LINE!"
            ) else (
                if "!LINE!"=="" (
                    if !MATCH!==1 (
                        echo   !GAMES!
                        echo      !LOGIN!
                        echo      !PASS!
                        echo.
                        set /a FOUND+=1
                        set "MATCH=0"
                    )
                )
            )
        )
    )
)

if !MATCH!==1 (
    echo   !GAMES!
    echo      !LOGIN!
    echo      !PASS!
    echo.
    set /a FOUND+=1
)

echo   ──────────────────────────────────────────
if !FOUND!==0 (
    echo   Ничего не найдено.
) else (
    echo   Найдено: !FOUND!
)
if defined ALT (
    echo   (искали также: !ALT!)
)

echo.
pause
cls
goto search

rem === Функция словаря синонимов ===
:get_synonym
set "KEY=%~1"
set "KEY=%KEY: = %"
set "ALT="

for %%K in ("!KEY!") do (
    set "K=%%~K"
    if /i "!K!"=="ведьмак" set "ALT=witcher"
    if /i "!K!"=="паук" set "ALT=spider"
    if /i "!K!"=="гта" set "ALT=grand theft auto"
    if /i "!K!"=="gta" set "ALT=grand theft auto"
    if /i "!K!"=="ведьмак 3" set "ALT=witcher 3"
    if /i "!K!"=="скайрим" set "ALT=skyrim"
    if /i "!K!"=="дум" set "ALT=doom"
    if /i "!K!"=="мортал" set "ALT=mortal kombat"
    if /i "!K!"=="резидент" set "ALT=resident evil"
    if /i "!K!"=="обитель" set "ALT=resident evil"
    if /i "!K!"=="томб райдер" set "ALT=tomb raider"
    if /i "!K!"=="дайинг" set "ALT=dying light"
    if /i "!K!"=="киберпанк" set "ALT=cyberpunk"
    if /i "!K!"=="хогвартс" set "ALT=hogwarts"
    if /i "!K!"=="бог войны" set "ALT=god of war"
    if /i "!K!"=="год оф вар" set "ALT=god of war"
    if /i "!K!"=="человек паук" set "ALT=spider-man"
    if /i "!K!"=="последний из нас" set "ALT=last of us"
    if /i "!K!"=="ласт оф ас" set "ALT=last of us"
    if /i "!K!"=="мафия" set "ALT=mafia"
    if /i "!K!"=="душа" set "ALT=souls"
    if /i "!K!"=="елден" set "ALT=elden ring"
    if /i "!K!"=="элден" set "ALT=elden ring"
    if /i "!K!"=="кольцо" set "ALT=elden ring"
    if /i "!K!"=="сталкер" set "ALT=S.T.A.L.K.E.R"
    if /i "!K!"=="метро" set "ALT=metro"
    if /i "!K!"=="фоллаут" set "ALT=fallout"
    if /i "!K!"=="фаллаут" set "ALT=fallout"
    if /i "!K!"=="ассасин" set "ALT=assassin"
    if /i "!K!"=="крид" set "ALT=creed"
    if /i "!K!"=="фар край" set "ALT=far cry"
    if /i "!K!"=="фаркрай" set "ALT=far cry"
    if /i "!K!"=="батлфилд" set "ALT=battlefield"
    if /i "!K!"=="колда" set "ALT=call of duty"
    if /i "!K!"=="кол оф дьюти" set "ALT=call of duty"
    if /i "!K!"=="фифа" set "ALT=fc"
    if /i "!K!"=="фифа 25" set "ALT=fc 25"
    if /i "!K!"=="еа фк" set "ALT=fc 25"
    if /i "!K!"=="форза" set "ALT=forza"
    if /i "!K!"=="хорайзон" set "ALT=horizon"
    if /i "!K!"=="зелда" set "ALT=zelda"
    if /i "!K!"=="марио" set "ALT=mario"
    if /i "!K!"=="сонс оф форест" set "ALT=sons of the forest"
    if /i "!K!"=="форест" set "ALT=the forest"
    if /i "!K!"=="лес" set "ALT=the forest"
    if /i "!K!"=="рафт" set "ALT=raft"
    if /i "!K!"=="портал" set "ALT=portal"
    if /i "!K!"=="майнкрафт" set "ALT=minecraft"
    if /i "!K!"=="террария" set "ALT=terraria"
    if /i "!K!"=="тетрис" set "ALT=tetris"
    if /i "!K!"=="варкрафт" set "ALT=warcraft"
    if /i "!K!"=="старкрафт" set "ALT=starcraft"
    if /i "!K!"=="ведьмак дикая охота" set "ALT=witcher 3 wild hunt"
    if /i "!K!"=="киберпанк 2077" set "ALT=cyberpunk 2077"
    if /i "!K!"=="данганронпа" set "ALT=danganronpa"
    if /i "!K!"=="данганронпа 2" set "ALT=danganronpa 2"
    if /i "!K!"=="данганронпа v3" set "ALT=danganronpa v3"
    if /i "!K!"=="данганронпа 3" set "ALT=danganronpa v3"
    if /i "!K!"=="данга" set "ALT=danganronpa"
    if /i "!K!"=="дарк соулс" set "ALT=dark souls"
    if /i "!K!"=="дарк соулз" set "ALT=dark souls"
    if /i "!K!"=="дарк соулс 3" set "ALT=dark souls 3"
    if /i "!K!"=="дарк соулс 2" set "ALT=dark souls 2"
    if /i "!K!"=="дс" set "ALT=dark souls"
    if /i "!K!"=="дс3" set "ALT=dark souls 3"
    if /i "!K!"=="секиро" set "ALT=sekiro"
    if /i "!K!"=="бладборн" set "ALT=bloodborne"
    if /i "!K!"=="армор кор" set "ALT=armored core"
    if /i "!K!"=="армор кор 6" set "ALT=armored core 6"
    if /i "!K!"=="нио" set "ALT=nioh"
    if /i "!K!"=="нио 2" set "ALT=nioh 2"
    if /i "!K!"=="лайс оф пи" set "ALT=lies of p"
    if /i "!K!"=="лордс оф зе фоллен" set "ALT=lords of the fallen"
    if /i "!K!"=="гта 5" set "ALT=gta 5"
    if /i "!K!"=="гта5" set "ALT=gta 5"
    if /i "!K!"=="гта 6" set "ALT=gta 6"
    if /i "!K!"=="гта 4" set "ALT=gta 4"
    if /i "!K!"=="гта сан" set "ALT=gta san andreas"
    if /i "!K!"=="сан андреас" set "ALT=gta san andreas"
    if /i "!K!"=="рдр" set "ALT=red dead redemption"
    if /i "!K!"=="рдр 2" set "ALT=red dead redemption 2"
    if /i "!K!"=="ред дед" set "ALT=red dead redemption"
    if /i "!K!"=="ред дед 2" set "ALT=red dead redemption 2"
    if /i "!K!"=="мафия 2" set "ALT=mafia 2"
    if /i "!K!"=="мафия 3" set "ALT=mafia 3"
    if /i "!K!"=="мафия 1" set "ALT=mafia definitive edition"
    if /i "!K!"=="буллы" set "ALT=bully"
    if /i "!K!"=="ла нойр" set "ALT=l.a. noire"
    if /i "!K!"=="обливион" set "ALT=oblivion"
    if /i "!K!"=="морровинд" set "ALT=morrowind"
    if /i "!K!"=="фоллаут 4" set "ALT=fallout 4"
    if /i "!K!"=="фоллаут 3" set "ALT=fallout 3"
    if /i "!K!"=="фоллаут 76" set "ALT=fallout 76"
    if /i "!K!"=="фоллаут нью вегас" set "ALT=fallout new vegas"
    if /i "!K!"=="нью вегас" set "ALT=fallout new vegas"
    if /i "!K!"=="старфилд" set "ALT=starfield"
    if /i "!K!"=="дум 2016" set "ALT=doom 2016"
    if /i "!K!"=="дум этернал" set "ALT=doom eternal"
    if /i "!K!"=="дум 3" set "ALT=doom 3"
    if /i "!K!"=="квикс" set "ALT=quake"
    if /i "!K!"=="вольфенштейн" set "ALT=wolfenstein"
    if /i "!K!"=="ассасин крид" set "ALT=assassins creed"
    if /i "!K!"=="ассасин 2" set "ALT=assassins creed 2"
    if /i "!K!"=="ассасин 4" set "ALT=assassins creed 4"
    if /i "!K!"=="ассасин блэк флаг" set "ALT=assassins creed black flag"
    if /i "!K!"=="ассасин вальгалла" set "ALT=assassins creed valhalla"
    if /i "!K!"=="вальгалла" set "ALT=assassins creed valhalla"
    if /i "!K!"=="ассасин ориджинс" set "ALT=assassins creed origins"
    if /i "!K!"=="ориджинс" set "ALT=assassins creed origins"
    if /i "!K!"=="ассасин одессей" set "ALT=assassins creed odyssey"
    if /i "!K!"=="одессей" set "ALT=assassins creed odyssey"
    if /i "!K!"=="ассасин мираж" set "ALT=assassins creed mirage"
    if /i "!K!"=="миража" set "ALT=assassins creed mirage"
    if /i "!K!"=="фар край 3" set "ALT=far cry 3"
    if /i "!K!"=="фар край 4" set "ALT=far cry 4"
    if /i "!K!"=="фар край 5" set "ALT=far cry 5"
    if /i "!K!"=="фар край 6" set "ALT=far cry 6"
    if /i "!K!"=="примал" set "ALT=far cry primal"
    if /i "!K!"=="фар край нью давн" set "ALT=far cry new dawn"
    if /i "!K!"=="дивижн" set "ALT=the division"
    if /i "!K!"=="дивижн 2" set "ALT=the division 2"
    if /i "!K!"=="рэйнбоу сикс" set "ALT=rainbow six"
    if /i "!K!"=="р6" set "ALT=rainbow six siege"
    if /i "!K!"=="рэйнбоу сикс сидж" set "ALT=rainbow six siege"
    if /i "!K!"=="принс оф персия" set "ALT=prince of persia"
    if /i "!K!"=="принц персии" set "ALT=prince of persia"
    if /i "!K!"=="сплинтер селл" set "ALT=splinter cell"
    if /i "!K!"=="сплинтер" set "ALT=splinter cell"
    if /i "!K!"=="варч" set "ALT=watch dogs"
    if /i "!K!"=="вотч догс" set "ALT=watch dogs"
    if /i "!K!"=="вотч догс 2" set "ALT=watch dogs 2"
    if /i "!K!"=="вотч догс лиджн" set "ALT=watch dogs legion"
    if /i "!K!"=="легион" set "ALT=watch dogs legion"
    if /i "!K!"=="фор хонор" set "ALT=for honor"
    if /i "!K!"=="гоуст рикон" set "ALT=ghost recon"
    if /i "!K!"=="гоуст рекон" set "ALT=ghost recon"
    if /i "!K!"=="тхе крю" set "ALT=the crew"
    if /i "!K!"=="трекмания" set "ALT=trackmania"
    if /i "!K!"=="райман" set "ALT=rayman"
    if /i "!K!"=="колда мв2" set "ALT=call of duty mw2"
    if /i "!K!"=="мв2" set "ALT=call of duty mw2"
    if /i "!K!"=="мв3" set "ALT=call of duty mw3"
    if /i "!K!"=="варзона" set "ALT=call of duty warzone"
    if /i "!K!"=="варзоне" set "ALT=call of duty warzone"
    if /i "!K!"=="код" set "ALT=call of duty"
    if /i "!K!"=="батла" set "ALT=battlefield"
    if /i "!K!"=="батлфилд 1" set "ALT=battlefield 1"
    if /i "!K!"=="батлфилд 4" set "ALT=battlefield 4"
    if /i "!K!"=="батлфилд 2042" set "ALT=battlefield 2042"
    if /i "!K!"=="бф4" set "ALT=battlefield 4"
    if /i "!K!"=="апекс" set "ALT=apex legends"
    if /i "!K!"=="апекс легендс" set "ALT=apex legends"
    if /i "!K!"=="титанфолл" set "ALT=titanfall"
    if /i "!K!"=="титанфолл 2" set "ALT=titanfall 2"
    if /i "!K!"=="дестини" set "ALT=destiny"
    if /i "!K!"=="дестини 2" set "ALT=destiny 2"
    if /i "!K!"=="овервотч" set "ALT=overwatch"
    if /i "!K!"=="овервоч" set "ALT=overwatch"
    if /i "!K!"=="оверватч" set "ALT=overwatch"
    if /i "!K!"=="ов" set "ALT=overwatch"
    if /i "!K!"=="ов 2" set "ALT=overwatch 2"
    if /i "!K!"=="овервотч 2" set "ALT=overwatch 2"
    if /i "!K!"=="паладинс" set "ALT=paladins"
    if /i "!K!"=="валорант" set "ALT=valorant"
    if /i "!K!"=="кске" set "ALT=cs2"
    if /i "!K!"=="кс 2" set "ALT=cs2"
    if /i "!K!"=="кс го" set "ALT=csgo"
    if /i "!K!"=="ксго" set "ALT=csgo"
    if /i "!K!"=="контра" set "ALT=counter-strike"
    if /i "!K!"=="контер страйк" set "ALT=counter-strike"
    if /i "!K!"=="р6с" set "ALT=rainbow six siege"
    if /i "!K!"=="хитмен" set "ALT=hitman"
    if /i "!K!"=="хитман 3" set "ALT=hitman 3"
    if /i "!K!"=="фифа 24" set "ALT=fc 24"
    if /i "!K!"=="фифа 23" set "ALT=fifa 23"
    if /i "!K!"=="фифа 22" set "ALT=fifa 22"
    if /i "!K!"=="фифа 21" set "ALT=fifa 21"
    if /i "!K!"=="фк 24" set "ALT=fc 24"
    if /i "!K!"=="фк 25" set "ALT=fc 25"
    if /i "!K!"=="еа фк 25" set "ALT=fc 25"
    if /i "!K!"=="нхл" set "ALT=nhl"
    if /i "!K!"=="нба" set "ALT=nba 2k"
    if /i "!K!"=="нба 2к" set "ALT=nba 2k"
    if /i "!K!"=="мадден" set "ALT=madden"
    if /i "!K!"=="уефа" set "ALT=uefa"
    if /i "!K!"=="ф1" set "ALT=f1"
    if /i "!K!"=="ф1 24" set "ALT=f1 24"
    if /i "!K!"=="скайфолл" set "ALT=skyfall"
    if /i "!K!"=="нид фор спид" set "ALT=need for speed"
    if /i "!K!"=="нфс" set "ALT=need for speed"
    if /i "!K!"=="нид фор спид мост вантед" set "ALT=need for speed most wanted"
    if /i "!K!"=="мост вантед" set "ALT=need for speed most wanted"
    if /i "!K!"=="нид фор спид хит" set "ALT=need for speed heat"
    if /i "!K!"=="хит нфс" set "ALT=need for speed heat"
    if /i "!K!"=="анбаунд" set "ALT=need for speed unbound"
    if /i "!K!"=="нфс анбаунд" set "ALT=need for speed unbound"
    if /i "!K!"=="биошок" set "ALT=bioshock"
    if /i "!K!"=="биошок 2" set "ALT=bioshock 2"
    if /i "!K!"=="биошок инфинити" set "ALT=bioshock infinite"
    if /i "!K!"=="бордерлендс" set "ALT=borderlands"
    if /i "!K!"=="бордерлендс 2" set "ALT=borderlands 2"
    if /i "!K!"=="бордерлендс 3" set "ALT=borderlands 3"
    if /i "!K!"=="блур" set "ALT=borderlands"
    if /i "!K!"=="сивилизейшн" set "ALT=civilization"
    if /i "!K!"=="цива" set "ALT=civilization"
    if /i "!K!"=="цивилизация" set "ALT=civilization"
    if /i "!K!"=="цив 6" set "ALT=civilization 6"
    if /i "!K!"=="цива 6" set "ALT=civilization 6"
    if /i "!K!"=="ксеком" set "ALT=xcom"
    if /i "!K!"=="ксеном" set "ALT=xcom"
    if /i "!K!"=="ксеном 2" set "ALT=xcom 2"
    if /i "!K!"=="мафия дефинитив" set "ALT=mafia definitive edition"
    if /i "!K!"=="персона" set "ALT=persona"
    if /i "!K!"=="персона 5" set "ALT=persona 5"
    if /i "!K!"=="персона 4" set "ALT=persona 4"
    if /i "!K!"=="персона 3" set "ALT=persona 3"
    if /i "!K!"=="персона 5 роял" set "ALT=persona 5 royal"
    if /i "!K!"=="п5р" set "ALT=persona 5 royal"
    if /i "!K!"=="п5" set "ALT=persona 5"
    if /i "!K!"=="соул хакерс" set "ALT=soul hackers"
    if /i "!K!"=="шх2" set "ALT=soul hackers 2"
    if /i "!K!"=="метафор" set "ALT=metaphor refantazio"
    if /i "!K!"=="метафора" set "ALT=metaphor refantazio"
    if /i "!K!"=="катсураги" set "ALT=catherine"
    if /i "!K!"=="кетрин" set "ALT=catherine"
    if /i "!K!"=="ярн" set "ALT=yakuza"
    if /i "!K!"=="якудза" set "ALT=yakuza"
    if /i "!K!"=="якудза 0" set "ALT=yakuza 0"
    if /i "!K!"=="якудза лайк э драгон" set "ALT=yakuza like a dragon"
    if /i "!K!"=="лайк э драгон" set "ALT=yakuza like a dragon"
    if /i "!K!"=="джаджмент" set "ALT=judgment"
    if /i "!K!"=="лондон" set "ALT=yakuza"
    if /i "!K!"=="соник" set "ALT=sonic"
    if /i "!K!"=="соник фронтьерс" set "ALT=sonic frontiers"
    if /i "!K!"=="тотал вар" set "ALT=total war"
    if /i "!K!"=="тотал вор" set "ALT=total war"
    if /i "!K!"=="тотал вар вархаммер" set "ALT=total war warhammer"
    if /i "!K!"=="тв вархаммер" set "ALT=total war warhammer"
    if /i "!K!"=="футбал менеджер" set "ALT=football manager"
    if /i "!K!"=="фм" set "ALT=football manager"
    if /i "!K!"=="зельда ботв" set "ALT=zelda breath of the wild"
    if /i "!K!"=="ботв" set "ALT=zelda breath of the wild"
    if /i "!K!"=="тотк" set "ALT=zelda tears of the kingdom"
    if /i "!K!"=="тиарс оф зе киндом" set "ALT=zelda tears of the kingdom"
    if /i "!K!"=="марио карт" set "ALT=mario kart"
    if /i "!K!"=="марио карт 8" set "ALT=mario kart 8"
    if /i "!K!"=="марио оддиси" set "ALT=mario odyssey"
    if /i "!K!"=="супер марио" set "ALT=super mario"
    if /i "!K!"=="супер марио брос" set "ALT=super mario bros"
    if /i "!K!"=="смб" set "ALT=super mario bros"
    if /i "!K!"=="покемон" set "ALT=pokemon"
    if /i "!K!"=="покемоны" set "ALT=pokemon"
    if /i "!K!"=="покемон го" set "ALT=pokemon go"
    if /i "!K!"=="свитч" set "ALT=switch"
    if /i "!K!"=="ниндтендо" set "ALT=nintendo"
    if /i "!K!"=="нинтендо" set "ALT=nintendo"
    if /i "!K!"=="свич" set "ALT=switch"
    if /i "!K!"=="сплэтун" set "ALT=splatoon"
    if /i "!K!"=="сплатун" set "ALT=splatoon"
    if /i "!K!"=="метроид" set "ALT=metroid"
    if /i "!K!"=="метроид дред" set "ALT=metroid dread"
    if /i "!K!"=="кирби" set "ALT=kirby"
    if /i "!K!"=="донки конг" set "ALT=donkey kong"
    if /i "!K!"=="энимал кроссинг" set "ALT=animal crossing"
    if /i "!K!"=="анимал кроссинг" set "ALT=animal crossing"
    if /i "!K!"=="энимал кросинг" set "ALT=animal crossing"
    if /i "!K!"=="анчартед" set "ALT=uncharted"
    if /i "!K!"=="анчартед 4" set "ALT=uncharted 4"
    if /i "!K!"=="анчартед 2" set "ALT=uncharted 2"
    if /i "!K!"=="анч" set "ALT=uncharted"
    if /i "!K!"=="бог войны 2018" set "ALT=god of war 2018"
    if /i "!K!"=="год оф вар рагнарок" set "ALT=god of war ragnarok"
    if /i "!K!"=="рагнарек" set "ALT=god of war ragnarok"
    if /i "!K!"=="рагнарок" set "ALT=god of war ragnarok"
    if /i "!K!"=="год оф вар 3" set "ALT=god of war 3"
    if /i "!K!"=="год 3" set "ALT=god of war 3"
    if /i "!K!"=="хорайзон зеро давн" set "ALT=horizon zero dawn"
    if /i "!K!"=="хорайзон 2" set "ALT=horizon forbidden west"
    if /i "!K!"=="запретный запад" set "ALT=horizon forbidden west"
    if /i "!K!"=="хорайзон форбидден вест" set "ALT=horizon forbidden west"
    if /i "!K!"=="ласт оф ас 2" set "ALT=last of us 2"
    if /i "!K!"=="ласт оф ас парт 2" set "ALT=last of us part 2"
    if /i "!K!"=="лоу 2" set "ALT=last of us 2"
    if /i "!K!"=="ласт оф ас 1" set "ALT=last of us part 1"
    if /i "!K!"=="ласт оф ас ремейк" set "ALT=last of us part 1"
    if /i "!K!"=="гоуст оф цушима" set "ALT=ghost of tsushima"
    if /i "!K!"=="гоуст" set "ALT=ghost of tsushima"
    if /i "!K!"=="цусима" set "ALT=ghost of tsushima"
    if /i "!K!"=="гоуст оф цусима" set "ALT=ghost of tsushima"
    if /i "!K!"=="спайдермен" set "ALT=spider-man"
    if /i "!K!"=="спайдер мен" set "ALT=spider-man"
    if /i "!K!"=="человек паук 2" set "ALT=spider-man 2"
    if /i "!K!"=="спайдермен 2" set "ALT=spider-man 2"
    if /i "!K!"=="человек-паук 2" set "ALT=spider-man 2"
    if /i "!K!"=="майлз моралес" set "ALT=spider-man miles morales"
    if /i "!K!"=="майлз" set "ALT=spider-man miles morales"
    if /i "!K!"=="ратчет и кланк" set "ALT=ratchet and clank"
    if /i "!K!"=="ратчет" set "ALT=ratchet and clank"
    if /i "!K!"=="бладборн 2" set "ALT=bloodborne 2"
    if /i "!K!"=="ретурнал" set "ALT=returnal"
    if /i "!K!"=="демонс соулс" set "ALT=demons souls"
    if /i "!K!"=="демон соулс" set "ALT=demons souls"
    if /i "!K!"=="сайлент хилл" set "ALT=silent hill"
    if /i "!K!"=="сайлент хилл 2" set "ALT=silent hill 2"
    if /i "!K!"=="дес стрендинг" set "ALT=death stranding"
    if /i "!K!"=="дес стрендинг 2" set "ALT=death stranding 2"
    if /i "!K!"=="дс2" set "ALT=death stranding 2"
    if /i "!K!"=="дэйс ган" set "ALT=days gone"
    if /i "!K!"=="дейс ган" set "ALT=days gone"
    if /i "!K!"=="инфэмос" set "ALT=infamous"
    if /i "!K!"=="инфамос" set "ALT=infamous"
    if /i "!K!"=="киллзоун" set "ALT=killzone"
    if /i "!K!"=="гран туризмо" set "ALT=gran turismo"
    if /i "!K!"=="гт" set "ALT=gran turismo"
    if /i "!K!"=="гт7" set "ALT=gran turismo 7"
    if /i "!K!"=="резидент ивел" set "ALT=resident evil"
    if /i "!K!"=="резидент ивел 2" set "ALT=resident evil 2"
    if /i "!K!"=="ре2" set "ALT=resident evil 2"
    if /i "!K!"=="резидент ивел 4" set "ALT=resident evil 4"
    if /i "!K!"=="ре4" set "ALT=resident evil 4"
    if /i "!K!"=="резидент 4" set "ALT=resident evil 4"
    if /i "!K!"=="резидент ивел 7" set "ALT=resident evil 7"
    if /i "!K!"=="ре7" set "ALT=resident evil 7"
    if /i "!K!"=="резидент 7" set "ALT=resident evil 7"
    if /i "!K!"=="резидент ивел вилладж" set "ALT=resident evil village"
    if /i "!K!"=="вилладж" set "ALT=resident evil village"
    if /i "!K!"=="ре вилладж" set "ALT=resident evil village"
    if /i "!K!"=="ре3" set "ALT=resident evil 3"
    if /i "!K!"=="резидент ивел 3" set "ALT=resident evil 3"
    if /i "!K!"=="резидент 3" set "ALT=resident evil 3"
    if /i "!K!"=="девил мэй край" set "ALT=devil may cry"
    if /i "!K!"=="дмс" set "ALT=devil may cry"
    if /i "!K!"=="дмк" set "ALT=devil may cry"
    if /i "!K!"=="девил мей край 5" set "ALT=devil may cry 5"
    if /i "!K!"=="дмк 5" set "ALT=devil may cry 5"
    if /i "!K!"=="дмс 5" set "ALT=devil may cry 5"
    if /i "!K!"=="монстер хантер" set "ALT=monster hunter"
    if /i "!K!"=="мх" set "ALT=monster hunter"
    if /i "!K!"=="монстер хантер ворлд" set "ALT=monster hunter world"
    if /i "!K!"=="мх ворлд" set "ALT=monster hunter world"
    if /i "!K!"=="монстер хантер райз" set "ALT=monster hunter rise"
    if /i "!K!"=="мх райз" set "ALT=monster hunter rise"
    if /i "!K!"=="монстер хантер вайлдс" set "ALT=monster hunter wilds"
    if /i "!K!"=="мх вайлдс" set "ALT=monster hunter wilds"
    if /i "!K!"=="драгонс догма" set "ALT=dragons dogma"
    if /i "!K!"=="драгон догма 2" set "ALT=dragons dogma 2"
    if /i "!K!"=="дд2" set "ALT=dragons dogma 2"
    if /i "!K!"=="онимьюша" set "ALT=onimusha"
    if /i "!K!"=="онемуша" set "ALT=onimusha"
    if /i "!K!"=="асура" set "ALT=asuras wrath"
    if /i "!K!"=="стрит файтер" set "ALT=street fighter"
    if /i "!K!"=="сф" set "ALT=street fighter"
    if /i "!K!"=="стрит файтер 6" set "ALT=street fighter 6"
    if /i "!K!"=="стф 6" set "ALT=street fighter 6"
    if /i "!K!"=="теккен" set "ALT=tekken"
    if /i "!K!"=="теккен 8" set "ALT=tekken 8"
    if /i "!K!"=="т8" set "ALT=tekken 8"
    if /i "!K!"=="соулкалибур" set "ALT=soulcalibur"
    if /i "!K!"=="соул калибур" set "ALT=soulcalibur"
    if /i "!K!"=="мортал комбат" set "ALT=mortal kombat"
    if /i "!K!"=="мк" set "ALT=mortal kombat"
    if /i "!K!"=="мк1" set "ALT=mortal kombat 1"
    if /i "!K!"=="мк 11" set "ALT=mortal kombat 11"
    if /i "!K!"=="мортал 11" set "ALT=mortal kombat 11"
    if /i "!K!"=="мортал комбат 1" set "ALT=mortal kombat 1"
    if /i "!K!"=="инджастис" set "ALT=injustice"
    if /i "!K!"=="инджастис 2" set "ALT=injustice 2"
    if /i "!K!"=="финал фэнтези" set "ALT=final fantasy"
    if /i "!K!"=="фф" set "ALT=final fantasy"
    if /i "!K!"=="финалка" set "ALT=final fantasy"
    if /i "!K!"=="фф7" set "ALT=final fantasy 7"
    if /i "!K!"=="финал фэнтези 7" set "ALT=final fantasy 7"
    if /i "!K!"=="фф7 ремейк" set "ALT=final fantasy 7 remake"
    if /i "!K!"=="фф7 ребёрс" set "ALT=final fantasy 7 rebirth"
    if /i "!K!"=="фф16" set "ALT=final fantasy 16"
    if /i "!K!"=="финал фэнтези 16" set "ALT=final fantasy 16"
    if /i "!K!"=="фф14" set "ALT=final fantasy 14"
    if /i "!K!"=="фф15" set "ALT=final fantasy 15"
    if /i "!K!"=="фф10" set "ALT=final fantasy 10"
    if /i "!K!"=="кингдом хартс" set "ALT=kingdom hearts"
    if /i "!K!"=="кх" set "ALT=kingdom hearts"
    if /i "!K!"=="кингдом хартс 3" set "ALT=kingdom hearts 3"
    if /i "!K!"=="драгон квест" set "ALT=dragon quest"
    if /i "!K!"=="дк" set "ALT=dragon quest"
    if /i "!K!"=="драгон квест 11" set "ALT=dragon quest 11"
    if /i "!K!"=="ниер" set "ALT=nier"
    if /i "!K!"=="ниер автомата" set "ALT=nier automata"
    if /i "!K!"=="нир автомата" set "ALT=nier automata"
    if /i "!K!"=="ниер репликант" set "ALT=nier replicant"
    if /i "!K!"=="нир репликант" set "ALT=nier replicant"
    if /i "!K!"=="драгон квест билдерс" set "ALT=dragon quest builders"
    if /i "!K!"=="октопат" set "ALT=octopath traveler"
    if /i "!K!"=="октопат 2" set "ALT=octopath traveler 2"
    if /i "!K!"=="триангл" set "ALT=triangle strategy"
    if /i "!K!"=="бравелли" set "ALT=bravely default"
    if /i "!K!"=="паразит ив" set "ALT=parasite eve"
    if /i "!K!"=="кронос" set "ALT=chrono trigger"
    if /i "!K!"=="хроно" set "ALT=chrono trigger"
    if /i "!K!"=="дарк соулс ремастер" set "ALT=dark souls remastered"
    if /i "!K!"=="дср" set "ALT=dark souls remastered"
    if /i "!K!"=="элден ринг шэдоу" set "ALT=elden ring shadow of the erdtree"
    if /i "!K!"=="эрдтри" set "ALT=elden ring shadow of the erdtree"
    if /i "!K!"=="арморд кор 6" set "ALT=armored core 6"
    if /i "!K!"=="ас6" set "ALT=armored core 6"
    if /i "!K!"=="аc6" set "ALT=armored core 6"
    if /i "!K!"=="теккен 7" set "ALT=tekken 7"
    if /i "!K!"=="т7" set "ALT=tekken 7"
    if /i "!K!"=="соул калибур 6" set "ALT=soulcalibur 6"
    if /i "!K!"=="ск6" set "ALT=soulcalibur 6"
    if /i "!K!"=="наруто" set "ALT=naruto"
    if /i "!K!"=="наруто шиппуден" set "ALT=naruto shippuden"
    if /i "!K!"=="наруто ултимейт" set "ALT=naruto ultimate ninja storm"
    if /i "!K!"=="ултимейт ниндзя шторм" set "ALT=naruto ultimate ninja storm"
    if /i "!K!"=="ултимейт ниндзя сторм" set "ALT=naruto ultimate ninja storm"
    if /i "!K!"=="джамп форс" set "ALT=jump force"
    if /i "!K!"=="дрэгон бол" set "ALT=dragon ball"
    if /i "!K!"=="дрэгон болл" set "ALT=dragon ball"
    if /i "!K!"=="драгон бол" set "ALT=dragon ball"
    if /i "!K!"=="драгонбол" set "ALT=dragon ball"
    if /i "!K!"=="дбз" set "ALT=dragon ball z"
    if /i "!K!"=="драгон болл з" set "ALT=dragon ball z"
    if /i "!K!"=="какарот" set "ALT=dragon ball z kakarot"
    if /i "!K!"=="драгон болл файтерз" set "ALT=dragon ball fighterz"
    if /i "!K!"=="дбфз" set "ALT=dragon ball fighterz"
    if /i "!K!"=="ван пис" set "ALT=one piece"
    if /i "!K!"=="уан пис" set "ALT=one piece"
    if /i "!K!"=="уанпис" set "ALT=one piece"
    if /i "!K!"=="соник 2" set "ALT=sonic 2"
    if /i "!K!"=="соник адвенчер" set "ALT=sonic adventure"
    if /i "!K!"=="соник мэния" set "ALT=sonic mania"
    if /i "!K!"=="соник суперстарз" set "ALT=sonic superstars"
    if /i "!K!"=="соник и сотс" set "ALT=sonic and the secret rings"
    if /i "!K!"=="якудза 6" set "ALT=yakuza 6"
    if /i "!K!"=="якудза 7" set "ALT=yakuza 7"
    if /i "!K!"=="якудза кивами" set "ALT=yakuza kiwami"
    if /i "!K!"=="якудза кивами 2" set "ALT=yakuza kiwami 2"
    if /i "!K!"=="исчин" set "ALT=yakuza ishin"
    if /i "!K!"=="лост джаджмент" set "ALT=lost judgment"
    if /i "!K!"=="like a dragon gaiden" set "ALT=like a dragon gaiden"
    if /i "!K!"=="лайк э драгон гайден" set "ALT=like a dragon gaiden"
    if /i "!K!"=="лайк э драгон инфинит" set "ALT=like a dragon infinite wealth"
    if /i "!K!"=="сталкрафт 2" set "ALT=starcraft 2"
    if /i "!K!"=="ст2" set "ALT=starcraft 2"
    if /i "!K!"=="старкрафт 2" set "ALT=starcraft 2"
    if /i "!K!"=="варкрафт 3" set "ALT=warcraft 3"
    if /i "!K!"=="вк3" set "ALT=warcraft 3"
    if /i "!K!"=="варкрафт 2" set "ALT=warcraft 2"
    if /i "!K!"=="ворлд оф варкрафт" set "ALT=world of warcraft"
    if /i "!K!"=="вов" set "ALT=world of warcraft"
    if /i "!K!"=="вов классик" set "ALT=wow classic"
    if /i "!K!"=="диабло" set "ALT=diablo"
    if /i "!K!"=="диабло 2" set "ALT=diablo 2"
    if /i "!K!"=="диабло 3" set "ALT=diablo 3"
    if /i "!K!"=="диабло 4" set "ALT=diablo 4"
    if /i "!K!"=="д3" set "ALT=diablo 3"
    if /i "!K!"=="д4" set "ALT=diablo 4"
    if /i "!K!"=="диабло 2 резурректед" set "ALT=diablo 2 resurrected"
    if /i "!K!"=="д2р" set "ALT=diablo 2 resurrected"
    if /i "!K!"=="овервотч классик" set "ALT=overwatch classic"
    if /i "!K!"=="пат оф экзайл" set "ALT=path of exile"
    if /i "!K!"=="поэ" set "ALT=path of exile"
    if /i "!K!"=="поэ 2" set "ALT=path of exile 2"
    if /i "!K!"=="пат оф экзайл 2" set "ALT=path of exile 2"
    if /i "!K!"=="грим давн" set "ALT=grim dawn"
    if /i "!K!"=="титан квест" set "ALT=titan quest"
    if /i "!K!"=="титан квест 2" set "ALT=titan quest 2"
    if /i "!K!"=="торчлайт" set "ALT=torchlight"
    if /i "!K!"=="аге оф эмпайрс" set "ALT=age of empires"
    if /i "!K!"=="аое" set "ALT=age of empires"
    if /i "!K!"=="аге оф эмпайрс 2" set "ALT=age of empires 2"
    if /i "!K!"=="аое 2" set "ALT=age of empires 2"
    if /i "!K!"=="аге оф эмпайрс 4" set "ALT=age of empires 4"
    if /i "!K!"=="аое 4" set "ALT=age of empires 4"
    if /i "!K!"=="комманд энд конкер" set "ALT=command and conquer"
    if /i "!K!"=="кнк" set "ALT=command and conquer"
    if /i "!K!"=="ред алерт" set "ALT=red alert"
    if /i "!K!"=="ред алерт 2" set "ALT=red alert 2"
    if /i "!K!"=="ра2" set "ALT=red alert 2"
    if /i "!K!"=="тиберриум" set "ALT=tiberium"
    if /i "!K!"=="анно" set "ALT=anno"
    if /i "!K!"=="anno 1800" set "ALT=anno 1800"
    if /i "!K!"=="анно 1800" set "ALT=anno 1800"
    if /i "!K!"=="анно 2070" set "ALT=anno 2070"
    if /i "!K!"=="ситис скаяйнс" set "ALT=cities skylines"
    if /i "!K!"=="сити скаяйнс" set "ALT=cities skylines"
    if /i "!K!"=="ситис 2" set "ALT=cities skylines 2"
    if /i "!K!"=="симс" set "ALT=the sims"
    if /i "!K!"=="симс 4" set "ALT=the sims 4"
    if /i "!K!"=="симс 5" set "ALT=the sims 5"
    if /i "!K!"=="симс 3" set "ALT=the sims 3"
    if /i "!K!"=="планет костер" set "ALT=planet coaster"
    if /i "!K!"=="планет коустер" set "ALT=planet coaster"
    if /i "!K!"=="планет зоо" set "ALT=planet zoo"
    if /i "!K!"=="фростпанк" set "ALT=frostpunk"
    if /i "!K!"=="фростпанк 2" set "ALT=frostpunk 2"
    if /i "!K!"=="тропико" set "ALT=tropico"
    if /i "!K!"=="тропико 6" set "ALT=tropico 6"
    if /i "!K!"=="сурвайвинг марс" set "ALT=surviving mars"
    if /i "!K!"=="сурвайвинг" set "ALT=surviving mars"
    if /i "!K!"=="энной" set "ALT=anno"
    if /i "!K!"=="факторио" set "ALT=factorio"
    if /i "!K!"=="факторио 2" set "ALT=factorio 2"
    if /i "!K!"=="сатисфактори" set "ALT=satisfactory"
    if /i "!K!"=="рифтворлд" set "ALT=riftworld"
    if /i "!K!"=="валхейм" set "ALT=valheim"
    if /i "!K!"=="валхейм 2" set "ALT=valheim 2"
    if /i "!K!"=="раст" set "ALT=rust"
    if /i "!K!"=="раст 2" set "ALT=rust 2"
    if /i "!K!"=="арк" set "ALT=ark survival evolved"
    if /i "!K!"=="арк сурвайвал" set "ALT=ark survival evolved"
    if /i "!K!"=="арк 2" set "ALT=ark 2"
    if /i "!K!"=="палворлд" set "ALT=palworld"
    if /i "!K!"=="пал ворлд" set "ALT=palworld"
    if /i "!K!"=="эншраудед" set "ALT=enshrouded"
    if /i "!K!"=="дед бай дейлайт" set "ALT=dead by daylight"
    if /i "!K!"=="дбд" set "ALT=dead by daylight"
    if /i "!K!"=="дед бай" set "ALT=dead by daylight"
    if /i "!K!"=="фрайдей 13" set "ALT=friday the 13th"
    if /i "!K!"=="фрайдэй" set "ALT=friday the 13th"
    if /i "!K!"=="лефт фор дед" set "ALT=left 4 dead"
    if /i "!K!"=="л4д" set "ALT=left 4 dead"
    if /i "!K!"=="лефт фор дед 2" set "ALT=left 4 dead 2"
    if /i "!K!"=="л4д2" set "ALT=left 4 dead 2"
    if /i "!K!"=="бэк 4 блад" set "ALT=back 4 blood"
    if /i "!K!"=="бэк фор блад" set "ALT=back 4 blood"
    if /i "!K!"=="б4б" set "ALT=back 4 blood"
    if /i "!K!"=="верминтайд" set "ALT=vermintide"
    if /i "!K!"=="верминтайд 2" set "ALT=vermintide 2"
    if /i "!K!"=="дарктайд" set "ALT=darktide"
    if /i "!K!"=="дип рок" set "ALT=deep rock galactic"
    if /i "!K!"=="дрг" set "ALT=deep rock galactic"
    if /i "!K!"=="хеллдайверс" set "ALT=helldivers"
    if /i "!K!"=="хеллдайверс 2" set "ALT=helldivers 2"
    if /i "!K!"=="хд2" set "ALT=helldivers 2"
    if /i "!K!"=="хеллдавэрс" set "ALT=helldivers"
    if /i "!K!"=="гта онлайн" set "ALT=gta online"
    if /i "!K!"=="гтао" set "ALT=gta online"
    if /i "!K!"=="рдр онлайн" set "ALT=red dead online"
    if /i "!K!"=="рдо" set "ALT=red dead online"
    if /i "!K!"=="зе форест" set "ALT=the forest"
    if /i "!K!"=="сонс оф зе форест" set "ALT=sons of the forest"
    if /i "!K!"=="соны фореста" set "ALT=sons of the forest"
    if /i "!K!"=="грин хелл" set "ALT=green hell"
    if /i "!K!"=="гринхелл" set "ALT=green hell"
    if /i "!K!"=="сабнавтика" set "ALT=subnautica"
    if /i "!K!"=="сабнотика" set "ALT=subnautica"
    if /i "!K!"=="сабнавтика 2" set "ALT=subnautica 2"
    if /i "!K!"=="сабнавтика бз" set "ALT=subnautica below zero"
    if /i "!K!"=="белоу зиро" set "ALT=subnautica below zero"
    if /i "!K!"=="ноу мэнс скай" set "ALT=no mans sky"
    if /i "!K!"=="номанс скай" set "ALT=no mans sky"
    if /i "!K!"=="номанскай" set "ALT=no mans sky"
    if /i "!K!"=="стардев вэлли" set "ALT=stardew valley"
    if /i "!K!"=="стардью" set "ALT=stardew valley"
    if /i "!K!"=="стардью вэлли" set "ALT=stardew valley"
    if /i "!K!"=="анимал кроссинг нью хорайзонс" set "ALT=animal crossing new horizons"
    if /i "!K!"=="аснх" set "ALT=animal crossing new horizons"
    if /i "!K!"=="гравити фоллс" set "ALT=gravity falls"
    if /i "!K!"=="гравити" set "ALT=gravity falls"
    if /i "!K!"=="хадес" set "ALT=hades"
    if /i "!K!"=="хадес 2" set "ALT=hades 2"
    if /i "!K!"=="дед селс" set "ALT=dead cells"
    if /i "!K!"=="дед селлс" set "ALT=dead cells"
    if /i "!K!"=="скул" set "ALT=skul"
    if /i "!K!"=="скул зе хироу" set "ALT=skul the hero slayer"
    if /i "!K!"=="инскрипшн" set "ALT=inscryption"
    if /i "!K!"=="инскрипшен" set "ALT=inscryption"
    if /i "!K!"=="слэй зе спайр" set "ALT=slay the spire"
    if /i "!K!"=="слэй" set "ALT=slay the spire"
    if /i "!K!"=="балатро" set "ALT=balatro"
    if /i "!K!"=="вампир сурвайворс" set "ALT=vampire survivors"
    if /i "!K!"=="вампир сурвайвор" set "ALT=vampire survivors"
    if /i "!K!"=="бротато" set "ALT=brotato"
    if /i "!K!"=="майнкрафт 2" set "ALT=minecraft 2"
    if /i "!K!"=="майнкрафт данженс" set "ALT=minecraft dungeons"
    if /i "!K!"=="майн данженс" set "ALT=minecraft dungeons"
    if /i "!K!"=="майнкрафт легендс" set "ALT=minecraft legends"
    if /i "!K!"=="майн легендс" set "ALT=minecraft legends"
    if /i "!K!"=="роблокс" set "ALT=roblox"
    if /i "!K!"=="роблокс 2" set "ALT=roblox 2"
    if /i "!K!"=="роблокс студио" set "ALT=roblox studio"
    if /i "!K!"=="фортнайт" set "ALT=fortnite"
    if /i "!K!"=="форточка" set "ALT=fortnite"
    if /i "!K!"=="фортнайт 2" set "ALT=fortnite 2"
    if /i "!K!"=="апекс легенд" set "ALT=apex legends"
    if /i "!K!"=="колда варзона" set "ALT=call of duty warzone"
)

goto :eof
