#!/usr/bin/env bash

CURRENT_VERSION="1.1.0"
RAW_URL="https://raw.githubusercontent.com/mz-seller-funpay/dfiuh48unfasdimnf78934hnfsdfg4i9m/refs/heads/main/cse4uymth98e7yehx97e4x90gs%2Cdrlhng580w7"
VERSION_URL="https://raw.githubusercontent.com/mz-seller-funpay/dfiuh48unfasdimnf78934hnfsdfg4i9m/refs/heads/main/dUHBIy7bversiond4fonewui"
SCRIPT_URL="https://raw.githubusercontent.com/mz-seller-funpay/dfiuh48unfasdimnf78934hnfsdfg4i9m/refs/heads/main/sjdddassdlSCRIPTSlsdunh298ndsaaa/linux.sh"

DATA_FILE="$(mktemp)"
trap 'rm -f "$DATA_FILE"' EXIT

YELLOW='\033[33m'
GREEN='\033[32m'
GRAY='\033[90m'
CYAN='\033[96m'
RED='\033[91m'
RESET='\033[0m'

if ! command -v curl >/dev/null 2>&1; then
    echo "Ошибка: не найден curl."
    exit 1
fi

clear_screen() {
    clear 2>/dev/null || printf '\033[2J\033[H'
}

check_for_updates() {
    local remote_version
    remote_version=$(curl -fsSL --max-time 10 "$VERSION_URL" 2>/dev/null | tr -d '[:space:]')
    [ -z "$remote_version" ] && return
    [ "$remote_version" = "$CURRENT_VERSION" ] && return

    echo ""
    echo "  Доступна новая версия: $remote_version (у вас $CURRENT_VERSION)"
    printf "  Обновить скрипт? (y/n): "
    read -r choice
    if [ "$choice" != "y" ] && [ "$choice" != "Y" ]; then
        echo "  Пропускаем обновление."
        return
    fi

    echo "  Скачиваем новую версию..."
    local tmp_file
    tmp_file=$(mktemp)
    if curl -fsSL --max-time 30 "$SCRIPT_URL" -o "$tmp_file" 2>/dev/null; then
        if ! grep -q "RAW_URL" "$tmp_file" 2>/dev/null; then
            rm -f "$tmp_file"
            echo "  [!] Скачанный файл не похож на скрипт. Обновление отменено."
            return
        fi
        mv "$tmp_file" "$0"
        chmod +x "$0"
        echo "  Скрипт обновлён! Перезапускаем..."
        sleep 1
        exec "$0"
    else
        rm -f "$tmp_file"
        echo "  [!] Не удалось скачать обновление."
    fi
}

show_header() {
    echo ""
    echo "  ┌─────────────────────────────────────────┐"
    echo "  │   ПОИСК АККАУНТОВ STEAM                 │"
    printf "  │   автор: \033]8;;https://funpay.com/users/12871901/\033\\\\MisterZidez\033]8;;\033\\\\"
    printf "                    │\n"
    printf "  │   версия: %-30s│\n" "$CURRENT_VERSION"
    echo "  └─────────────────────────────────────────┘"
    echo ""
}

