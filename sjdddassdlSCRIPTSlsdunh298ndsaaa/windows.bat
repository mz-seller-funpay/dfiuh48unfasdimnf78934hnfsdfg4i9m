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

powershell -NoProfile -Command "$b64 = (Invoke-WebRequest -Uri '%RAW_URL%' -UseBasicParsing).Content; $b64 = $b64 -replace '\s',''; $bytes = [Convert]::FromBase64String($b64); [IO.File]::WriteAllBytes('%ACCS_FILE%', $bytes)"
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

powershell -NoProfile -Command "$c = [IO.File]::ReadAllText('%ACCS_FILE%', [Text.Encoding]::UTF8); if ($c -match 'Логин:') { exit 0 } else { exit 1 }"
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

rem === Записываем PowerShell-код поиска через отдельный PowerShell (не через echo) ===
powershell -NoProfile -Command ^
  "$ps = @'" ^
  "param([string]$Query, [string]$File)" ^
  "$q = $Query.Trim()" ^
  "$synonyms = @{" ^
  "    'ведьмак'='witcher'; 'паук'='spider'; 'гта'='grand theft auto'; 'gta'='grand theft auto';" ^
  "    'ведьмак 3'='witcher 3'; 'скайрим'='skyrim'; 'дум'='doom'; 'мортал'='mortal kombat';" ^
  "    'резидент'='resident evil'; 'обитель'='resident evil'; 'томб райдер'='tomb raider';" ^
  "    'дайинг'='dying light'; 'киберпанк'='cyberpunk'; 'хогвартс'='hogwarts';" ^
  "    'бог войны'='god of war'; 'год оф вар'='god of war'; 'человек паук'='spider-man';" ^
  "    'последний из нас'='last of us'; 'ласт оф ас'='last of us'; 'мафия'='mafia';" ^
  "    'душа'='souls'; 'елден'='elden ring'; 'элден'='elden ring'; 'кольцо'='elden ring';" ^
  "    'сталкер'='stalker'; 'метро'='metro'; 'фоллаут'='fallout'; 'фаллаут'='fallout';" ^
  "    'ассасин'='assassin'; 'крид'='creed'; 'фар край'='far cry'; 'фаркрай'='far cry';" ^
  "    'батлфилд'='battlefield'; 'колда'='call of duty'; 'кол оф дьюти'='call of duty';" ^
  "    'фифа'='fc'; 'фифа 25'='fc 25'; 'еа фк'='fc 25';" ^
  "    'форза'='forza'; 'хорайзон'='horizon'; 'зелда'='zelda'; 'марио'='mario';" ^
  "    'сонс оф форест'='sons of the forest'; 'форест'='the forest'; 'лес'='the forest';" ^
  "    'рафт'='raft'; 'портал'='portal'; 'майнкрафт'='minecraft';" ^
  "    'террария'='terraria'; 'тетрис'='tetris'; 'варкрафт'='warcraft'; 'старкрафт'='starcraft';" ^
  "    'ведьмак дикая охота'='witcher 3 wild hunt'; 'киберпанк 2077'='cyberpunk 2077';" ^
  "    'данганронпа'='danganronpa'; 'данганронпа 2'='danganronpa 2'; 'данганронпа v3'='danganronpa v3';" ^
  "    'данганронпа 3'='danganronpa v3'; 'данга'='danganronpa';" ^
  "    'ведьмак 2'='witcher 2'; 'ведьмак 1'='witcher';" ^
  "    'гвинт'='gwent'; 'киберпанк 2'='cyberpunk 2'; 'ведьмак 4'='witcher 4';" ^
  "    'дарк соулс'='dark souls'; 'дарк соулз'='dark souls'; 'дарк соулс 3'='dark souls 3';" ^
  "    'дарк соулс 2'='dark souls 2'; 'дс'='dark souls'; 'дс3'='dark souls 3';" ^
  "    'секиро'='sekiro'; 'бладборн'='bloodborne'; 'армор кор'='armored core';" ^
  "    'армор кор 6'='armored core 6'; 'нио'='nioh'; 'нио 2'='nioh 2'; 'лайс оф пи'='lies of p';" ^
  "    'лордс оф зе фоллен'='lords of the fallen';" ^
  "    'гта 5'='gta 5'; 'гта5'='gta 5'; 'гта 6'='gta 6'; 'гта 4'='gta 4';" ^
  "    'гта сан'='gta san andreas'; 'сан андреас'='gta san andreas';" ^
  "    'рдр'='red dead redemption'; 'рдр 2'='red dead redemption 2';" ^
  "    'ред дед'='red dead redemption'; 'ред дед 2'='red dead redemption 2';" ^
  "    'мафия 2'='mafia 2'; 'мафия 3'='mafia 3'; 'мафия 1'='mafia definitive edition';" ^
  "    'буллы'='bully'; 'ла нойр'='l.a. noire';" ^
  "    'скайрим 2'='skyrim'; 'обливион'='oblivion'; 'морровинд'='morrowind';" ^
  "    'фоллаут 4'='fallout 4'; 'фоллаут 3'='fallout 3'; 'фоллаут 76'='fallout 76';" ^
  "    'фоллаут нью вегас'='fallout new vegas'; 'нью вегас'='fallout new vegas';" ^
  "    'старфилд'='starfield'; 'дум 2016'='doom 2016'; 'дум этернал'='doom eternal';" ^
  "    'дум 3'='doom 3'; 'квикс'='quake'; 'вольфенштейн'='wolfenstein';" ^
  "    'ассасин крид'='assassins creed'; 'ассасин 2'='assassins creed 2';" ^
  "    'ассасин 4'='assassins creed 4'; 'ассасин блэк флаг'='assassins creed black flag';" ^
  "    'ассасин вальгалла'='assassins creed valhalla'; 'вальгалла'='assassins creed valhalla';" ^
  "    'ассасин ориджинс'='assassins creed origins'; 'ориджинс'='assassins creed origins';" ^
  "    'ассасин одессей'='assassins creed odyssey'; 'одессей'='assassins creed odyssey';" ^
  "    'ассасин мираж'='assassins creed mirage'; 'миража'='assassins creed mirage';" ^
  "    'фар край 3'='far cry 3'; 'фар край 4'='far cry 4'; 'фар край 5'='far cry 5';" ^
  "    'фар край 6'='far cry 6'; 'примал'='far cry primal'; 'фар край нью давн'='far cry new dawn';" ^
  "    'дивижн'='the division'; 'дивижн 2'='the division 2'; 'рэйнбоу сикс'='rainbow six';" ^
  "    'р6'='rainbow six siege'; 'рэйнбоу сикс сидж'='rainbow six siege';" ^
  "    'принс оф персия'='prince of persia'; 'принц персии'='prince of persia';" ^
  "    'сплинтер селл'='splinter cell'; 'сплинтер'='splinter cell';" ^
  "    'варч'='watch dogs'; 'вотч догс'='watch dogs'; 'вотч догс 2'='watch dogs 2';" ^
  "    'вотч догс лиджн'='watch dogs legion'; 'легион'='watch dogs legion';" ^
  "    'фор хонор'='for honor'; 'гоуст рикон'='ghost recon'; 'гоуст рекон'='ghost recon';" ^
  "    'тхе крю'='the crew'; 'трекмания'='trackmania'; 'райман'='rayman';" ^
  "    'колда мв2'='call of duty mw2'; 'мв2'='call of duty mw2';" ^
  "    'мв3'='call of duty mw3'; 'варзона'='call of duty warzone'; 'варзоне'='call of duty warzone';" ^
  "    'код'='call of duty'; 'батла'='battlefield'; 'батлфилд 1'='battlefield 1';" ^
  "    'батлфилд 4'='battlefield 4'; 'батлфилд 2042'='battlefield 2042'; 'бф4'='battlefield 4';" ^
  "    'апекс'='apex legends'; 'апекс легендс'='apex legends'; 'титанфолл'='titanfall';" ^
  "    'титанфолл 2'='titanfall 2'; 'дестини'='destiny'; 'дестини 2'='destiny 2';" ^
  "    'овервотч'='overwatch'; 'овервоч'='overwatch'; 'оверватч'='overwatch'; 'ов'='overwatch';" ^
  "    'ов 2'='overwatch 2'; 'овервотч 2'='overwatch 2'; 'паладинс'='paladins';" ^
  "    'валорант'='valorant'; 'кске'='cs2'; 'кс 2'='cs2';" ^
  "    'кс го'='csgo'; 'ксго'='csgo'; 'контра'='counter-strike'; 'контер страйк'='counter-strike';" ^
  "    'р6с'='rainbow six siege'; 'хитмен'='hitman'; 'хитман 3'='hitman 3';" ^
  "    'фифа 24'='fc 24'; 'фифа 23'='fifa 23'; 'фифа 22'='fifa 22'; 'фифа 21'='fifa 21';" ^
  "    'фк 24'='fc 24'; 'фк 25'='fc 25'; 'еа фк 25'='fc 25'; 'нхл'='nhl'; 'нба'='nba 2k';" ^
  "    'нба 2к'='nba 2k'; 'мадден'='madden'; 'уефа'='uefa'; 'ф1'='f1'; 'ф1 24'='f1 24';" ^
  "    'скайфолл'='skyfall'; 'нид фор спид'='need for speed'; 'нфс'='need for speed';" ^
  "    'нид фор спид мост вантед'='need for speed most wanted'; 'мост вантед'='need for speed most wanted';" ^
  "    'нид фор спид хит'='need for speed heat'; 'хит нфс'='need for speed heat';" ^
  "    'анбаунд'='need for speed unbound'; 'нфс анбаунд'='need for speed unbound';" ^
  "    'биошок'='bioshock'; 'биошок 2'='bioshock 2'; 'биошок инфинити'='bioshock infinite';" ^
  "    'бордерлендс'='borderlands'; 'бордерлендс 2'='borderlands 2'; 'бордерлендс 3'='borderlands 3';" ^
  "    'блур'='borderlands'; 'сивилизейшн'='civilization'; 'цива'='civilization';" ^
  "    'цивилизация'='civilization'; 'цив 6'='civilization 6'; 'цива 6'='civilization 6';" ^
  "    'ксеком'='xcom'; 'ксеном'='xcom'; 'ксеном 2'='xcom 2'; 'мафия дефинитив'='mafia definitive edition';" ^
  "    'персона'='persona'; 'персона 5'='persona 5'; 'персона 4'='persona 4'; 'персона 3'='persona 3';" ^
  "    'персона 5 роял'='persona 5 royal'; 'п5р'='persona 5 royal'; 'п5'='persona 5';" ^
  "    'соул хакерс'='soul hackers'; 'шх2'='soul hackers 2'; 'метафор'='metaphor refantazio';" ^
  "    'метафора'='metaphor refantazio'; 'катсураги'='catherine'; 'кетрин'='catherine';" ^
  "    'ярн'='yakuza'; 'якудза'='yakuza'; 'якудза 0'='yakuza 0'; 'якудза лайк э драгон'='yakuza like a dragon';" ^
  "    'лайк э драгон'='yakuza like a dragon'; 'джаджмент'='judgment'; 'лондон'='yakuza';" ^
  "    'соник'='sonic'; 'соник фронтьерс'='sonic frontiers';" ^
  "    'тотал вар'='total war'; 'тотал вор'='total war'; 'тотал вар вархаммер'='total war warhammer';" ^
  "    'тв вархаммер'='total war warhammer'; 'футбал менеджер'='football manager'; 'фм'='football manager';" ^
  "    'зельда'='zelda'; 'зельда ботв'='zelda breath of the wild'; 'ботв'='zelda breath of the wild';" ^
  "    'тотк'='zelda tears of the kingdom'; 'тиарс оф зе киндом'='zelda tears of the kingdom';" ^
  "    'марио карт'='mario kart'; 'марио карт 8'='mario kart 8'; 'марио оддиси'='mario odyssey';" ^
  "    'супер марио'='super mario'; 'супер марио брос'='super mario bros'; 'смб'='super mario bros';" ^
  "    'покемон'='pokemon'; 'покемоны'='pokemon'; 'покемон го'='pokemon go';" ^
  "    'свитч'='switch'; 'ниндтендо'='nintendo'; 'нинтендо'='nintendo'; 'свич'='switch';" ^
  "    'сплэтун'='splatoon'; 'сплатун'='splatoon'; 'метроид'='metroid'; 'метроид дред'='metroid dread';" ^
  "    'кирби'='kirby'; 'донки конг'='donkey kong'; 'энимал кроссинг'='animal crossing';" ^
  "    'анимал кроссинг'='animal crossing'; 'энимал кросинг'='animal crossing';" ^
  "    'анчартед'='uncharted'; 'анчартед 4'='uncharted 4'; 'анчартед 2'='uncharted 2';" ^
  "    'анч'='uncharted'; 'бог войны 2018'='god of war 2018'; 'год оф вар рагнарок'='god of war ragnarok';" ^
  "    'рагнарек'='god of war ragnarok'; 'рагнарок'='god of war ragnarok';" ^
  "    'год оф вар 3'='god of war 3'; 'год 3'='god of war 3';" ^
  "    'хорайзон зеро давн'='horizon zero dawn'; 'хорайзон 2'='horizon forbidden west';" ^
  "    'запретный запад'='horizon forbidden west'; 'хорайзон форбидден вест'='horizon forbidden west';" ^
  "    'ласт оф ас 2'='last of us 2'; 'ласт оф ас парт 2'='last of us part 2'; 'лоу 2'='last of us 2';" ^
  "    'ласт оф ас 1'='last of us part 1'; 'ласт оф ас ремейк'='last of us part 1';" ^
  "    'гоуст оф цушима'='ghost of tsushima'; 'гоуст'='ghost of tsushima'; 'цусима'='ghost of tsushima';" ^
  "    'гоуст оф цусима'='ghost of tsushima'; 'спайдермен'='spider-man'; 'спайдер мен'='spider-man';" ^
  "    'человек паук 2'='spider-man 2'; 'спайдермен 2'='spider-man 2'; 'человек-паук 2'='spider-man 2';" ^
  "    'майлз моралес'='spider-man miles morales'; 'майлз'='spider-man miles morales';" ^
  "    'ратчет и кланк'='ratchet and clank'; 'ратчет'='ratchet and clank';" ^
  "    'бладборн 2'='bloodborne 2'; 'ретурнал'='returnal'; 'демонс соулс'='demons souls';" ^
  "    'демон соулс'='demons souls'; 'сайлент хилл'='silent hill'; 'сайлент хилл 2'='silent hill 2';" ^
  "    'дес стрендинг'='death stranding'; 'дес стрендинг 2'='death stranding 2'; 'дс2'='death stranding 2';" ^
  "    'дэйс ган'='days gone'; 'дейс ган'='days gone'; 'инфэмос'='infamous'; 'инфамос'='infamous';" ^
  "    'киллзоун'='killzone'; 'гран туризмо'='gran turismo'; 'гт'='gran turismo'; 'гт7'='gran turismo 7';" ^
  "    'резидент ивел'='resident evil'; 'резидент ивел 2'='resident evil 2'; 'ре2'='resident evil 2';" ^
  "    'резидент ивел 4'='resident evil 4'; 'ре4'='resident evil 4'; 'резидент 4'='resident evil 4';" ^
  "    'резидент ивел 7'='resident evil 7'; 'ре7'='resident evil 7'; 'резидент 7'='resident evil 7';" ^
  "    'резидент ивел вилладж'='resident evil village'; 'вилладж'='resident evil village';" ^
  "    'ре3'='resident evil 3'; 'резидент ивел 3'='resident evil 3'; 'резидент 3'='resident evil 3';" ^
  "    'девил мэй край'='devil may cry'; 'дмс'='devil may cry'; 'дмк'='devil may cry';" ^
  "    'девил мей край 5'='devil may cry 5'; 'дмк 5'='devil may cry 5'; 'дмс 5'='devil may cry 5';" ^
  "    'монстер хантер'='monster hunter'; 'мх'='monster hunter'; 'монстер хантер ворлд'='monster hunter world';" ^
  "    'мх ворлд'='monster hunter world'; 'монстер хантер райз'='monster hunter rise'; 'мх райз'='monster hunter rise';" ^
  "    'монстер хантер вайлдс'='monster hunter wilds'; 'мх вайлдс'='monster hunter wilds';" ^
  "    'драгонс догма'='dragons dogma'; 'драгон догма 2'='dragons dogma 2'; 'дд2'='dragons dogma 2';" ^
  "    'онимьюша'='onimusha'; 'онемуша'='onimusha'; 'асура'='asuras wrath';" ^
  "    'стрит файтер'='street fighter'; 'сф'='street fighter'; 'стрит файтер 6'='street fighter 6';" ^
  "    'стф 6'='street fighter 6'; 'теккен'='tekken'; 'теккен 8'='tekken 8'; 'т8'='tekken 8';" ^
  "    'соулкалибур'='soulcalibur'; 'соул калибур'='soulcalibur'; 'мортал комбат'='mortal kombat';" ^
  "    'мк'='mortal kombat'; 'мк1'='mortal kombat 1'; 'мк 11'='mortal kombat 11'; 'мортал 11'='mortal kombat 11';" ^
  "    'мортал комбат 1'='mortal kombat 1'; 'инджастис'='injustice'; 'инджастис 2'='injustice 2';" ^
  "    'финал фэнтези'='final fantasy'; 'фф'='final fantasy'; 'финалка'='final fantasy';" ^
  "    'фф7'='final fantasy 7'; 'финал фэнтези 7'='final fantasy 7'; 'фф7 ремейк'='final fantasy 7 remake';" ^
  "    'фф7 ребёрс'='final fantasy 7 rebirth'; 'фф16'='final fantasy 16'; 'финал фэнтези 16'='final fantasy 16';" ^
  "    'фф14'='final fantasy 14'; 'фф15'='final fantasy 15'; 'фф10'='final fantasy 10';" ^
  "    'кингдом хартс'='kingdom hearts'; 'кх'='kingdom hearts'; 'кингдом хартс 3'='kingdom hearts 3';" ^
  "    'драгон квест'='dragon quest'; 'дк'='dragon quest'; 'драгон квест 11'='dragon quest 11';" ^
  "    'ниер'='nier'; 'ниер автомата'='nier automata'; 'нир автомата'='nier automata';" ^
  "    'ниер репликант'='nier replicant'; 'нир репликант'='nier replikant';" ^
  "    'драгон квест билдерс'='dragon quest builders'; 'октопат'='octopath traveler';" ^
  "    'октопат 2'='octopath traveler 2'; 'триангл'='triangle strategy'; 'бравелли'='bravely default';" ^
  "    'паразит ив'='parasite eve'; 'кронос'='chrono trigger'; 'хроно'='chrono trigger';" ^
  "    'дарк соулс ремастер'='dark souls remastered'; 'дср'='dark souls remastered';" ^
  "    'элден ринг шэдоу'='elden ring shadow of the erdtree'; 'эрдтри'='elden ring shadow of the erdtree';" ^
  "    'арморд кор 6'='armored core 6'; 'ас6'='armored core 6';" ^
  "    'теккен 7'='tekken 7'; 'т7'='tekken 7'; 'соул калибур 6'='soulcalibur 6'; 'ск6'='soulcalibur 6';" ^
  "    'наруто'='naruto'; 'наруто шиппуден'='naruto shippuden'; 'наруто ултимейт'='naruto ultimate ninja storm';" ^
  "    'ултимейт ниндзя шторм'='naruto ultimate ninja storm'; 'ултимейт ниндзя сторм'='naruto ultimate ninja storm';" ^
  "    'джамп форс'='jump force'; 'дрэгон бол'='dragon ball'; 'дрэгон болл'='dragon ball';" ^
  "    'драгон бол'='dragon ball'; 'драгонбол'='dragon ball'; 'дбз'='dragon ball z';" ^
  "    'драгон болл з'='dragon ball z'; 'какарот'='dragon ball z kakarot';" ^
  "    'драгон болл файтерз'='dragon ball fighterz'; 'дбфз'='dragon ball fighterz';" ^
  "    'ван пис'='one piece'; 'уан пис'='one piece'; 'уанпис'='one piece';" ^
  "    'соник 2'='sonic 2'; 'соник адвенчер'='sonic adventure'; 'соник мэния'='sonic mania';" ^
  "    'соник суперстарз'='sonic superstars'; 'соник и сотс'='sonic and the secret rings';" ^
  "    'якудза 6'='yakuza 6'; 'якудза 7'='yakuza 7'; 'якудза кивами'='yakuza kiwami';" ^
  "    'якудза кивами 2'='yakuza kiwami 2'; 'исчин'='yakuza ishin';" ^
  "    'лост джаджмент'='lost judgment'; 'like a dragon gaiden'='like a dragon gaiden';" ^
  "    'лайк э драгон гайден'='like a dragon gaiden'; 'лайк э драгон инфинит'='like a dragon infinite wealth';" ^
  "    'сталкрафт 2'='starcraft 2'; 'ст2'='starcraft 2'; 'старкрафт 2'='starcraft 2';" ^
  "    'варкрафт 3'='warcraft 3'; 'вк3'='warcraft 3'; 'варкрафт 2'='warcraft 2';" ^
  "    'ворлд оф варкрафт'='world of warcraft'; 'вов'='world of warcraft'; 'вов классик'='wow classic';" ^
  "    'диабло'='diablo'; 'диабло 2'='diablo 2'; 'диабло 3'='diablo 3'; 'диабло 4'='diablo 4'; 'д3'='diablo 3';" ^
  "    'д4'='diablo 4'; 'диабло 2 резурректед'='diablo 2 resurrected'; 'д2р'='diablo 2 resurrected';" ^
  "    'овервотч классик'='overwatch classic'; 'пат оф экзайл'='path of exile'; 'поэ'='path of exile';" ^
  "    'поэ 2'='path of exile 2'; 'пат оф экзайл 2'='path of exile 2'; 'грим давн'='grim dawn';" ^
  "    'титан квест'='titan quest'; 'титан квест 2'='titan quest 2'; 'торчлайт'='torchlight';" ^
  "    'аге оф эмпайрс'='age of empires'; 'аое'='age of empires'; 'аге оф эмпайрс 2'='age of empires 2';" ^
  "    'аое 2'='age of empires 2'; 'аге оф эмпайрс 4'='age of empires 4'; 'аое 4'='age of empires 4';" ^
  "    'комманд энд конкер'='command and conquer'; 'кнк'='command and conquer'; 'ред алерт'='red alert';" ^
  "    'ред алерт 2'='red alert 2'; 'ра2'='red alert 2'; 'тиберриум'='tiberium';" ^
  "    'анно'='anno'; 'anno 1800'='anno 1800'; 'анно 1800'='anno 1800'; 'анно 2070'='anno 2070';" ^
  "    'ситис скаяйнс'='cities skylines'; 'сити скаяйнс'='cities skylines'; 'ситис 2'='cities skylines 2';" ^
  "    'симс'='the sims'; 'симс 4'='the sims 4'; 'симс 5'='the sims 5'; 'симс 3'='the sims 3';" ^
  "    'планет костер'='planet coaster'; 'планет коустер'='planet coaster'; 'планет зоо'='planet zoo';" ^
  "    'фростпанк'='frostpunk'; 'фростпанк 2'='frostpunk 2'; 'тропико'='tropico'; 'тропико 6'='tropico 6';" ^
  "    'сурвайвинг марс'='surviving mars'; 'сурвайвинг'='surviving mars';" ^
  "    'энной'='anno'; 'факторио'='factorio'; 'факторио 2'='factorio 2'; 'сатисфактори'='satisfactory';" ^
  "    'рифтворлд'='riftworld'; 'валхейм'='valheim'; 'валхейм 2'='valheim 2';" ^
  "    'раст'='rust'; 'раст 2'='rust 2'; 'арк'='ark survival evolved'; 'арк сурвайвал'='ark survival evolved';" ^
  "    'арк 2'='ark 2'; 'палворлд'='palworld'; 'пал ворлд'='palworld'; 'эншраудед'='enshrouded';" ^
  "    'дед бай дейлайт'='dead by daylight'; 'дбд'='dead by daylight'; 'дед бай'='dead by daylight';" ^
  "    'фрайдей 13'='friday the 13th'; 'фрайдэй'='friday the 13th'; 'лефт фор дед'='left 4 dead';" ^
  "    'л4д'='left 4 dead'; 'лефт фор дед 2'='left 4 dead 2'; 'л4д2'='left 4 dead 2';" ^
  "    'бэк 4 блад'='back 4 blood'; 'бэк фор блад'='back 4 blood'; 'б4б'='back 4 blood';" ^
  "    'верминтайд'='vermintide'; 'верминтайд 2'='vermintide 2'; 'дарктайд'='darktide';" ^
  "    'дип рок'='deep rock galactic'; 'дрг'='deep rock galactic'; 'хеллдайверс'='helldivers';" ^
  "    'хеллдайверс 2'='helldivers 2'; 'хд2'='helldivers 2'; 'хеллдавэрс'='helldivers';" ^
  "    'гта онлайн'='gta online'; 'гтао'='gta online'; 'рдр онлайн'='red dead online'; 'рдо'='red dead online';" ^
  "    'зе форест'='the forest'; 'сонс оф зе форест'='sons of the forest';" ^
  "    'соны фореста'='sons of the forest'; 'грин хелл'='green hell'; 'гринхелл'='green hell';" ^
  "    'сабнавтика'='subnautica'; 'сабнотика'='subnautica'; 'сабнавтика 2'='subnautica 2';" ^
  "    'сабнавтика бз'='subnautica below zero'; 'белоу зиро'='subnautica below zero';" ^
  "    'ноу мэнс скай'='no mans sky'; 'номанс скай'='no mans sky'; 'номанскай'='no mans sky';" ^
  "    'стардев вэлли'='stardew valley'; 'стардью'='stardew valley'; 'стардью вэлли'='stardew valley';" ^
  "    'анимал кроссинг нью хорайзонс'='animal crossing new horizons'; 'аснх'='animal crossing new horizons';" ^
  "    'гравити фоллс'='gravity falls'; 'гравити'='gravity falls'; 'хадес'='hades'; 'хадес 2'='hades 2';" ^
  "    'дед селс'='dead cells'; 'дед селлс'='dead cells'; 'скул'='skul'; 'скул зе хироу'='skul the hero slayer';" ^
  "    'инскрипшн'='inscryption'; 'инскрипшен'='inscryption'; 'слэй зе спайр'='slay the spire';" ^
  "    'слэй'='slay the spire'; 'балатро'='balatro'; 'вампир сурвайворс'='vampire survivors';" ^
  "    'вампир сурвайвор'='vampire survivors'; 'бротато'='brotato';" ^
  "    'майнкрафт 2'='minecraft 2'; 'майнкрафт данженс'='minecraft dungeons'; 'майн данженс'='minecraft dungeons';" ^
  "    'майнкрафт легендс'='minecraft legends'; 'майн легендс'='minecraft legends';" ^
  "    'роблокс'='roblox'; 'роблокс 2'='roblox 2'; 'роблокс студио'='roblox studio';" ^
  "    'фортнайт'='fortnite'; 'форточка'='fortnite'; 'фортнайт 2'='fortnite 2';" ^
  "    'апекс легенд'='apex legends'; 'колда варзона'='call of duty warzone'" ^
  "}" ^
  "$qLower = $q.ToLower()" ^
  "$altQuery = $synonyms[$qLower]" ^
  "$queries = @($q)" ^
  "if ($altQuery) { $queries += $altQuery }" ^
  "$lines = [IO.File]::ReadAllLines($File, [Text.Encoding]::UTF8)" ^
  "$found = 0; $games = ''; $login = ''; $pass = ''; $match = $false" ^
  "function Format-Games($gamesLine, $queryList) {" ^
  "    $gamesText = $gamesLine -replace '^.*Игры:\s*', ''" ^
  "    $games = $gamesText -split ',\s*'" ^
  "    $total = $games.Count" ^
  "    $matched = @()" ^
  "    foreach ($qq in $queryList) { $matched += @($games | Where-Object { $_ -match [regex]::Escape($qq) }) }" ^
  "    $matched = @($matched | Select-Object -Unique)" ^
  "    if ($total -le 3) { return ($games -join ', ') }" ^
  "    if ($matched.Count -ge 1) {" ^
  "        $shown = $matched[0..([Math]::Min($matched.Count-1, 2))]" ^
  "        $rest = $total - $shown.Count" ^
  "        if ($rest -gt 0) { return (($shown -join ', ') + '  +' + $rest + ' игр') } else { return ($shown -join ', ') }" ^
  "    } else {" ^
  "        $shown = $games[0..2]" ^
  "        return (($shown -join ', ') + '  +' + ($total - 3) + ' игр')" ^
  "    }" ^
  "}" ^
  "foreach ($line in $lines) {" ^
  "    if ($line -match '^🎮') {" ^
  "        $games = $line; $login = ''; $pass = ''; $match = $false" ^
  "        foreach ($qq in $queries) { if ($line -match [regex]::Escape($qq)) { $match = $true; break } }" ^
  "    }" ^
  "    elseif ($line -match '^👤') { $login = $line }" ^
  "    elseif ($line -match '^🔒') { $pass = $line }" ^
  "    elseif ($line.Trim() -eq '') {" ^
  "        if ($match) {" ^
  "            Write-Host ('  🎮 ' + (Format-Games $games $queries)) -ForegroundColor Yellow" ^
  "            Write-Host ('     ' + ($login -replace '^👤\s*Логин:\s*','Логин: ')) -ForegroundColor Green" ^
  "            Write-Host ('     ' + ($pass -replace '^🔒\s*Пароль:\s*','Пароль: ')) -ForegroundColor DarkGray" ^
  "            Write-Host ''" ^
  "            $found++; $match = $false" ^
  "        }" ^
  "    }" ^
  "}" ^
  "if ($match) {" ^
  "    Write-Host ('  🎮 ' + (Format-Games $games $queries)) -ForegroundColor Yellow" ^
  "    Write-Host ('     ' + ($login -replace '^👤\s*Логин:\s*','Логин: ')) -ForegroundColor Green" ^
  "    Write-Host ('     ' + ($pass -replace '^🔒\s*Пароль:\s*','Пароль: ')) -ForegroundColor DarkGray" ^
  "    Write-Host ''" ^
  "    $found++" ^
  "}" ^
  "Write-Host ('  ──────────────────────────────────────────') -ForegroundColor DarkGray" ^
  "if ($found -eq 0) {" ^
  "    Write-Host ('  Ничего не найдено.') -ForegroundColor Red" ^
  "    if ($altQuery) { Write-Host ('  (искали также: ' + $altQuery + ')') -ForegroundColor DarkGray }" ^
  "} else {" ^
  "    Write-Host ('  Найдено: ' + $found) -ForegroundColor Cyan" ^
  "    if ($altQuery) { Write-Host ('  (искали также: ' + $altQuery + ')') -ForegroundColor DarkGray }" ^
  "}" ^
  "'@" ^
  "[IO.File]::WriteAllText('%PS1_FILE%', $ps, [Text.Encoding]::UTF8)"

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1_FILE%" -Query "%QUERY%" -File "%ACCS_FILE%"

del /q "%PS1_FILE%" 2>nul

echo.
pause
cls
goto :search
