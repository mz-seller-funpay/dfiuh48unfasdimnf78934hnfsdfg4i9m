#!/usr/bin/env bash

CURRENT_VERSION="1.0.1"
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
        cp "$0" "$0.bak"
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
        "сталкер") echo "stalker" ;;
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
    read -r _ || break
done