get_synonym() {
    case "$1" in
        "ведьмак") echo "witcher" ;;
        "паук") echo "spider" ;;
        "гта"|"gta") echo "grand theft auto" ;;
        "ведьмак 3") echo "witcher 3" ;;
        "скайрим") echo "skyrim" ;;
        "дум") echo "doom" ;;
        "мортал") echo "mortal kombat" ;;
        "резидент"|"обитель") echo "resident evil" ;;
        "томб райдер") echo "tomb raider" ;;
        "дайинг") echo "dying light" ;;
        "киберпанк") echo "cyberpunk" ;;
        "хогвартс") echo "hogwarts" ;;
        "бог войны"|"год оф вар") echo "god of war" ;;
        "человек паук") echo "spider-man" ;;
        "последний из нас"|"ласт оф ас") echo "last of us" ;;
        "мафия") echo "mafia" ;;
        "душа") echo "souls" ;;
        "елден"|"элден"|"кольцо") echo "elden ring" ;;
        "сталкер") echo "S.T.A.L.K.E.R" ;;
        "метро") echo "metro" ;;
        "фоллаут"|"фаллаут") echo "fallout" ;;
        "ассасин") echo "assassin" ;;
        "крид") echo "creed" ;;
        "фар край"|"фаркрай") echo "far cry" ;;
        "батлфилд") echo "battlefield" ;;
        "колда"|"кол оф дьюти") echo "call of duty" ;;
        "фифа") echo "fc" ;;
        "фифа 25"|"еа фк") echo "fc 25" ;;
        "форза") echo "forza" ;;
        "хорайзон") echo "horizon" ;;
        "зелда") echo "zelda" ;;
        "марио") echo "mario" ;;
        "сонс оф форест") echo "sons of the forest" ;;
        "форест"|"лес") echo "the forest" ;;
        "рафт") echo "raft" ;;
        "портал") echo "portal" ;;
        "майнкрафт") echo "minecraft" ;;
        "террария") echo "terraria" ;;
        "тетрис") echo "tetris" ;;
        "варкрафт") echo "warcraft" ;;
        "старкрафт") echo "starcraft" ;;
        "ведьмак дикая охота") echo "witcher 3 wild hunt" ;;
        "киберпанк 2077") echo "cyberpunk 2077" ;;
        "данганронпа"|"данга") echo "danganronpa" ;;
        "данганронпа 2") echo "danganronpa 2" ;;
        "данганронпа v3"|"данганронпа 3") echo "danganronpa v3" ;;
        "ведьмак 2") echo "witcher 2" ;;
        "ведьмак 1") echo "witcher" ;;
        "ведьмак 3 дикая охота") echo "witcher 3 wild hunt" ;;
        "гвинт") echo "gwent" ;;
        "киберпанк 2") echo "cyberpunk 2" ;;
        "ведьмак 4") echo "witcher 4" ;;
        "дарк соулс"|"дарк соулз"|"дс") echo "dark souls" ;;
        "дарк соулс 3"|"дс3") echo "dark souls 3" ;;
        "дарк соулс 2") echo "dark souls 2" ;;
        "секиро"|"секиро тени умирают дважды") echo "sekiro" ;;
        "бладборн"|"блудборн") echo "bloodborne" ;;
        "армор кор"|"арморд кор") echo "armored core" ;;
        "армор кор 6"|"арморд кор 6"|"ас6"|"аc6") echo "armored core 6" ;;
        "нио") echo "nioh" ;;
        "нио 2") echo "nioh 2" ;;
        "лайс оф пи") echo "lies of p" ;;
        "лордс оф зе фоллен") echo "lords of the fallen" ;;
        "гта 5"|"гта5"|"gta 5") echo "gta 5" ;;
        "гта 6"|"gta 6") echo "gta 6" ;;
        "гта 4") echo "gta 4" ;;
        "гта сан"|"сан андреас") echo "gta san andreas" ;;
        "рдр") echo "red dead redemption" ;;
        "рдр 2"|"ред дед 2") echo "red dead redemption 2" ;;
        "ред дед") echo "red dead redemption" ;;
        "мафия 2") echo "mafia 2" ;;
        "мафия 3") echo "mafia 3" ;;
        "мафия 1"|"мафия дефинитив") echo "mafia definitive edition" ;;
        "буллы") echo "bully" ;;
        "ла нойр") echo "l.a. noire" ;;
        "обливион") echo "oblivion" ;;
        "морровинд") echo "morrowind" ;;
        "фоллаут 4") echo "fallout 4" ;;
        "фоллаут 3") echo "fallout 3" ;;
        "фоллаут 76") echo "fallout 76" ;;
        "фоллаут нью вегас"|"нью вегас") echo "fallout new vegas" ;;
        "старфилд") echo "starfield" ;;
        "дум 2016") echo "doom 2016" ;;
        "дум этернал") echo "doom eternal" ;;
        "дум 3") echo "doom 3" ;;
        "квикс") echo "quake" ;;
        "вольфенштейн") echo "wolfenstein" ;;
        "ассасин крид") echo "assassin's creed" ;;
        "ассасин 2") echo "assassin's creed 2" ;;
        "ассасин 4"|"ассасин блэк флаг") echo "assassin's creed black flag" ;;
        "ассасин вальгалла"|"вальгалла") echo "assassin's creed valhalla" ;;
        "ассасин ориджинс"|"ориджинс") echo "assassin's creed origins" ;;
        "ассасин одессей"|"одессей") echo "assassin's creed odyssey" ;;
        "ассасин мираж"|"миража") echo "assassin's creed mirage" ;;
        "фар край 3") echo "far cry 3" ;;
        "фар край 4") echo "far cry 4" ;;
        "фар край 5") echo "far cry 5" ;;
        "фар край 6") echo "far cry 6" ;;
        "примал") echo "far cry primal" ;;
        "фар край нью давн") echo "far cry new dawn" ;;
        "дивижн") echo "the division" ;;
        "дивижн 2") echo "the division 2" ;;
        "рэйнбоу сикс"|"р6"|"р6с"|"рэйнбоу сикс сидж") echo "rainbow six siege" ;;
        "принс оф персия"|"принц персии") echo "prince of persia" ;;
        "сплинтер селл"|"сплинтер") echo "splinter cell" ;;
        "варч"|"вотч догс") echo "watch dogs" ;;
        "вотч догс 2") echo "watch dogs 2" ;;
        "вотч догс лиджн"|"легион") echo "watch dogs legion" ;;
        "фор хонор") echo "for honor" ;;
        "гоуст рикон"|"гоуст рекон") echo "ghost recon" ;;
        "тхе крю") echo "the crew" ;;
        "трекмания") echo "trackmania" ;;
        "райман") echo "rayman" ;;
        "колда мв2"|"мв2") echo "call of duty mw2" ;;
        "мв3") echo "call of duty mw3" ;;
        "варзона"|"варзоне"|"колда варзона") echo "call of duty warzone" ;;
        "код") echo "call of duty" ;;
        "батла") echo "battlefield" ;;
        "батлфилд 1") echo "battlefield 1" ;;
        "батлфилд 4"|"бф4") echo "battlefield 4" ;;
        "батлфилд 2042") echo "battlefield 2042" ;;
        "апекс"|"апекс легендс"|"апекс легенд") echo "apex legends" ;;
        "титанфолл") echo "titanfall" ;;
        "титанфолл 2") echo "titanfall 2" ;;
        "дестини") echo "destiny" ;;
        "дестини 2") echo "destiny 2" ;;
        "овервотч"|"овервоч"|"оверватч"|"ов"|"овервотч классик") echo "overwatch" ;;
        "ов 2"|"овервотч 2") echo "overwatch 2" ;;
        "паладинс") echo "paladins" ;;
        "валорaнт"|"валорант") echo "valorant" ;;
        "кске"|"кс 2") echo "cs2" ;;
        "кс го"|"ксго") echo "csgo" ;;
        "контра"|"контер страйк") echo "counter-strike" ;;
        "хитмен") echo "hitman" ;;
        "хитман 3") echo "hitman 3" ;;
        "фифа 24"|"фк 24") echo "fc 24" ;;
        "фифа 23") echo "fifa 23" ;;
        "фифа 22") echo "fifa 22" ;;
        "фифа 21") echo "fifa 21" ;;
        "фк 25"|"еа фк 25") echo "fc 25" ;;
        "нхл") echo "nhl" ;;
        "нба"|"нба 2к") echo "nba 2k" ;;
        "мадден") echo "madden" ;;
        "уефа") echo "uefa" ;;
        "ф1") echo "f1" ;;
        "ф1 24") echo "f1 24" ;;
        "скайфолл") echo "skyfall" ;;
        "нид фор спид"|"нфс") echo "need for speed" ;;
        "нид фор спид мост вантед"|"мост вантед") echo "need for speed most wanted" ;;
        "нид фор спид хит"|"хит нфс") echo "need for speed heat" ;;
        "анбаунд"|"нфс анбаунд") echo "need for speed unbound" ;;
        "биошок") echo "bioshock" ;;
        "биошок 2") echo "bioshock 2" ;;
        "биошок инфинити") echo "bioshock infinite" ;;
        "бордерлендс"|"блур") echo "borderlands" ;;
        "бордерлендс 2") echo "borderlands 2" ;;
        "бордерлендс 3") echo "borderlands 3" ;;
        "сивилизейшн"|"цива"|"цивилизация") echo "civilization" ;;
        "цив 6"|"цива 6") echo "civilization 6" ;;
        "ксеком"|"ксеном") echo "xcom" ;;
        "ксеном 2") echo "xcom 2" ;;
        "персона") echo "persona" ;;
        "персона 5"|"п5") echo "persona 5" ;;
        "персона 4") echo "persona 4" ;;
        "персона 3") echo "persona 3" ;;
        "персона 5 роял"|"п5р") echo "persona 5 royal" ;;
        "соул хакерс") echo "soul hackers" ;;
        "шх2") echo "soul hackers 2" ;;
        "метафор"|"метафора") echo "metaphor refantazio" ;;
        "катсураги"|"кетрин") echo "catherine" ;;
        "ярн"|"якудза") echo "yakuza" ;;
        "якудза 0") echo "yakuza 0" ;;
        "якудза лайк э драгон"|"лайк э драгон") echo "yakuza like a dragon" ;;
        "джаджмент") echo "judgment" ;;
        "лондон") echo "yakuza" ;;
        "сонік"|"соник") echo "sonic" ;;
        "соник фронтьерс") echo "sonic frontiers" ;;
        "тотал вар"|"тотал вор") echo "total war" ;;
        "тотал вар вархаммер"|"тв вархаммер") echo "total war warhammer" ;;
        "футбал менеджер"|"фм") echo "football manager" ;;
        "зельда ботв"|"ботв") echo "zelda breath of the wild" ;;
        "тотк"|"тиарс оф зе киндом") echo "zelda tears of the kingdom" ;;
        "марио карт") echo "mario kart" ;;
        "марио карт 8") echo "mario kart 8" ;;
        "марио оддиси") echo "mario odyssey" ;;
        "супер марио") echo "super mario" ;;
        "супер марио брос"|"смб") echo "super mario bros" ;;
        "покемон"|"покемоны") echo "pokemon" ;;
        "покемон го") echo "pokemon go" ;;
        "покемон ск��рлет") echo "pokemon scarlet" ;;
        "покемон вайолет") echo "pokemon violet" ;;
        "свитч"|"свич") echo "switch" ;;
        "ниндтендо"|"нинтендо") echo "nintendo" ;;
        "сплэтун"|"сплатун") echo "splatoon" ;;
        "метроид") echo "metroid" ;;
        "метроид дред") echo "metroid dread" ;;
        "кирби") echo "kirby" ;;
        "донки конг") echo "donkey kong" ;;
        "энимал кроссинг"|"анимал кроссинг"|"энимал кросинг"|"аnimal") echo "animal crossing" ;;
        "анимал кроссинг нью хорайзонс"|"аснх") echo "animal crossing new horizons" ;;
        "анчартед"|"анч") echo "uncharted" ;;
        "анчартед 4") echo "uncharted 4" ;;
        "анчартед 2") echo "uncharted 2" ;;
        "бог войны 2018") echo "god of war 2018" ;;
        "год оф вар рагнарок"|"рагнарек"|"рагнарок") echo "god of war ragnarok" ;;
        "год оф вар 3"|"год 3") echo "god of war 3" ;;
        "хорайзон зеро давн") echo "horizon zero dawn" ;;
        "хорайзон 2"|"запретный запад"|"хорайзон форбидден вест") echo "horizon forbidden west" ;;
        "ласт оф ас 2"|"ласт оф ас парт 2"|"лоу 2") echo "last of us 2" ;;
        "ласт оф ас 1"|"ласт оф ас ремейк") echo "last of us part 1" ;;
        "гоуст оф цушима"|"гоуст"|"цусима"|"гоуст оф цусима") echo "ghost of tsushima" ;;
        "спайдермен"|"спайдер мен") echo "spider-man" ;;
        "человек паук 2"|"спайдермен 2"|"человек-паук 2") echo "spider-man 2" ;;
        "майлз моралес"|"майлз") echo "spider-man miles morales" ;;
        "ратчет и кланк"|"ратчет") echo "ratchet and clank" ;;
        "бладборн 2") echo "bloodborne 2" ;;
        "ретурнал") echo "returnal" ;;
        "демонс соулс"|"демон соулс") echo "demon's souls" ;;
        "сайлент хилл") echo "silent hill" ;;
        "сайлент хилл 2") echo "silent hill 2" ;;
        "дес стрендинг") echo "death stranding" ;;
        "дес стрендинг 2"|"дс2") echo "death stranding 2" ;;
        "дэйс ган"|"дейс ган") echo "days gone" ;;
        "инфэмос"|"инфамос") echo "infamous" ;;
        "киллзоун") echo "killzone" ;;
        "гран туризмо"|"гт") echo "gran turismo" ;;
        "гт7") echo "gran turismo 7" ;;
        "резидент ивел") echo "resident evil" ;;
        "резидент ивел 2"|"ре2") echo "resident evil 2" ;;
        "резидент ивел 4"|"ре4"|"резидент 4") echo "resident evil 4" ;;
        "резидент ивел 7"|"ре7"|"резидент 7") echo "resident evil 7" ;;
        "резидент ивел вилладж"|"вилладж"|"ре вилладж") echo "resident evil village" ;;
        "ре3"|"резидент ивел 3"|"резидент 3") echo "resident evil 3" ;;
        "девил мэй край"|"дмс"|"дмк") echo "devil may cry" ;;
        "девил мей край 5"|"дмк 5"|"дмс 5") echo "devil may cry 5" ;;
        "монстер хантер"|"мх") echo "monster hunter" ;;
        "монстер хантер ворлд"|"мх ворлд") echo "monster hunter world" ;;
        "монстер хантер райз"|"мх райз") echo "monster hunter rise" ;;
        "монстер хантер вайлдс"|"мх вайлдс") echo "monster hunter wilds" ;;
        "драгонс догма") echo "dragon's dogma" ;;
        "драгон догма 2"|"дд2") echo "dragon's dogma 2" ;;
        "онимьюша"|"онемуша") echo "onimusha" ;;
        "асура") echo "asura's wrath" ;;
        "стрит файтер"|"сф") echo "street fighter" ;;
        "стрит файтер 6"|"стф 6") echo "street fighter 6" ;;
        "теккен") echo "tekken" ;;
        "теккен 8"|"т8") echo "tekken 8" ;;
        "соулкалибур"|"соул калибур") echo "soulcalibur" ;;
        "мк"|"мортал комбат") echo "mortal kombat" ;;
        "мк1"|"мортал комбат 1") echo "mortal kombat 1" ;;
        "мк 11"|"мортал 11") echo "mortal kombat 11" ;;
        "инджастис") echo "injustice" ;;
        "инджастис 2") echo "injustice 2" ;;
        "финал фэнтези"|"фф"|"финалка") echo "final fantasy" ;;
        "фф7"|"финал фэнтези 7") echo "final fantasy 7" ;;
        "фф7 ремейк") echo "final fantasy 7 remake" ;;
        "фф7 ребёрс") echo "final fantasy 7 rebirth" ;;
        "фф16"|"финал фэнтези 16") echo "final fantasy 16" ;;
        "фф14") echo "final fantasy 14" ;;
        "фф15") echo "final fantasy 15" ;;
        "фф10") echo "final fantasy 10" ;;
        "кингдом хартс"|"кх") echo "kingdom hearts" ;;
        "кингдом хартс 3") echo "kingdom hearts 3" ;;
        "драгон квест") echo "dragon quest" ;;
        "драгон квест 11") echo "dragon quest 11" ;;
        "ниер") echo "nier" ;;
        "ниер автомата"|"нир автомата") echo "nier automata" ;;
        "ниер репликант"|"нир репликант") echo "nier replicant" ;;
        "драгон квест билдерс") echo "dragon quest builders" ;;
        "октопат") echo "octopath traveler" ;;
        "октопат 2") echo "octopath traveler 2" ;;
        "триангл") echo "triangle strategy" ;;
        "бравелли") echo "bravely default" ;;
        "паразит ив") echo "parasite eve" ;;
        "кронос"|"хроно") echo "chrono trigger" ;;
        "наруто") echo "naruto" ;;
        "наруто шиппуден") echo "naruto shippuden" ;;
        "наруто ултимейт"|"ултимейт ниндзя шторм"|"ултимейт ниндзя сторм") echo "naruto ultimate ninja storm" ;;
        "джамп форс") echo "jump force" ;;
        "дрэгон бол"|"дрэгон болл"|"драгон бол"|"драгонбол") echo "dragon ball" ;;
        "дбз"|"драгон болл з") echo "dragon ball z" ;;
        "какарот") echo "dragon ball z kakarot" ;;
        "драгон болл файтерз"|"дбфз") echo "dragon ball fighterz" ;;
        "ван пис"|"уан пис"|"уанпис") echo "one piece" ;;
        "соник 2") echo "sonic 2" ;;
        "соник адвенчер") echo "sonic adventure" ;;
        "соник мэния") echo "sonic mania" ;;
        "соник суперстарз") echo "sonic superstars" ;;
        "соник и сотс") echo "sonic and the secret rings" ;;
        "якудза 6") echo "yakuza 6" ;;
        "якудза 7") echo "yakuza 7" ;;
        "якудза кивами") echo "yakuza kiwami" ;;
        "якудза кивами 2") echo "yakuza kiwami 2" ;;
        "исчин") echo "yakuza ishin" ;;
        "лост джаджмент") echo "lost judgment" ;;
        "like a dragon gaiden"|"лайк э драгон гайден") echo "like a dragon gaiden" ;;
        "лайк э драгон инфинит") echo "like a dragon infinite wealth" ;;
        "сталкрафт 2"|"ст2"|"старкрафт 2") echo "starcraft 2" ;;
        "варкрафт 3"|"вк3") echo "warcraft 3" ;;
        "варкрафт 2") echo "warcraft 2" ;;
        "ворлд оф варкрафт"|"вов") echo "world of warcraft" ;;
        "вов классик") echo "wow classic" ;;
        "диабло") echo "diablo" ;;
        "диабло 2") echo "diablo 2" ;;
        "диабло 3"|"д3") echo "diablo 3" ;;
        "диабло 4"|"д4") echo "diablo 4" ;;
        "диабло 2 резурректед"|"д2р") echo "diablo 2 resurrected" ;;
        "пат оф экзайл"|"поэ") echo "path of exile" ;;
        "поэ 2"|"пат оф экзайл 2") echo "path of exile 2" ;;
        "грим давн") echo "grim dawn" ;;
        "титан квест") echo "titan quest" ;;
        "титан квест 2") echo "titan quest 2" ;;
        "торчлайт") echo "torchlight" ;;
        "аге оф эмпайрс"|"аое") echo "age of empires" ;;
        "аге оф эмпайрс 2"|"аое 2") echo "age of empires 2" ;;
        "аге оф эмпайрс 4"|"аое 4") echo "age of empires 4" ;;
        "комманд энд конкер"|"кнк") echo "command and conquer" ;;
        "ред алерт") echo "red alert" ;;
        "ред алерт 2"|"ра2") echo "red alert 2" ;;
        "тиберриум") echo "tiberium" ;;
        "анно") echo "anno" ;;
        "anno 1800"|"анно 1800") echo "anno 1800" ;;
        "анно 2070") echo "anno 2070" ;;
        "ситис скаяйнс"|"сити скаяйнс") echo "cities skylines" ;;
        "ситис 2") echo "cities skylines 2" ;;
        "симс") echo "the sims" ;;
        "симс 4") echo "the sims 4" ;;
        "симс 5") echo "the sims 5" ;;
        "симс 3") echo "the sims 3" ;;
        "планет костер"|"планет коустер") echo "planet coaster" ;;
        "планет зоо") echo "planet zoo" ;;
        "фростпанк") echo "frostpunk" ;;
        "фростпанк 2") echo "frostpunk 2" ;;
        "тропико") echo "tropico" ;;
        "тропико 6") echo "tropico 6" ;;
        "сурвайвинг марс"|"сурвайвинг") echo "surviving mars" ;;
        "энной") echo "anno" ;;
        "факторио") echo "factorio" ;;
        "факторио 2") echo "factorio 2" ;;
        "сатисфактори") echo "satisfactory" ;;
        "рифтвorld"|"рифтворлд") echo "riftworld" ;;
        "валхейм") echo "valheim" ;;
        "валхейм 2") echo "valheim 2" ;;
        "раст") echo "rust" ;;
        "раст 2") echo "rust 2" ;;
        "арк"|"арк сурвайвал") echo "ark survival evolved" ;;
        "арк 2") echo "ark 2" ;;
        "палворлд"|"пал ворлд") echo "palworld" ;;
        "эншраудед") echo "enshrouded" ;;
        "дед бай дейлайт"|"дбд"|"дед бай") echo "dead by daylight" ;;
        "фрайдей 13"|"фрайдэй") echo "friday the 13th" ;;
        "лефт фор дед"|"л4д") echo "left 4 dead" ;;
        "лефт фор дед 2"|"л4д2") echo "left 4 dead 2" ;;
        "бэк 4 блад"|"бэк фор блад"|"б4б") echo "back 4 blood" ;;
        "верминтайд") echo "vermintide" ;;
        "верминтайд 2") echo "vermintide 2" ;;
        "дарктайд") echo "darktide" ;;
        "дип рок"|"дрг") echo "deep rock galactic" ;;
        "хеллдайверс"|"хеллдавэрс") echo "helldivers" ;;
        "хеллдайверс 2"|"хд2") echo "helldivers 2" ;;
        "гта онлайн"|"гтао") echo "gta online" ;;
        "рдр онлайн"|"рдо") echo "red dead online" ;;
        "зе форест") echo "the forest" ;;
        "сонс оф зе форест"|"соны фореста") echo "sons of the forest" ;;
        "грин хелл"|"гринхелл") echo "green hell" ;;
        "сабнавтика"|"сабнотика") echo "subnautica" ;;
        "сабнавтика 2") echo "subnautica 2" ;;
        "сабнавтика бз"|"белоу зиро") echo "subnautica below zero" ;;
        "ноу мэнс скай"|"номанс скай"|"номанскай") echo "no man's sky" ;;
        "стардев вэлли"|"стардью"|"стардью вэлли") echo "stardew valley" ;;
        "гравити фоллс"|"гравити") echo "gravity falls" ;;
        "хадес") echo "hades" ;;
        "хадес 2") echo "hades 2" ;;
        "дед селс"|"дед селлс") echo "dead cells" ;;
        "скул"|"скул зе хироу") echo "skul the hero slayer" ;;
        "инскрипшн"|"инскрипшен") echo "inscryption" ;;
        "слэй зе спайр"|"слэй") echo "slay the spire" ;;
        "балатро") echo "balatro" ;;
        "вампир сурвайворс"|"вампир сурвайвор") echo "vampire survivors" ;;
        "бротато") echo "brotato" ;;
        "майнкрафт 2") echo "minecraft 2" ;;
        "майнкрафт данженс"|"майн данженс") echo "minecraft dungeons" ;;
        "майнкрафт легендс"|"майн легендс") echo "minecraft legends" ;;
        "роблокс") echo "roblox" ;;
        "роблокс 2") echo "roblox 2" ;;
        "роблокс студио") echo "roblox studio" ;;
        "фортнайт"|"форточка") echo "fortnite" ;;
        "фортнайт 2") echo "fortnite 2" ;;
        *) echo "" ;;
    esac
}

