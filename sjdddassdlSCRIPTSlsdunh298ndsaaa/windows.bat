@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
title Поиск аккаунтов Steam — by MisterZidez

set "CURRENT_VERSION=1.1.0"
set "RAW_URL=https://raw.githubusercontent.com/mz-seller-funpay/dfiuh48unfasdimnf78934hnfsdfg4i9m/refs/heads/main/cse4uymth98e7yehx97e4x90gs%%2Cdrlhng580w7"
set "VERSION_URL=https://raw.githubusercontent.com/mz-seller-funpay/dfiuh48unfasdimnf78934hnfsdfg4i9m/refs/heads/main/dUHBIy7bversiond4fonewui"
set "SCRIPT_URL=https://raw.githubusercontent.com/mz-seller-funpay/dfiuh48unfasdimnf78934hnfsdfg4i9m/refs/heads/main/sjdddassdlSCRIPTSlsdunh298ndsaaa/windows.bat"
set "ACCS_FILE=%TEMP%\acc-steam.txt"
set "PS1_FILE=%TEMP%\search_tmp.ps1"
set "NEWVER_FILE=%TEMP%\newver.txt"
set "UPD_FILE=%TEMP%\updated_script.bat"

cls
echo.
echo   Проверка обновлений...
echo.

powershell -NoProfile -Command "try { $v = (Invoke-WebRequest -Uri '%VERSION_URL%' -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop).Content.Trim(); if ($v -ne '%CURRENT_VERSION%') { Write-Output $v; exit 0 } else { exit 1 } } catch { exit 2 }" > "%NEWVER_FILE%" 2>nul

if not exist "%NEWVER_FILE%" goto :after_update_check
set /p NEWVER=<"%NEWVER_FILE%"
del /q "%NEWVER_FILE%" 2>nul

if not defined NEWVER goto :after_update_check

echo   Доступна новая версия: !NEWVER! ^(у вас %CURRENT_VERSION%^)
set /p "UPD=  Обновить скрипт? (y/n): "
if /i not "!UPD!"=="y" (
    echo   Пропускаем обновление.
    goto :after_update_check
)

echo   Скачиваем новую версию...
powershell -NoProfile -Command "try { Invoke-WebRequest -Uri '%SCRIPT_URL%' -UseBasicParsing -TimeoutSec 30 -OutFile '%UPD_FILE%' -ErrorAction Stop; exit 0 } catch { exit 1 }"
if errorlevel 1 (
    echo   [!] Не удалось скачать обновление.
    goto :after_update_check
)

if not exist "%UPD_FILE%" (
    echo   [!] Временный файл обновления не найден.
    goto :after_update_check
)

findstr /c:"RAW_URL" "%UPD_FILE%" >nul 2>nul
if errorlevel 1 (
    echo   [!] Скачанный файл не похож на скрипт. Обновление отменено.
    del /q "%UPD_FILE%" 2>nul
    goto :after_update_check
)

echo   Запускаем обновление...

powershell -NoProfile -Command "Start-Process -WindowStyle Hidden -FilePath 'cmd.exe' -ArgumentList '/c', 'timeout /t 2 >nul & copy /y \"%UPD_FILE%\" \"%~f0\" >nul & del /q \"%UPD_FILE%\" >nul & start \"\" \"%~f0\"'"
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
echo   │   версия: %CURRENT_VERSION%                   │
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