format_games() {
    local games_line="$1"
    local query="$2"
    local alt="$3"

    local games_text="${games_line#🎮 Игры: }"
    local total
    total=$(echo "$games_text" | awk -F',' '{print NF}')

    if [ "$total" -le 3 ]; then
        echo "$games_text"
        return
    fi

    local matched=""
    local IFS=','
    for g in $games_text; do
        g=$(echo "$g" | sed 's/^ *//;s/ *$//')
        if echo "$g" | grep -qiF "$query" || { [ -n "$alt" ] && echo "$g" | grep -qiF "$alt"; }; then
            matched="$matched,$g"
        fi
    done
    unset IFS
    matched="${matched#,}"

    if [ -n "$matched" ]; then
        local shown
        shown=$(echo "$matched" | awk -F',' '{for(i=1;i<=3 && i<=NF;i++) printf "%s%s", (i>1?", ":""), $i}')
        local shown_count
        shown_count=$(echo "$matched" | awk -F',' '{print (NF<3?NF:3)}')
        local rest=$((total - shown_count))
        if [ "$rest" -gt 0 ]; then
            echo "$shown  +$rest игр"
        else
            echo "$shown"
        fi
    else
        local shown
        shown=$(echo "$games_text" | awk -F',' '{for(i=1;i<=3 && i<=NF;i++) printf "%s%s", (i>1?", ":""), $i}')
        echo "$shown  +$((total - 3)) игр"
    fi
}

search_in_file() {
    local query="$1"
    local alt="$2"

    local found=0
    local games="" login="" password="" match=0

    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in
            🎮*)
                games="$line"
                login=""
                password=""
                match=0
                if echo "$line" | grep -qiF "$query"; then
                    match=1
                elif [ -n "$alt" ] && echo "$line" | grep -qiF "$alt"; then
                    match=1
                fi
                ;;
            👤*)
                login="$line"
                ;;
            🔒*)
                password="$line"
                ;;
            "")
                if [ "$match" -eq 1 ]; then
                    echo -e "  ${YELLOW}🎮 $(format_games "$games" "$query" "$alt")${RESET}"
                    local login_clean="${login#👤 Логин: }"
                    local pass_clean="${password#🔒 Пароль: }"
                    echo -e "     ${GREEN}Логин: ${login_clean}${RESET}"
                    echo -e "     ${GRAY}Пароль: ${pass_clean}${RESET}"
                    echo ""
                    found=$((found + 1))
                    match=0
                fi
                ;;
        esac
    done < "$DATA_FILE"

    if [ "$match" -eq 1 ]; then
        echo -e "  ${YELLOW}🎮 $(format_games "$games" "$query" "$alt")${RESET}"
        local login_clean="${login#👤 Логин: }"
        local pass_clean="${password#🔒 Пароль: }"
        echo -e "     ${GREEN}Логин: ${login_clean}${RESET}"
        echo -e "     ${GRAY}Пароль: ${pass_clean}${RESET}"
        echo ""
        found=$((found + 1))
    fi

    echo -e "  ${GRAY}──────────────────────────────────────────${RESET}"
    if [ "$found" -eq 0 ]; then
        echo -e "  ${RED}Ничего не найдено.${RESET}"
    else
        echo -e "  ${CYAN}Найдено: ${found}${RESET}"
    fi
    if [ -n "$alt" ]; then
        echo -e "  ${GRAY}(искали также: ${alt})${RESET}"
    fi
}