> "%PS1_FILE%" echo param([string]$Query, [string]$File)
>> "%PS1_FILE%" echo $q = $Query.Trim()
>> "%PS1_FILE%" echo $synonyms = @{
>> "%PS1_FILE%" echo     'ведьмак'='witcher'; 'паук'='spider'; 'гта'='grand theft auto'; 'gta'='grand theft auto';
>> "%PS1_FILE%" echo     'ведьмак 3'='witcher 3'; 'скайрим'='skyrim'; 'дум'='doom'; 'мортал'='mortal kombat';
>> "%PS1_FILE%" echo     'резидент'='resident evil'; 'обитель'='resident evil'; 'томб райдер'='tomb raider';
>> "%PS1_FILE%" echo     'дайинг'='dying light'; 'киберпанк'='cyberpunk'; 'хогвартс'='hogwarts';
>> "%PS1_FILE%" echo     'бог войны'='god of war'; 'год оф вар'='god of war'; 'человек паук'='spider-man';
>> "%PS1_FILE%" echo     'последний из нас'='last of us'; 'ласт оф ас'='last of us'; 'мафия'='mafia';
>> "%PS1_FILE%" echo     'душа'='souls'; 'елден'='elden ring'; 'элден'='elden ring'; 'кольцо'='elden ring';
>> "%PS1_FILE%" echo     'сталкер'='stalker'; 'метро'='metro'; 'фоллаут'='fallout'; 'фаллаут'='fallout';
>> "%PS1_FILE%" echo     'ассасин'='assassin'; 'крид'='creed'; 'фар край'='far cry'; 'фаркрай'='far cry';
>> "%PS1_FILE%" echo     'батлфилд'='battlefield'; 'колда'='call of duty'; 'кол оф дьюти'='call of duty';
>> "%PS1_FILE%" echo     'фифа'='fc'; 'фифа 25'='fc 25'; 'еа фк'='fc 25';
>> "%PS1_FILE%" echo     'форза'='forza'; 'хорайзон'='horizon'; 'зелда'='zelda'; 'марио'='mario';
>> "%PS1_FILE%" echo     'сонс оф форест'='sons of the forest'; 'форест'='the forest'; 'лес'='the forest';
>> "%PS1_FILE%" echo     'рафт'='raft'; 'портал'='portal'; 'майнкрафт'='minecraft';
>> "%PS1_FILE%" echo     'террария'='terraria'; 'тетрис'='tetris'; 'варкрафт'='warcraft'; 'старкрафт'='starcraft';
>> "%PS1_FILE%" echo     'ведьмак дикая охота'='witcher 3 wild hunt'; 'киберпанк 2077'='cyberpunk 2077';
>> "%PS1_FILE%" echo     'данганронпа'='danganronpa'; 'данганронпа 2'='danganronpa 2'; 'данганронпа v3'='danganronpa v3';
>> "%PS1_FILE%" echo     'данганронпа 3'='danganronpa v3'; 'данга'='danganronpa';
>> "%PS1_FILE%" echo     'ведьмак 2'='witcher 2'; 'ведьмак 1'='witcher'; 'ведьмак 3 дикая охота'='witcher 3 wild hunt';
>> "%PS1_FILE%" echo     'гвинт'='gwent'; 'киберпанк 2'='cyberpunk 2'; 'ведьмак 4'='witcher 4';
>> "%PS1_FILE%" echo     'дарк соулс'='dark souls'; 'дарк соулз'='dark souls'; 'дарк соулс 3'='dark souls 3';
>> "%PS1_FILE%" echo     'дарк соулс 2'='dark souls 2'; 'дс'='dark souls'; 'дс3'='dark souls 3';
>> "%PS1_FILE%" echo     'секиро'='sekiro'; 'секиро тени умирают дважды'='sekiro'; 'бладборн'='bloodborne';
>> "%PS1_FILE%" echo     'блудборн'='bloodborne'; 'армор кор'='armored core'; 'арморд кор'='armored core';
>> "%PS1_FILE%" echo     'армор кор 6'='armored core 6'; 'нио'='nioh'; 'нио 2'='nioh 2'; 'лайс оф пи'='lies of p';
>> "%PS1_FILE%" echo     'лордс оф зе фоллен'='lords of the fallen';
>> "%PS1_FILE%" echo     'гта 5'='gta 5'; 'гта5'='gta 5'; 'гта 6'='gta 6'; 'гта 4'='gta 4';
>> "%PS1_FILE%" echo     'гта сан'='gta san andreas'; 'сан андреас'='gta san andreas';
>> "%PS1_FILE%" echo     'рдр'='red dead redemption'; 'рдр 2'='red dead redemption 2';
>> "%PS1_FILE%" echo     'ред дед'='red dead redemption'; 'ред дед 2'='red dead redemption 2';
>> "%PS1_FILE%" echo     'мафия 2'='mafia 2'; 'мафия 3'='mafia 3'; 'мафия 1'='mafia definitive edition';
>> "%PS1_FILE%" echo     'буллы'='bully'; 'ла нойр'='l.a. noire';
>> "%PS1_FILE%" echo     'скайрим 2'='skyrim'; 'обливион'='oblivion'; 'морровинд'='morrowind';
>> "%PS1_FILE%" echo     'фоллаут 4'='fallout 4'; 'фоллаут 3'='fallout 3'; 'фоллаут 76'='fallout 76';
>> "%PS1_FILE%" echo     'фоллаут нью вегас'='fallout new vegas'; 'нью вегас'='fallout new vegas';
>> "%PS1_FILE%" echo     'старфилд'='starfield'; 'дум 2016'='doom 2016'; 'дум этернал'='doom eternal';
>> "%PS1_FILE%" echo     'дум 3'='doom 3'; 'квикс'='quake'; 'вольфенштейн'='wolfenstein';
>> "%PS1_FILE%" echo     'ассасин крид'='assassins creed'; 'ассасин 2'='assassins creed 2';
>> "%PS1_FILE%" echo     'ассасин 4'='assassins creed 4'; 'ассасин блэк флаг'='assassins creed black flag';
>> "%PS1_FILE%" echo     'ассасин вальгалла'='assassins creed valhalla'; 'вальгалла'='assassins creed valhalla';
>> "%PS1_FILE%" echo     'ассасин ориджинс'='assassins creed origins'; 'ориджинс'='assassins creed origins';
>> "%PS1_FILE%" echo     'ассасин одессей'='assassins creed odyssey'; 'одессей'='assassins creed odyssey';
>> "%PS1_FILE%" echo     'ассасин мираж'='assassins creed mirage'; 'миража'='assassins creed mirage';
>> "%PS1_FILE%" echo     'фар край 3'='far cry 3'; 'фар край 4'='far cry 4'; 'фар край 5'='far cry 5';
>> "%PS1_FILE%" echo     'фар край 6'='far cry 6'; 'примал'='far cry primal'; 'фар край нью давн'='far cry new dawn';
>> "%PS1_FILE%" echo     'дивижн'='the division'; 'дивижн 2'='the division 2'; 'рэйнбоу сикс'='rainbow six';
>> "%PS1_FILE%" echo     'р6'='rainbow six siege'; 'рэйнбоу сикс сидж'='rainbow six siege';
>> "%PS1_FILE%" echo     'принс оф персия'='prince of persia'; 'принц персии'='prince of persia';
>> "%PS1_FILE%" echo     'сплинтер селл'='splinter cell'; 'сплинтер'='splinter cell';
>> "%PS1_FILE%" echo     'варч'='watch dogs'; 'вотч догс'='watch dogs'; 'вотч догс 2'='watch dogs 2';
>> "%PS1_FILE%" echo     'вотч догс лиджн'='watch dogs legion'; 'легион'='watch dogs legion';
>> "%PS1_FILE%" echo     'фор хонор'='for honor'; 'гоуст рикон'='ghost recon'; 'гоуст рекон'='ghost recon';
>> "%PS1_FILE%" echo     'тхе крю'='the crew'; 'трекмания'='trackmania'; 'райман'='rayman';
>> "%PS1_FILE%" echo     'колда мв2'='call of duty mw2'; 'мв2'='call of duty mw2';
>> "%PS1_FILE%" echo     'мв3'='call of duty mw3'; 'варзона'='call of duty warzone'; 'варзоне'='call of duty warzone';
>> "%PS1_FILE%" echo     'код'='call of duty'; 'батла'='battlefield'; 'батлфилд 1'='battlefield 1';
>> "%PS1_FILE%" echo     'батлфилд 4'='battlefield 4'; 'батлфилд 2042'='battlefield 2042'; 'бф4'='battlefield 4';
>> "%PS1_FILE%" echo     'апекс'='apex legends'; 'апекс легендс'='apex legends'; 'титанфолл'='titanfall';
>> "%PS1_FILE%" echo     'титанфолл 2'='titanfall 2'; 'дестини'='destiny'; 'дестини 2'='destiny 2';
>> "%PS1_FILE%" echo     'овервотч'='overwatch'; 'овервоч'='overwatch'; 'оверватч'='overwatch'; 'ов'='overwatch';
>> "%PS1_FILE%" echo     'ов 2'='overwatch 2'; 'овервотч 2'='overwatch 2'; 'паладинс'='paladins';
>> "%PS1_FILE%" echo     'валорант'='valorant'; 'кске'='cs2'; 'кс 2'='cs2';
>> "%PS1_FILE%" echo     'кс го'='csgo'; 'ксго'='csgo'; 'контра'='counter-strike'; 'контер страйк'='counter-strike';
>> "%PS1_FILE%" echo     'р6с'='rainbow six siege'; 'хитмен'='hitman'; 'хитман 3'='hitman 3';
>> "%PS1_FILE%" echo     'фифа 24'='fc 24'; 'фифа 23'='fifa 23'; 'фифа 22'='fifa 22'; 'фифа 21'='fifa 21';
>> "%PS1_FILE%" echo     'фк 24'='fc 24'; 'фк 25'='fc 25'; 'еа фк 25'='fc 25'; 'нхл'='nhl'; 'нба'='nba 2k';
>> "%PS1_FILE%" echo     'нба 2к'='nba 2k'; 'мадден'='madden'; 'уефа'='uefa'; 'ф1'='f1'; 'ф1 24'='f1 24';
>> "%PS1_FILE%" echo     'скайфолл'='skyfall'; 'нид фор спид'='need for speed'; 'нфс'='need for speed';
>> "%PS1_FILE%" echo     'нид фор спид мост вантед'='need for speed most wanted'; 'мост вантед'='need for speed most wanted';
>> "%PS1_FILE%" echo     'нид фор спид хит'='need for speed heat'; 'хит нфс'='need for speed heat';
>> "%PS1_FILE%" echo     'анбаунд'='need for speed unbound'; 'нфс анбаунд'='need for speed unbound';
>> "%PS1_FILE%" echo     'биошок'='bioshock'; 'биошок 2'='bioshock 2'; 'биошок инфинити'='bioshock infinite';
>> "%PS1_FILE%" echo     'бордерлендс'='borderlands'; 'бордерлендс 2'='borderlands 2'; 'бордерлендс 3'='borderlands 3';
>> "%PS1_FILE%" echo     'блур'='borderlands'; 'сивилизейшн'='civilization'; 'цива'='civilization';
>> "%PS1_FILE%" echo     'цивилизация'='civilization'; 'цив 6'='civilization 6'; 'цива 6'='civilization 6';
>> "%PS1_FILE%" echo     'ксеком'='xcom'; 'ксеном'='xcom'; 'ксеном 2'='xcom 2'; 'мафия дефинитив'='mafia definitive edition';
>> "%PS1_FILE%" echo     'персона'='persona'; 'персона 5'='persona 5'; 'персона 4'='persona 4'; 'персона 3'='persona 3';
>> "%PS1_FILE%" echo     'персона 5 роял'='persona 5 royal'; 'п5р'='persona 5 royal'; 'п5'='persona 5';
>> "%PS1_FILE%" echo     'соул хакерс'='soul hackers'; 'шх2'='soul hackers 2'; 'метафор'='metaphor refantazio';
>> "%PS1_FILE%" echo     'метафора'='metaphor refantazio'; 'катсураги'='catherine'; 'кетрин'='catherine';
>> "%PS1_FILE%" echo     'ярн'='yakuza'; 'якудза'='yakuza'; 'якудза 0'='yakuza 0'; 'якудза лайк э драгон'='yakuza like a dragon';
>> "%PS1_FILE%" echo     'лайк э драгон'='yakuza like a dragon'; 'джаджмент'='judgment'; 'лондон'='yakuza';
>> "%PS1_FILE%" echo     'соник'='sonic'; 'соник фронтьерс'='sonic frontiers';
>> "%PS1_FILE%" echo     'тотал вар'='total war'; 'тотал вор'='total war'; 'тотал вар вархаммер'='total war warhammer';
>> "%PS1_FILE%" echo     'тв вархаммер'='total war warhammer'; 'футбал менеджер'='football manager'; 'фм'='football manager';
>> "%PS1_FILE%" echo     'зельда'='zelda'; 'зельда ботв'='zelda breath of the wild'; 'ботв'='zelda breath of the wild';
>> "%PS1_FILE%" echo     'тотк'='zelda tears of the kingdom'; 'тиарс оф зе киндом'='zelda tears of the kingdom';
>> "%PS1_FILE%" echo     'марио карт'='mario kart'; 'марио карт 8'='mario kart 8'; 'марио оддиси'='mario odyssey';
>> "%PS1_FILE%" echo     'супер марио'='super mario'; 'супер марио брос'='super mario bros'; 'смб'='super mario bros';
>> "%PS1_FILE%" echo     'покемон'='pokemon'; 'покемоны'='pokemon'; 'покемон го'='pokemon go';
>> "%PS1_FILE%" echo     'свитч'='switch'; 'ниндтендо'='nintendo'; 'нинтендо'='nintendo'; 'свич'='switch';
>> "%PS1_FILE%" echo     'сплэтун'='splatoon'; 'сплатун'='splatoon'; 'метроид'='metroid'; 'метроид дред'='metroid dread';
>> "%PS1_FILE%" echo     'кирби'='kirby'; 'донки конг'='donkey kong'; 'энимал кроссинг'='animal crossing';
>> "%PS1_FILE%" echo     'анимал кроссинг'='animal crossing'; 'энимал кросинг'='animal crossing';
>> "%PS1_FILE%" echo     'анчартед'='uncharted'; 'анчартед 4'='uncharted 4'; 'анчартед 2'='uncharted 2';
>> "%PS1_FILE%" echo     'анч'='uncharted'; 'бог войны 2018'='god of war 2018'; 'год оф вар рагнарок'='god of war ragnarok';
>> "%PS1_FILE%" echo     'рагнарек'='god of war ragnarok'; 'рагнарок'='god of war ragnarok';
>> "%PS1_FILE%" echo     'год оф вар 3'='god of war 3'; 'год 3'='god of war 3';
>> "%PS1_FILE%" echo     'хорайзон зеро давн'='horizon zero dawn'; 'хорайзон 2'='horizon forbidden west';
>> "%PS1_FILE%" echo     'запретный запад'='horizon forbidden west'; 'хорайзон форбидден вест'='horizon forbidden west';
>> "%PS1_FILE%" echo     'ласт оф ас 2'='last of us 2'; 'ласт оф ас парт 2'='last of us part 2'; 'лоу 2'='last of us 2';
>> "%PS1_FILE%" echo     'ласт оф ас 1'='last of us part 1'; 'ласт оф ас ремейк'='last of us part 1';
>> "%PS1_FILE%" echo     'гоуст оф цушима'='ghost of tsushima'; 'гоуст'='ghost of tsushima'; 'цусима'='ghost of tsushima';
>> "%PS1_FILE%" echo     'гоуст оф цусима'='ghost of tsushima'; 'спайдермен'='spider-man'; 'спайдер мен'='spider-man';
>> "%PS1_FILE%" echo     'человек паук 2'='spider-man 2'; 'спайдермен 2'='spider-man 2'; 'человек-паук 2'='spider-man 2';
>> "%PS1_FILE%" echo     'майлз моралес'='spider-man miles morales'; 'майлз'='spider-man miles morales';
>> "%PS1_FILE%" echo     'ратчет и кланк'='ratchet and clank'; 'ратчет'='ratchet and clank';
>> "%PS1_FILE%" echo     'бладборн 2'='bloodborne 2'; 'ретурнал'='returnal'; 'демонс соулс'='demons souls';
>> "%PS1_FILE%" echo     'демон соулс'='demons souls'; 'сайлент хилл'='silent hill'; 'сайлент хилл 2'='silent hill 2';
>> "%PS1_FILE%" echo     'дес стрендинг'='death stranding'; 'дес стрендинг 2'='death stranding 2'; 'дс2'='death stranding 2';
>> "%PS1_FILE%" echo     'дэйс ган'='days gone'; 'дейс ган'='days gone'; 'инфэмос'='infamous'; 'инфамос'='infamous';
>> "%PS1_FILE%" echo     'киллзоун'='killzone'; 'гран туризмо'='gran turismo'; 'гт'='gran turismo'; 'гт7'='gran turismo 7';
>> "%PS1_FILE%" echo     'резидент ивел'='resident evil'; 'резидент ивел 2'='resident evil 2'; 'ре2'='resident evil 2';
>> "%PS1_FILE%" echo     'резидент ивел 4'='resident evil 4'; 'ре4'='resident evil 4'; 'резидент 4'='resident evil 4';
>> "%PS1_FILE%" echo     'резидент ивел 7'='resident evil 7'; 'ре7'='resident evil 7'; 'резидент 7'='resident evil 7';
>> "%PS1_FILE%" echo     'резидент ивел вилладж'='resident evil village'; 'вилладж'='resident evil village';
>> "%PS1_FILE%" echo     'ре3'='resident evil 3'; 'резидент ивел 3'='resident evil 3'; 'резидент 3'='resident evil 3';
>> "%PS1_FILE%" echo     'девил мэй край'='devil may cry'; 'дмс'='devil may cry'; 'дмк'='devil may cry';
>> "%PS1_FILE%" echo     'девил мей край 5'='devil may cry 5'; 'дмк 5'='devil may cry 5'; 'дмс 5'='devil may cry 5';
>> "%PS1_FILE%" echo     'монстер хантер'='monster hunter'; 'мх'='monster hunter'; 'монстер хантер ворлд'='monster hunter world';
>> "%PS1_FILE%" echo     'мх ворлд'='monster hunter world'; 'монстер хантер райз'='monster hunter rise'; 'мх райз'='monster hunter rise';
>> "%PS1_FILE%" echo     'монстер хантер вайлдс'='monster hunter wilds'; 'мх вайлдс'='monster hunter wilds';
>> "%PS1_FILE%" echo     'драгонс догма'='dragons dogma'; 'драгон догма 2'='dragons dogma 2'; 'дд2'='dragons dogma 2';
>> "%PS1_FILE%" echo     'онимьюша'='onimusha'; 'онемуша'='onimusha'; 'асура'='asuras wrath';
>> "%PS1_FILE%" echo     'стрит файтер'='street fighter'; 'сф'='street fighter'; 'стрит файтер 6'='street fighter 6';
>> "%PS1_FILE%" echo     'стф 6'='street fighter 6'; 'теккен'='tekken'; 'теккен 8'='tekken 8'; 'т8'='tekken 8';
>> "%PS1_FILE%" echo     'соулкалибур'='soulcalibur'; 'соул калибур'='soulcalibur'; 'мортал комбат'='mortal kombat';
>> "%PS1_FILE%" echo     'мк'='mortal kombat'; 'мк1'='mortal kombat 1'; 'мк 11'='mortal kombat 11'; 'мортал 11'='mortal kombat 11';
>> "%PS1_FILE%" echo     'мортал комбат 1'='mortal kombat 1'; 'инджастис'='injustice'; 'инджастис 2'='injustice 2';
>> "%PS1_FILE%" echo     'финал фэнтези'='final fantasy'; 'фф'='final fantasy'; 'финалка'='final fantasy';
>> "%PS1_FILE%" echo     'фф7'='final fantasy 7'; 'финал фэнтези 7'='final fantasy 7'; 'фф7 ремейк'='final fantasy 7 remake';
>> "%PS1_FILE%" echo     'фф7 ребёрс'='final fantasy 7 rebirth'; 'фф16'='final fantasy 16'; 'финал фэнтези 16'='final fantasy 16';
>> "%PS1_FILE%" echo     'фф14'='final fantasy 14'; 'фф15'='final fantasy 15'; 'фф10'='final fantasy 10';
>> "%PS1_FILE%" echo     'кингдом хартс'='kingdom hearts'; 'кх'='kingdom hearts'; 'кингдом хартс 3'='kingdom hearts 3';
>> "%PS1_FILE%" echo     'драгон квест'='dragon quest'; 'дк'='dragon quest'; 'драгон квест 11'='dragon quest 11';
>> "%PS1_FILE%" echo     'ниер'='nier'; 'ниер автомата'='nier automata'; 'нир автомата'='nier automata';
>> "%PS1_FILE%" echo     'ниер репликант'='nier replicant'; 'нир репликант'='nier replicant';
>> "%PS1_FILE%" echo     'драгон квест билдерс'='dragon quest builders'; 'октопат'='octopath traveler';
>> "%PS1_FILE%" echo     'октопат 2'='octopath traveler 2'; 'триангл'='triangle strategy'; 'бравелли'='bravely default';
>> "%PS1_FILE%" echo     'паразит ив'='parasite eve'; 'кронос'='chrono trigger'; 'хроно'='chrono trigger';
>> "%PS1_FILE%" echo     'дарк соулс ремастер'='dark souls remastered'; 'дср'='dark souls remastered';
>> "%PS1_FILE%" echo     'элден ринг шэдоу'='elden ring shadow of the erdtree'; 'эрдтри'='elden ring shadow of the erdtree';
>> "%PS1_FILE%" echo     'арморд кор 6'='armored core 6'; 'ас6'='armored core 6';
>> "%PS1_FILE%" echo     'теккен 7'='tekken 7'; 'т7'='tekken 7'; 'соул калибур 6'='soulcalibur 6'; 'ск6'='soulcalibur 6';
>> "%PS1_FILE%" echo     'наруто'='naruto'; 'наруто шиппуден'='naruto shippuden'; 'наруто ултимейт'='naruto ultimate ninja storm';
>> "%PS1_FILE%" echo     'ултимейт ниндзя шторм'='naruto ultimate ninja storm'; 'ултимейт ниндзя сторм'='naruto ultimate ninja storm';
>> "%PS1_FILE%" echo     'джамп форс'='jump force'; 'дрэгон бол'='dragon ball'; 'дрэгон болл'='dragon ball';
>> "%PS1_FILE%" echo     'драгон бол'='dragon ball'; 'драгонбол'='dragon ball'; 'дбз'='dragon ball z';
>> "%PS1_FILE%" echo     'драгон болл з'='dragon ball z'; 'какарот'='dragon ball z kakarot';
>> "%PS1_FILE%" echo     'драгон болл файтерз'='dragon ball fighterz'; 'дбфз'='dragon ball fighterz';
>> "%PS1_FILE%" echo     'ван пис'='one piece'; 'уан пис'='one piece'; 'уанпис'='one piece';
>> "%PS1_FILE%" echo     'соник 2'='sonic 2'; 'соник адвенчер'='sonic adventure'; 'соник мэния'='sonic mania';
>> "%PS1_FILE%" echo     'соник суперстарз'='sonic superstars'; 'соник и сотс'='sonic and the secret rings';
>> "%PS1_FILE%" echo     'якудза 6'='yakuza 6'; 'якудза 7'='yakuza 7'; 'якудза кивами'='yakuza kiwami';
>> "%PS1_FILE%" echo     'якудза кивами 2'='yakuza kiwami 2'; 'исчин'='yakuza ishin';
>> "%PS1_FILE%" echo     'лост джаджмент'='lost judgment'; 'like a dragon gaiden'='like a dragon gaiden';
>> "%PS1_FILE%" echo     'лайк э драгон гайден'='like a dragon gaiden'; 'лайк э драгон инфинит'='like a dragon infinite wealth';
>> "%PS1_FILE%" echo     'сталкрафт 2'='starcraft 2'; 'ст2'='starcraft 2'; 'старкрафт 2'='starcraft 2';
>> "%PS1_FILE%" echo     'варкрафт 3'='warcraft 3'; 'вк3'='warcraft 3'; 'варкрафт 2'='warcraft 2';
>> "%PS1_FILE%" echo     'ворлд оф варкрафт'='world of warcraft'; 'вов'='world of warcraft'; 'вов классик'='wow classic';
>> "%PS1_FILE%" echo     'диабло'='diablo'; 'диабло 2'='diablo 2'; 'диабло 3'='diablo 3'; 'диабло 4'='diablo 4'; 'д3'='diablo 3';
>> "%PS1_FILE%" echo     'д4'='diablo 4'; 'диабло 2 резурректед'='diablo 2 resurrected'; 'д2р'='diablo 2 resurrected';
>> "%PS1_FILE%" echo     'овервотч классик'='overwatch classic'; 'пат оф экзайл'='path of exile'; 'поэ'='path of exile';
>> "%PS1_FILE%" echo     'поэ 2'='path of exile 2'; 'пат оф экзайл 2'='path of exile 2'; 'грим давн'='grim dawn';
>> "%PS1_FILE%" echo     'титан квест'='titan quest'; 'титан квест 2'='titan quest 2'; 'торчлайт'='torchlight';
>> "%PS1_FILE%" echo     'аге оф эмпайрс'='age of empires'; 'аое'='age of empires'; 'аге оф эмпайрс 2'='age of empires 2';
>> "%PS1_FILE%" echo     'аое 2'='age of empires 2'; 'аге оф эмпайрс 4'='age of empires 4'; 'аое 4'='age of empires 4';
>> "%PS1_FILE%" echo     'комманд энд конкер'='command and conquer'; 'кнк'='command and conquer'; 'ред алерт'='red alert';
>> "%PS1_FILE%" echo     'ред алерт 2'='red alert 2'; 'ра2'='red alert 2'; 'тиберриум'='tiberium';
>> "%PS1_FILE%" echo     'анно'='anno'; 'anno 1800'='anno 1800'; 'анно 1800'='anno 1800'; 'анно 2070'='anno 2070';
>> "%PS1_FILE%" echo     'ситис скаяйнс'='cities skylines'; 'сити скаяйнс'='cities skylines'; 'ситис 2'='cities skylines 2';
>> "%PS1_FILE%" echo     'симс'='the sims'; 'симс 4'='the sims 4'; 'симс 5'='the sims 5'; 'симс 3'='the sims 3';
>> "%PS1_FILE%" echo     'планет костер'='planet coaster'; 'планет коустер'='planet coaster'; 'планет зоо'='planet zoo';
>> "%PS1_FILE%" echo     'фростпанк'='frostpunk'; 'фростпанк 2'='frostpunk 2'; 'тропико'='tropico'; 'тропико 6'='tropico 6';
>> "%PS1_FILE%" echo     'сурвайвинг марс'='surviving mars'; 'сурвайвинг'='surviving mars';
>> "%PS1_FILE%" echo     'энной'='anno'; 'факторио'='factorio'; 'факторио 2'='factorio 2'; 'сатисфактори'='satisfactory';
>> "%PS1_FILE%" echo     'рифтворлд'='riftworld'; 'валхейм'='valheim'; 'валхейм 2'='valheim 2';
>> "%PS1_FILE%" echo     'раст'='rust'; 'раст 2'='rust 2'; 'арк'='ark survival evolved'; 'арк сурвайвал'='ark survival evolved';
>> "%PS1_FILE%" echo     'арк 2'='ark 2'; 'палворлд'='palworld'; 'пал ворлд'='palworld'; 'эншраудед'='enshrouded';
>> "%PS1_FILE%" echo     'дед бай дейлайт'='dead by daylight'; 'дбд'='dead by daylight'; 'дед бай'='dead by daylight';
>> "%PS1_FILE%" echo     'фрайдей 13'='friday the 13th'; 'фрайдэй'='friday the 13th'; 'лефт фор дед'='left 4 dead';
>> "%PS1_FILE%" echo     'л4д'='left 4 dead'; 'лефт фор дед 2'='left 4 dead 2'; 'л4д2'='left 4 dead 2';
>> "%PS1_FILE%" echo     'бэк 4 блад'='back 4 blood'; 'бэк фор блад'='back 4 blood'; 'б4б'='back 4 blood';
>> "%PS1_FILE%" echo     'верминтайд'='vermintide'; 'верминтайд 2'='vermintide 2'; 'дарктайд'='darktide';
>> "%PS1_FILE%" echo     'дип рок'='deep rock galactic'; 'дрг'='deep rock galactic'; 'хеллдайверс'='helldivers';
>> "%PS1_FILE%" echo     'хеллдайверс 2'='helldivers 2'; 'хд2'='helldivers 2'; 'хеллдавэрс'='helldivers';
>> "%PS1_FILE%" echo     'гта онлайн'='gta online'; 'гтао'='gta online'; 'рдр онлайн'='red dead online'; 'рдо'='red dead online';
>> "%PS1_FILE%" echo     'зе форест'='the forest'; 'сонс оф зе форест'='sons of the forest';
>> "%PS1_FILE%" echo     'соны фореста'='sons of the forest'; 'грин хелл'='green hell'; 'гринхелл'='green hell';
>> "%PS1_FILE%" echo     'сабнавтика'='subnautica'; 'сабнотика'='subnautica'; 'сабнавтика 2'='subnautica 2';
>> "%PS1_FILE%" echo     'сабнавтика бз'='subnautica below zero'; 'белоу зиро'='subnautica below zero';
>> "%PS1_FILE%" echo     'ноу мэнс скай'='no mans sky'; 'номанс скай'='no mans sky'; 'номанскай'='no mans sky';
>> "%PS1_FILE%" echo     'стардев вэлли'='stardew valley'; 'стардью'='stardew valley'; 'стардью вэлли'='stardew valley';
>> "%PS1_FILE%" echo     'анимал кроссинг нью хорайзонс'='animal crossing new horizons'; 'аснх'='animal crossing new horizons';
>> "%PS1_FILE%" echo     'гравити фоллс'='gravity falls'; 'гравити'='gravity falls'; 'хадес'='hades'; 'хадес 2'='hades 2';
>> "%PS1_FILE%" echo     'дед селс'='dead cells'; 'дед селлс'='dead cells'; 'скул'='skul'; 'скул зе хироу'='skul the hero slayer';
>> "%PS1_FILE%" echo     'инскрипшн'='inscryption'; 'инскрипшен'='inscryption'; 'слэй зе спайр'='slay the spire';
>> "%PS1_FILE%" echo     'слэй'='slay the spire'; 'балатро'='balatro'; 'вампир сурвайворс'='vampire survivors';
>> "%PS1_FILE%" echo     'вампир сурвайвор'='vampire survivors'; 'бротато'='brotato';
>> "%PS1_FILE%" echo     'майнкрафт 2'='minecraft 2'; 'майнкрафт данженс'='minecraft dungeons'; 'майн данженс'='minecraft dungeons';
>> "%PS1_FILE%" echo     'майнкрафт легендс'='minecraft legends'; 'майн легендс'='minecraft legends';
>> "%PS1_FILE%" echo     'роблокс'='roblox'; 'роблокс 2'='roblox 2'; 'роблокс студио'='roblox studio';
>> "%PS1_FILE%" echo     'фортнайт'='fortnite'; 'форточка'='fortnite'; 'фортнайт 2'='fortnite 2';
>> "%PS1_FILE%" echo     'апекс легенд'='apex legends'; 'колда варзона'='call of duty warzone'
>> "%PS1_FILE%" echo }
>> "%PS1_FILE%" echo $qLower = $q.ToLower()
>> "%PS1_FILE%" echo $altQuery = $synonyms[$qLower]
>> "%PS1_FILE%" echo $queries = @($q)
>> "%PS1_FILE%" echo if ($altQuery) { $queries += $altQuery }
>> "%PS1_FILE%" echo $lines = [System.IO.File]::ReadAllLines($File, [System.Text.Encoding]::UTF8)
>> "%PS1_FILE%" echo $found = 0
>> "%PS1_FILE%" echo $games = ''
>> "%PS1_FILE%" echo $login = ''
>> "%PS1_FILE%" echo $pass = ''
>> "%PS1_FILE%" echo $match = $false
>> "%PS1_FILE%" echo function Format-Games($gamesLine, $queryList) {
>> "%PS1_FILE%" echo     $gamesText = $gamesLine -replace '^^.*Игры:\s*', ''
>> "%PS1_FILE%" echo     $games = $gamesText -split ',\s*'
>> "%PS1_FILE%" echo     $total = $games.Count
>> "%PS1_FILE%" echo     $matched = @()
>> "%PS1_FILE%" echo     foreach ($qq in $queryList) { $matched += @($games ^| Where-Object { $_ -match [regex]::Escape($qq) }) }
>> "%PS1_FILE%" echo     $matched = @($matched ^| Select-Object -Unique)
>> "%PS1_FILE%" echo     if ($total -le 3) { return ($games -join ', ') }
>> "%PS1_FILE%" echo     if ($matched.Count -ge 1) {
>> "%PS1_FILE%" echo         $shown = $matched[0..([Math]::Min($matched.Count-1, 2))]
>> "%PS1_FILE%" echo         $rest = $total - $shown.Count
>> "%PS1_FILE%" echo         if ($rest -gt 0) { return (($shown -join ', ') + '  +' + $rest + ' игр') } else { return ($shown -join ', ') }
>> "%PS1_FILE%" echo     } else {
>> "%PS1_FILE%" echo         $shown = $games[0..2]
>> "%PS1_FILE%" echo         return (($shown -join ', ') + '  +' + ($total - 3) + ' игр')
>> "%PS1_FILE%" echo     }
>> "%PS1_FILE%" echo }
>> "%PS1_FILE%" echo foreach ($line in $lines) {
>> "%PS1_FILE%" echo     if ($line -match '^^🎮') {
>> "%PS1_FILE%" echo         $games = $line; $login = ''; $pass = ''; $match = $false
>> "%PS1_FILE%" echo         foreach ($qq in $queries) { if ($line -match [regex]::Escape($qq)) { $match = $true; break } }
>> "%PS1_FILE%" echo     }
>> "%PS1_FILE%" echo     elseif ($line -match '^^👤') { $login = $line }
>> "%PS1_FILE%" echo     elseif ($line -match '^^🔒') { $pass = $line }
>> "%PS1_FILE%" echo     elseif ($line.Trim() -eq '') {
>> "%PS1_FILE%" echo         if ($match) {
>> "%PS1_FILE%" echo             Write-Host ('  🎮 ' + (Format-Games $games $queries)) -ForegroundColor Yellow
>> "%PS1_FILE%" echo             Write-Host ('     ' + ($login -replace '^^👤\s*Логин:\s*','Логин: ')) -ForegroundColor Green
>> "%PS1_FILE%" echo             Write-Host ('     ' + ($pass -replace '^^🔒\s*Пароль:\s*','Пароль: ')) -ForegroundColor DarkGray
>> "%PS1_FILE%" echo             Write-Host ''
>> "%PS1_FILE%" echo             $found++
>> "%PS1_FILE%" echo             $match = $false
>> "%PS1_FILE%" echo         }
>> "%PS1_FILE%" echo     }
>> "%PS1_FILE%" echo }
>> "%PS1_FILE%" echo if ($match) {
>> "%PS1_FILE%" echo     Write-Host ('  🎮 ' + (Format-Games $games $queries)) -ForegroundColor Yellow
>> "%PS1_FILE%" echo     Write-Host ('     ' + ($login -replace '^^👤\s*Логин:\s*','Логин: ')) -ForegroundColor Green
>> "%PS1_FILE%" echo     Write-Host ('     ' + ($pass -replace '^^🔒\s*Пароль:\s*','Пароль: ')) -ForegroundColor DarkGray
>> "%PS1_FILE%" echo     Write-Host ''
>> "%PS1_FILE%" echo     $found++
>> "%PS1_FILE%" echo }
>> "%PS1_FILE%" echo Write-Host ('  ──────────────────────────────────────────') -ForegroundColor DarkGray
>> "%PS1_FILE%" echo if ($found -eq 0) {
>> "%PS1_FILE%" echo     Write-Host ('  Ничего не найдено.') -ForegroundColor Red
>> "%PS1_FILE%" echo     if ($altQuery) { Write-Host ('  (искали также: ' + $altQuery + ')') -ForegroundColor DarkGray }
>> "%PS1_FILE%" echo } else {
>> "%PS1_FILE%" echo     Write-Host ('  Найдено: ' + $found) -ForegroundColor Cyan
>> "%PS1_FILE%" echo     if ($altQuery) { Write-Host ('  (искали также: ' + $altQuery + ')') -ForegroundColor DarkGray }
>> "%PS1_FILE%" echo }

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1_FILE%" -Query "%QUERY%" -File "%ACCS_FILE%"

del /q "%PS1_FILE%" 2>nul

echo.
pause
cls
goto :search