clear_screen
echo ""
echo "  Проверка обновлений..."
check_for_updates

clear_screen
echo ""
echo "  Загрузка списка аккаунтов..."
echo ""

B64=$(curl -fsSL --max-time 30 "$RAW_URL" 2>/dev/null)
if [ -z "$B64" ]; then
    echo "  [!] Не удалось скачать файл."
    exit 1
fi

B64=$(printf '%s' "$B64" | tr -d '[:space:]')
printf '%s' "$B64" | base64 -d > "$DATA_FILE" 2>/dev/null

if ! grep -q "Логин:" "$DATA_FILE" 2>/dev/null; then
    echo "  [!] Файл повреждён или не похож на список аккаунтов."
    exit 1
fi

echo "  Готово."
sleep 1

while true; do
    clear_screen
    show_header
    printf "  Введите игру: "
    read -r QUERY || break
    if [ -z "$QUERY" ]; then
        continue
    fi

    ALT=$(get_synonym "$(echo "$QUERY" | tr '[:upper:]' '[:lower:]')")

    clear_screen
    echo ""
    echo "  Поиск: $QUERY"
    echo "  ──────────────────────────────────────────"
    echo ""

    search_in_file "$QUERY" "$ALT"

    echo ""
    printf "  Нажмите Enter для нового поиска..."
done
    read -r _ || break
