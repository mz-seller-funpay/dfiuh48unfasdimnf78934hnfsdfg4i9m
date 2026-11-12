#!/usr/bin/env bash
# Поиск аккаунтов Steam — by MisterZidez
# Python-порт (linux) v1.5.2

set -uo pipefail

CURRENT_VERSION="1.5.2"
RAW_URL="https://raw.githubusercontent.com/mz-seller-funpay/dfiuh48unfasdimnf78934hnfsdfg4i9m/refs/heads/main/cse4uymth98e7yehx97e4x90gs%2Cdrlhng580w7"
VERSION_URL="https://raw.githubusercontent.com/mz-seller-funpay/dfiuh48unfasdimnf78934hnfsdfg4i9m/refs/heads/main/dUHBIy7bversiond4fonewui"
SCRIPT_URL="https://raw.githubusercontent.com/mz-seller-funpay/dfiuh48unfasdimnf78934hnfsdfg4i9m/refs/heads/main/sjdddassdlSCRIPTSlsdunh298ndsaaa/linux.sh"
SYNONYMS_URL="https://raw.githubusercontent.com/mz-seller-funpay/dfiuh48unfasdimnf78934hnfsdfg4i9m/refs/heads/main/1345synnom3gd435ndfhZDFony5464mGGs"

USER_AGENT="steam-search/${CURRENT_VERSION}"
HTTP_RETRIES=3
CACHE_TTL_SECONDS=3600
DEFAULT_LIMIT=50
MIN_ALT_LEN=2
SHORT_QUERY_WORDBOUND=1

M_GAMES="🎮"
M_LOGIN="👤"
M_PASS="🔒"
PREFIX_GAMES="${M_GAMES} Игры: "
PREFIX_LOGIN="${M_LOGIN} Логин: "
PREFIX_PASS="${M_PASS} Пароль: "

DATA_FILE="$(mktemp -t steam_accs.XXXXXX)"
SYN_FILE="$(mktemp -t steam_syn.XXXXXX)"
trap 'rm -f "$DATA_FILE" "$SYN_FILE"' EXIT

CACHE_ACCS="${TMPDIR:-/tmp}/.steam_accs_cache.txt"
CACHE_SYN="${TMPDIR:-/tmp}/.steam_synonyms_cache.json"
CONFIG_PATH="${HOME}/.steam_search_config.json"

# Флаги (значения по умолчанию)
OPT_QUERY=""
OPT_NO_UPDATE=0
OPT_UPDATE_NOW=0
OPT_CHECK_UPDATE=0
OPT_FORCE=0
OPT_INTERACTIVE=0
OPT_NO_CACHE=0
OPT_NO_CACHE_ACCS=0
OPT_SAVE=""
OPT_SAVE_MODE="a"
OPT_EXPORT="txt"
OPT_CSV_HEADER=0
OPT_CSV_DELIMITER=","
OPT_LIMIT="$DEFAULT_LIMIT"
OPT_ALL=0
OPT_MIN_GAMES=0
OPT_FULL_GAMES=0
OPT_STATS=0
OPT_STATS_TOP=10
OPT_BY="games"
OPT_NO_COLOR=0
OPT_CONFIG=""
OPT_SAVE_CONFIG=0
OPT_UNSET_CONFIG=()
OPT_DRY_RUN=0
OPT_LOG=""
OPT_DEBUG=0

COLOR=1
[ -t 1 ] || COLOR=0

if [ "$COLOR" = "1" ]; then
    YELLOW=$'\033[33m'; GREEN=$'\033[32m'; GRAY=$'\033[90m'
    CYAN=$'\033[96m'; RED=$'\033[91m'; RESET=$'\033[0m'
else
    YELLOW=""; GREEN=""; GRAY=""; CYAN=""; RED=""; RESET=""
fi

# ──────────────────────────────────────────────────────────────────────────────
# Утилиты
# ──────────────────────────────────────────────────────────────────────────────

dbg() {
    [ "$OPT_DEBUG" = "1" ] && echo "[debug] $*" >&2
}

die() {
    echo "  [!] $*" >&2
    exit 1
}

clear_screen() {
    [ -t 1 ] && clear 2>/dev/null
}

# HTTP GET с ретраями и ETag-кэшем (ETag хранится в памяти процесса)
declare -A ETAG_CACHE=()
declare -A ETAG_DATA=()

http_get() {
    local url="$1" timeout="${2:-30}" use_etag="${3:-0}"
    local headers=(-H "User-Agent: ${USER_AGENT}")
    if [ "$use_etag" = "1" ] && [ -n "${ETAG_CACHE[$url]:-}" ]; then
        headers+=(-H "If-None-Match: ${ETAG_CACHE[$url]}")
    fi

    local attempt=1 out status
    while [ "$attempt" -le "$HTTP_RETRIES" ]; do
        out=$(curl -sS -w '\n%{http_code}' --max-time "$timeout" "${headers[@]}" "$url" 2>/dev/null) || {
            dbg "http_get attempt $attempt failed (curl)"
            attempt=$((attempt + 1))
            sleep "$attempt"
            continue
        }
        status=$(echo "$out" | tail -n1)
        body=$(echo "$out" | sed '$d')

        if [ "$status" = "304" ] && [ "$use_etag" = "1" ] && [ -n "${ETAG_DATA[$url]:-}" ]; then
            printf '%s' "${ETAG_DATA[$url]}"
            return 0
        fi
        if [ "$status" = "200" ]; then
            if [ "$use_etag" = "1" ]; then
                local etag
                etag=$(curl -sSI --max-time "$timeout" "$url" 2>/dev/null | tr -d '\r' | awk -F': ' 'tolower($1)=="etag"{print $2}')
                if [ -n "$etag" ]; then
                    ETAG_CACHE[$url]="$etag"
                    ETAG_DATA[$url]="$body"
                fi
            fi
            printf '%s' "$body"
            return 0
        fi
        if [ "${status:0:1}" = "4" ] && [ "$status" != "429" ]; then
            echo "HTTP $status: $url" >&2
            return 1
        fi
        dbg "http_get attempt $attempt: HTTP $status"
        attempt=$((attempt + 1))
        sleep "$attempt"
    done
    return 1
}

# Скрыть/показать файл (на Linux — просто точка в имени; но если нужен chattr)
hide_file() { :; }
unhide_file() { :; }

delete_cache() {
    local f="$1"
    [ -f "$f" ] && rm -f "$f" && dbg "cache deleted: $f"
}

cache_fresh() {
    local f="$1" ttl="$2"
    [ -f "$f" ] || return 1
    local now mtime age
    now=$(date +%s)
    mtime=$(stat -c %Y "$f" 2>/dev/null || echo 0)
    age=$((now - mtime))
    [ "$age" -le "$ttl" ]
}

normalize_space() {
    # сжимает пробелы
    sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//'
}

normalize_query() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | normalize_space
}

should_wordbound() {
    [ "$SHORT_QUERY_WORDBOUND" = "1" ] || return 1
    [ "${#1}" -lt 3 ]
}

# match(text, needle, wordbound) -> 0/1
match() {
    local text="$1" needle="$2" wordbound="$3"
    [ -z "$needle" ] && return 1
    local t n
    t=$(echo "$text" | tr '[:upper:]' '[:lower:]' | normalize_space)
    n=$(echo "$needle" | tr '[:upper:]' '[:lower:]' | normalize_space)
    if [ "$wordbound" = "1" ] && should_wordbound "$n"; then
        echo "$t" | grep -qE "(^|[^[:alnum:]_])${n//./\\.}([^[:alnum:]_]|$)"
    else
        [[ "$t" == *"$n"* ]]
    fi
}

strip_prefix() {
    local line="$1" prefix="$2"
    if [[ "$line" == "$prefix"* ]]; then
        echo "${line#$prefix}"
    else
        echo "$line"
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
# Конфиг
# ──────────────────────────────────────────────────────────────────────────────

read_config() {
    local path="$1"
    [ -f "$path" ] || return 0
    python3 - "$path" <<'PY' 2>/dev/null || true
import json, sys
try:
    d = json.load(open(sys.argv[1], encoding="utf-8"))
    if isinstance(d, dict):
        for k, v in d.items():
            print(f"{k}={v}")
except Exception:
    pass
PY
}

write_config() {
    local path="$1"; shift
    python3 - "$path" "$@" <<'PY'
import json, sys
path = sys.argv[1]
d = {}
try:
    d = json.load(open(path, encoding="utf-8"))
    if not isinstance(d, dict):
        d = {}
except Exception:
    d = {}
for kv in sys.argv[2:]:
    if "=" in kv:
        k, v = kv.split("=", 1)
        if v.lower() in ("true", "false"):
            d[k] = v.lower() == "true"
        elif v.isdigit():
            d[k] = int(v)
        else:
            d[k] = v
json.dump(d, open(path, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
PY
    echo "  Конфиг сохранён: $path"
}

cfg_bool() {
    local key="$1" default="$2"
    local v="${CONFIG[$key]:-}"
    [ -z "$v" ] && { echo "$default"; return; }
    case "${v,,}" in
        true|1) echo 1 ;;
        *)      echo 0 ;;
    esac
}

declare -A CONFIG=()

# ──────────────────────────────────────────────────────────────────────────────
# Обновление
# ──────────────────────────────────────────────────────────────────────────────

validate_script() {
    local f="$1"
    grep -q "CURRENT_VERSION" "$f" && grep -q "check_for_updates" "$f"
}

check_for_updates() {
    local force="$1"
    local remote
    remote=$(http_get "$VERSION_URL" 10 1 2>/dev/null | tr -d '[:space:]') || {
        echo "  [!] Не удалось проверить обновления."
        return
    }
    [ -z "$remote" ] && {
        echo "  [!] Сервер вернул пустую версию — пропускаем проверку."
        return
    }

    if [ "$remote" = "$CURRENT_VERSION" ] && [ "$force" != "1" ]; then
        echo "  У вас последняя версия ($CURRENT_VERSION)."
        return
    fi
    echo
    if [ "$remote" = "$CURRENT_VERSION" ]; then
        echo "  Версия не изменилась ($CURRENT_VERSION). Переустановить?"
    else
        echo "  Доступна версия: $remote (у вас $CURRENT_VERSION)"
    fi

    if [ "$force" != "1" ]; then
        printf "  Обновить скрипт? (y/n): "
        read -r choice || return
        [ "$choice" = "y" ] || [ "$choice" = "Y" ] || { echo "  Пропускаем обновление."; return; }
    fi

    echo "  Скачиваем новую версию..."
    local tmp
    tmp="$(mktemp -t .steam_upd.XXXXXX.sh)" || { echo "  [!] mktemp failed"; return; }
    if ! http_get "$SCRIPT_URL" 30 > "$tmp"; then
        rm -f "$tmp"
        echo "  [!] Не удалось скачать обновление."
        return
    fi
    if ! validate_script "$tmp"; then
        rm -f "$tmp"
        echo "  [!] Скачанный файл не похож на скрипт. Обновление отменено."
        return
    fi
    if mv -f "$tmp" "$0"; then
        chmod +x "$0" 2>/dev/null || true
        echo "  Обновление завершено. Закрываем скрипт."
        echo "  Запустите его снова, чтобы использовать новую версию."
        exit 0
    else
        rm -f "$tmp"
        echo "  [!] Не удалось заменить файл."
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
# Загрузка аккаунтов
# ──────────────────────────────────────────────────────────────────────────────

download_accounts() {
    local use_cache="$1" use_accs_cache="$2"
    local raw
    if raw=$(http_get "$RAW_URL" 30 1 2>/dev/null); then
        local b64 data
        b64=$(printf '%s' "$raw" | tr -d '[:space:]')
        if ! printf '%s' "$b64" | base64 -d > "$DATA_FILE" 2>/dev/null; then
            die "base64 decode failed"
        fi
        if ! grep -q "Логин:" "$DATA_FILE"; then
            die "файл повреждён или не похож на список аккаунтов"
        fi
        if ! grep -q "$M_GAMES" "$DATA_FILE"; then
            echo "  [!] Формат файла не совпадает с ожидаемым (нет 🎮)."
        fi
        NETWORK_OK=1
        if [ "$use_cache" = "1" ] && [ "$use_accs_cache" = "1" ]; then
            cp -f "$DATA_FILE" "$CACHE_ACCS" 2>/dev/null || true
        fi
        return 0
    fi

    if [ "$use_cache" = "1" ] && [ "$use_accs_cache" = "1" ] && cache_fresh "$CACHE_ACCS" "$CACHE_TTL_SECONDS"; then
        echo "  [!] Сеть недоступна. Используем кэш из TMPDIR."
        cp -f "$CACHE_ACCS" "$DATA_FILE"
        NETWORK_OK=0
        return 0
    fi
    die "Не удалось получить список аккаунтов"
}

# ──────────────────────────────────────────────────────────────────────────────
# Синонимы
# ──────────────────────────────────────────────────────────────────────────────

declare -A SYNONYMS=()
declare -A FALLBACK=(
    ["ведьмак"]="witcher" ["гта"]="grand theft auto" ["gta"]="grand theft auto"
    ["скайрим"]="skyrim" ["фоллаут"]="fallout" ["фаллаут"]="fallout"
    ["киберпанк"]="cyberpunk" ["дарк соулс"]="dark souls" ["дс"]="dark souls"
    ["елден"]="elden ring" ["элден"]="elden ring" ["резидент"]="resident evil"
    ["фифа"]="fc" ["кс"]="cs" ["кс2"]="cs2" ["ксго"]="csgo"
    ["дота"]="dota 2" ["майнкрафт"]="minecraft" ["роблокс"]="roblox"
    ["фортнайт"]="fortnite" ["апекс"]="apex legends"
)

parse_synonyms_file() {
    local file="$1"
    # Парсим через python3 (есть почти везде), иначе fallback
    if command -v python3 >/dev/null 2>&1; then
        python3 - "$file" <<'PY'
import json, sys
try:
    d = json.load(open(sys.argv[1], encoding="utf-8"))
    if not isinstance(d, dict): sys.exit(1)
    out = {}
    for k, v in d.items():
        if not isinstance(k, str): continue
        if isinstance(v, str):
            if len(v) >= 2:
                out[" ".join(k.strip().lower().split())] = v
        elif isinstance(v, list):
            parts = [str(x) for x in v if isinstance(x, str) and len(x) >= 2]
            if parts:
                out[" ".join(k.strip().lower().split())] = "|".join(parts)
    for k, v in out.items():
        print(f"{k}\t{v}")
except Exception:
    sys.exit(1)
PY
        return $?
    fi
    return 1
}

load_synonyms() {
    local use_cache="$1"
    # 1) рядом со скриптом
    local local_file
    local_file="$(dirname "$(readlink -f "$0" 2>/dev/null || echo "$0")")/synonyms.json"
    if [ -f "$local_file" ]; then
        local out
        if out=$(parse_synonyms_file "$local_file"); then
            while IFS=$'\t' read -r k v; do SYNONYMS["$k"]="$v"; done <<< "$out"
            dbg "synonyms loaded from $local_file: ${#SYNONYMS[@]}"
            return
        fi
    fi

    # 2) скачать
    if http_get "$SYNONYMS_URL" 20 1 > "$SYN_FILE" 2>/dev/null; then
        local out
        if out=$(parse_synonyms_file "$SYN_FILE"); then
            while IFS=$'\t' read -r k v; do SYNONYMS["$k"]="$v"; done <<< "$out"
            dbg "synonyms downloaded: ${#SYNONYMS[@]}"
            if [ "$use_cache" = "1" ]; then cp -f "$SYN_FILE" "$CACHE_SYN" 2>/dev/null || true; fi
            return
        fi
    fi

    # 3) кэш
    if [ "$use_cache" = "1" ] && cache_fresh "$CACHE_SYN" "$CACHE_TTL_SECONDS"; then
        local out
        if out=$(parse_synonyms_file "$CACHE_SYN"); then
            while IFS=$'\t' read -r k v; do SYNONYMS["$k"]="$v"; done <<< "$out"
            echo "  [!] Синонимы загружены из кэша (сеть недоступна)."
            return
        fi
    fi

    echo "  [!] synonyms.json недоступен — используется встроенный fallback."
    for k in "${!FALLBACK[@]}"; do SYNONYMS["$k"]="${FALLBACK[$k]}"; done
}

split_alt() {
    local alt="$1"
    local IFS='|'
    for a in $alt; do
        [ "${#a}" -ge "$MIN_ALT_LEN" ] && printf '%s\n' "$a"
    done
}

resolve_alt() {
    local term="$1"
    local syn="${SYNONYMS[$term]:-}"
    [ -z "$syn" ] && return
    split_alt "$syn"
}

# ──────────────────────────────────────────────────────────────────────────────
# Парсинг аккаунтов
# ──────────────────────────────────────────────────────────────────────────────

# Выводит записи в формате: games\tlogin\tpassword
parse_records() {
    awk -v mg="$M_GAMES" -v ml="$M_LOGIN" -v mp="$M_PASS" '
        function push() {
            if (games != "" && login != "") {
                g = games; sub(/^[^:]*: /, "", g)
                l = login; sub(/^[^:]*: /, "", l)
                p = password; sub(/^[^:]*: /, "", p)
                n = split(g, arr, ", ")
                printf "%s\t%s\t%s\t%d\n", g, l, p, n
            }
            games=""; login=""; password=""
        }
        {
            line=$0
            if (index(line, mg) == 1) { push(); games=line }
            else if (index(line, ml) == 1) { login=line }
            else if (index(line, mp) == 1) { password=line }
            else if (line == "") { push() }
        }
        END { push() }
    ' "$DATA_FILE"
}

games_of() {
    local games="$1"
    echo "$games" | awk -F', ' '{print NF}'
}

# ──────────────────────────────────────────────────────────────────────────────
# Запрос: , OR; + AND; - NOT
# ──────────────────────────────────────────────────────────────────────────────

# Глобальные переменные запроса
declare -a Q_GROUPS=()     # каждая группа — строка через \x1f (AND-термы)
declare -a Q_ALTS=()       # каждая группа — строка через \x1f
declare -a Q_EXCLUDES=()
declare -a Q_EXCLUDES_ALT=()

parse_query() {
    local raw="$1"
    Q_GROUPS=(); Q_ALTS=(); Q_EXCLUDES=(); Q_EXCLUDES_ALT=()

    local IFS=','
    for chunk in $raw; do
        chunk="$(echo "$chunk" | normalize_space)"
        [ -z "$chunk" ] && continue
        local -a terms=()
        local -a plus_terms=()
        local has_plus=0
        for tok in $chunk; do
            if [[ "$tok" == -* ]] && [ "${#tok}" -gt 1 ]; then
                local term
                term=$(normalize_query "${tok:1}")
                [ -n "$term" ] && {
                    Q_EXCLUDES+=("$term")
                    while IFS= read -r a; do Q_EXCLUDES_ALT+=("$a"); done < <(resolve_alt "$term")
                }
            elif [ "$tok" = "+" ]; then
                has_plus=1
            else
                terms+=("$tok")
            fi
        done
        [ "${#terms[@]}" -eq 0 ] && continue

        local norm_terms=()
        for t in "${terms[@]}"; do
            local nt
            nt=$(normalize_query "$t")
            [ -n "$nt" ] && norm_terms+=("$nt")
        done
        [ "${#norm_terms[@]}" -eq 0 ] && continue

        local joined_terms
        joined_terms=$(IFS=$'\x1f'; echo "${norm_terms[*]}")
        Q_GROUPS+=("$joined_terms")

        local alts_line=""
        for t in "${norm_terms[@]}"; do
            while IFS= read -r a; do
                [ -z "$a" ] && continue
                if [ -z "$alts_line" ]; then alts_line="$a"; else alts_line+=$'\x1f'"$a"; fi
            done < <(resolve_alt "$t")
        done
        Q_ALTS+=("$alts_line")
    done
}

query_is_empty() {
    [ "${#Q_GROUPS[@]}" -eq 0 ]
}

# _match_line(line, query) → 0/1
query_match_line() {
    local line="$1"
    local matched=0

    local i
    for ((i=0; i<${#Q_GROUPS[@]}; i++)); do
        local terms_str="${Q_GROUPS[$i]}"
        local alts_str="${Q_ALTS[$i]}"

        # AND по термам
        local all=1
        local IFS=$'\x1f'
        for t in $terms_str; do
            if ! match "$line" "$t" 1; then all=0; break; fi
        done
        unset IFS
        [ "$all" = "1" ] && { matched=1; break; }

        # AND по alt
        [ -n "$alts_str" ] && {
            local all_alts=1
            IFS=$'\x1f'
            for a in $alts_str; do
                if ! match "$line" "$a" 0; then all_alts=0; break; fi
            done
            unset IFS
            [ "$all_alts" = "1" ] && { matched=1; break; }
        }
    done
    [ "$matched" = "0" ] && return 1

    for ex in "${Q_EXCLUDES[@]}"; do
        match "$line" "$ex" 1 && return 1
    done
    for ex in "${Q_EXCLUDES_ALT[@]}"; do
        match "$line" "$ex" 0 && return 1
    done
    return 0
}

# ──────────────────────────────────────────────────────────────────────────────
# Вывод
# ──────────────────────────────────────────────────────────────────────────────

format_games() {
    local games="$1" full="$2"
    local total
    total=$(games_of "$games")
    [ "$total" -eq 0 ] && { echo ""; return; }
    if [ "$full" = "1" ] || [ "$total" -le 3 ]; then
        echo "$games"
        return
    fi

    local all_terms=()
    local i
    for ((i=0; i<${#Q_GROUPS[@]}; i++)); do
        IFS=$'\x1f'
        for t in ${Q_GROUPS[$i]}; do all_terms+=("$t"); done
        unset IFS
        IFS=$'\x1f'
        for a in ${Q_ALTS[$i]}; do all_terms+=("$a"); done
        unset IFS
    done

    local matched=()
    local IFS=','
    for g in $games; do
        g="$(echo "$g" | normalize_space)"
        [ -z "$g" ] && continue
        local hit=0
        for t in "${all_terms[@]}"; do
            if match "$g" "$t" 0; then hit=1; break; fi
        done
        if [ "$hit" = "1" ]; then
            # дедуп
            local seen=0
            for m in "${matched[@]:-}"; do [ "$m" = "$g" ] && { seen=1; break; }; done
            [ "$seen" = "0" ] && matched+=("$g")
        fi
    done
    unset IFS

    if [ "${#matched[@]}" -gt 0 ]; then
        local shown=("${matched[@]:0:3}")
        local rest=$((${#matched[@]} - ${#shown[@]}))
        local base
        base=$(IFS=', '; echo "${shown[*]}")
        if [ "$rest" -gt 0 ]; then
            echo "$base  +$rest совпадений"
        else
            echo "$base"
        fi
    else
        local shown
        shown=$(echo "$games" | awk -F', ' '{for(i=1;i<=3 && i<=NF;i++) printf "%s%s", (i>1?", ":""), $i}')
        echo "$shown  +$((total - 3)) игр"
    fi
}

format_account() {
    local games="$1" login="$2" password="$3" full="$4"
    local games_str
    games_str=$(format_games "$games" "$full")
    printf "  %s%s %s%s\n" "$YELLOW" "$M_GAMES" "$games_str" "$RESET"
    printf "     %sЛогин: %s%s\n" "$GREEN" "$login" "$RESET"
    printf "     %sПароль: %s%s\n" "$GRAY" "$password" "$RESET"
}

write_record() {
    local games="$1" login="$2" password="$3" full="$4"
    [ -z "$OPT_SAVE" ] && return
    case "$OPT_EXPORT" in
        csv)
            python3 - "$OPT_CSV_DELIMITER" "$login" "$password" "$games" "$(games_of "$games")" <<'PY' >> "$OPT_SAVE"
import sys, csv
w = csv.writer(sys.stdout, delimiter=sys.argv[1], lineterminator="\n")
w.writerow(sys.argv[2:6])
PY
            ;;
        jsonl)
            python3 - "$login" "$password" "$games" "$(games_of "$games")" <<'PY' >> "$OPT_SAVE"
import sys, json
print(json.dumps({"login": sys.argv[1], "password": sys.argv[2],
                  "games": sys.argv[3], "games_count": int(sys.argv[4])},
                 ensure_ascii=False))
PY
            ;;
        *)
            {
                format_games "$games" "$full"
                echo "  Логин: $login"
                echo "  Пароль: $password"
                echo
            } >> "$OPT_SAVE"
            ;;
    esac
}

open_save() {
    [ -z "$OPT_SAVE" ] && return 0
    local path="$OPT_SAVE"
    if [ "$path" = "$CACHE_ACCS" ] || [ "$path" = "$CACHE_SYN" ]; then
        die "--save указывает на файл кэша"
    fi
    mkdir -p "$(dirname "$path")" 2>/dev/null || true
    local is_empty=1
    [ -s "$path" ] && is_empty=0
    if [ "$OPT_SAVE_MODE" = "w" ] && [ "$is_empty" = "0" ]; then
        echo "  [!] --save-mode w перезапишет $path"
    fi
    : > "$path"  # создать/очистить, дозапись ниже
    if [ "$OPT_SAVE_MODE" = "a" ] && [ "$is_empty" = "0" ]; then
        : # оставляем как есть
    else
        # для w или пустого файла — обнулить
        if [ "$OPT_SAVE_MODE" = "w" ]; then : > "$path"; fi
    fi
    if [ "$OPT_EXPORT" = "csv" ] && [ "$OPT_CSV_HEADER" = "1" ] && [ "$is_empty" = "1" ]; then
        echo "login${OPT_CSV_DELIMITER}password${OPT_CSV_DELIMITER}games${OPT_CSV_DELIMITER}games_count" >> "$OPT_SAVE"
    fi
}

search_records() {
    local limit="$1" min_games="$2" full="$3"
    local found=0 shown=0 header_written=0

    while IFS=$'\t' read -r games login password games_count; do
        [ -z "$games" ] && continue
        [ "$games_count" -lt "$min_games" ] && continue
        local line="${PREFIX_GAMES}${games}"
        query_match_line "$line" || continue

        found=$((found + 1))
        if [ -n "$limit" ] && [ "$limit" -gt 0 ] && [ "$shown" -ge "$limit" ]; then
            continue
        fi

        if [ -n "$OPT_SAVE" ] && [ "$header_written" = "0" ]; then
            local flat=""
            local i
            for ((i=0; i<${#Q_GROUPS[@]}; i++)); do
                IFS=$'\x1f'
                for t in ${Q_GROUPS[$i]}; do
                    [ -z "$flat" ] && flat="$t" || flat+=", $t"
                done
                unset IFS
            done
            echo "" >> "$OPT_SAVE"
            echo "=== $(date '+%Y-%m-%d %H:%M:%S') | ${flat:--} ===" >> "$OPT_SAVE"
            header_written=1
        fi

        format_account "$games" "$login" "$password" "$full"
        write_record "$games" "$login" "$password" "$full"
        shown=$((shown + 1))
    done < <(parse_records)

    printf "  %s%s%s\n" "$GRAY" "──────────────────────────────────────────" "$RESET"
    if [ "$found" -eq 0 ]; then
        printf "  %sНичего не найдено.%s\n" "$RED" "$RESET"
    else
        local suffix=""
        if [ -n "$limit" ] && [ "$limit" -gt 0 ] && [ "$found" -gt "$shown" ]; then
            suffix="  (показано $shown, используйте --all или --limit N)"
        fi
        printf "  %sНайдено: %s%s%s\n" "$CYAN" "$found" "$suffix" "$RESET"
    fi
    [ "${#Q_EXCLUDES[@]}" -gt 0 ] && printf "  %sисключено: %s%s\n" "$GRAY" "$(IFS=', '; echo "${Q_EXCLUDES[*]}")" "$RESET"
}

stats_records() {
    local top="$1" min_games="$2"
    local total=0 no_games=0
    local games_count_dist=()
    declare -A counter=()
    declare -A display=()

    while IFS=$'\t' read -r games login password gc; do
        [ -z "$games" ] && continue
        [ "$gc" -lt "$min_games" ] && continue
        total=$((total + 1))
        [ "$gc" -eq 0 ] && no_games=$((no_games + 1))
        games_count_dist[$gc]=$(( ${games_count_dist[$gc]:-0} + 1 ))
        local IFS=','
        for g in $games; do
            g="$(echo "$g" | normalize_space)"
            [ -z "$g" ] && continue
            local key
            key=$(echo "$g" | tr '[:upper:]' '[:lower:]')
            counter[$key]=$(( ${counter[$key]:-0} + 1 ))
            [ -z "${display[$key]:-}" ] && display[$key]="$g"
        done
        unset IFS
    done < <(parse_records)

    printf "  Аккаунтов: %d\n" "$total"
    [ "$no_games" -gt 0 ] && printf "  Аккаунтов без игр: %d\n" "$no_games"
    printf "  Уникальных игр: %d\n\n" "${#counter[@]}"
    printf "  %sТоп-%d игр:%s\n" "$CYAN" "$top" "$RESET"
    for key in "${!counter[@]}"; do
        printf "%d\t%s\n" "${counter[$key]}" "${display[$key]}"
    done | sort -rn | head -n "$top" | while IFS=$'\t' read -r cnt name; do
        printf "    %s%5d%s  %s\n" "$GREEN" "$cnt" "$RESET" "$name"
    done
    echo
    printf "  %sРаспределение по числу игр:%s\n" "$CYAN" "$RESET"
    for n in "${!games_count_dist[@]}"; do
        printf "%d\t%d\n" "$n" "${games_count_dist[$n]}"
    done | sort -n | while IFS=$'\t' read -r n c; do
        printf "    %s%3d%s игр  —  %d акк.\n" "$GREEN" "$n" "$RESET" "$c"
    done
}

print_filter_info() {
    local min_games="$1"
    [ "$min_games" -le 0 ] && return
    local total=0 passed=0
    while IFS=$'\t' read -r games login password gc; do
        [ -z "$games" ] && continue
        total=$((total + 1))
        [ "$gc" -ge "$min_games" ] && passed=$((passed + 1))
    done < <(parse_records)
    printf "  Фильтр --min-games %d: %d из %d\n\n" "$min_games" "$passed" "$total"
}

# ──────────────────────────────────────────────────────────────────────────────
# Режимы
# ──────────────────────────────────────────────────────────────────────────────

run_search() {
    local raw="$1" limit="$2" min_games="$3" by="$4" full="$5"

    parse_query "$raw"
    if query_is_empty; then
        echo "  [!] Пустой запрос."
        return 0
    fi

    if [ "$by" != "games" ]; then
        [ "$by" = "password" ] && echo "  [!] --by password: результаты содержат пароли в открытом виде."
        local found=0 shown=0
        echo "  Поиск по $by: $raw"
        echo "  ──────────────────────────────────────────"
        echo
        while IFS=$'\t' read -r games login password gc; do
            [ -z "$games" ] && continue
            [ "$gc" -lt "$min_games" ] && continue
            local field="$login"
            [ "$by" = "password" ] && field="$password"
            query_match_line "$field" || continue
            found=$((found + 1))
            [ -n "$limit" ] && [ "$limit" -gt 0 ] && [ "$shown" -ge "$limit" ] && continue
            format_account "$games" "$login" "$password" "$full"
            write_record "$games" "$login" "$password" "$full"
            shown=$((shown + 1))
        done < <(parse_records)
        if [ "$found" -eq 0 ]; then
            printf "  %sНичего не найдено.%s\n" "$RED" "$RESET"
        else
            printf "  %sНайдено: %d%s\n" "$CYAN" "$found" "$RESET"
        fi
        return 0
    fi

    echo "  Поиск: $raw"
    [ "${#Q_EXCLUDES[@]}" -gt 0 ] && echo "  Исключено: $(IFS=', '; echo "${Q_EXCLUDES[*]}")"
    echo "  ──────────────────────────────────────────"
    echo
    print_filter_info "$min_games"
    search_records "$limit" "$min_games" "$full"
}

interactive_loop() {
    local limit="$1"
    while true; do
        clear_screen
        echo
        echo "  ┌─────────────────────────────────────────┐"
        echo "  │   ПОИСК АККАУНТОВ STEAM                 │"
        echo "  │   автор: MisterZidez                    │"
        printf "  │   версия: %-30s│\n" "$CURRENT_VERSION"
        echo "  └─────────────────────────────────────────┘"
        echo
        printf "  Игра (q — выход, s/статистика, h/помощь): "
        read -r query || { echo; return; }
        query="$(echo "$query" | normalize_space)"
        [ -z "$query" ] && continue
        local low="${query,,}"
        case "$low" in
            q|quit|exit|выход) return ;;
            s|stat|stats|статистика)
                clear_screen; echo
                stats_records "$OPT_STATS_TOP" "$OPT_MIN_GAMES"
                echo; printf "  Enter — назад... "; read -r _ || return
                continue ;;
            h|\?|help|помощь)
                clear_screen; echo
                echo "  Введите название игры."
                echo "  ',' — OR, '+' — AND, '-' — исключить."
                echo "  Пример: гта + ведьмак -кс"
                echo "  Синонимы подставляются автоматически (гта → grand theft auto)."
                echo "  q — выход, s — статистика, h — эта справка."
                echo; printf "  Enter — назад... "; read -r _ || return
                continue ;;
        esac

        clear_screen; echo
        run_search "$query" "$limit" "$OPT_MIN_GAMES" "$OPT_BY" "$OPT_FULL_GAMES"
        echo
        printf "  Enter — новый поиск, q — выход: "
        read -r nxt || { echo; return; }
        [ "${nxt,,}" = "q" ] && return
    done
}

# ──────────────────────────────────────────────────────────────────────────────
# CLI
# ──────────────────────────────────────────────────────────────────────────────

usage() {
    cat <<EOF
Поиск аккаунтов Steam — $CURRENT_VERSION

Использование:
  $0 [QUERY] [опции]

Основное:
  QUERY                    игра для поиска (без интерактива)
  -h, --help               эта справка
  --version                версия

Обновления:
  --no-update              не проверять обновления
  --update-now             обновить принудительно
  --check-update           проверить обновления, несмотря на конфиг

Режим:
  -i, --interactive        принудительно интерактив
  --dry-run                загрузить и показать статистику

Кэш:
  --no-cache               не использовать кэш
  --no-cache-accs          не кэшировать аккаунты

Поиск:
  --by {games,login,password}
  --min-games N            только аккаунты с >= N играми
  --full-games             показывать все игры
  --limit N                лимит (0 — без лимита)
  --all                    без лимита
  --force                  разрешить --by password + --save

Сохранение:
  --save FILE              сохранить результаты
  --save-mode {a,w}        режим (по умолчанию a)
  --export {txt,csv,jsonl} формат (по умолчанию txt)
  --csv-header             заголовок CSV для пустого файла
  --csv-delimiter CHAR     разделитель CSV

Статистика:
  --stats                  статистика и выход
  --stats-top N            топ-N (по умолчанию 10)

Оформление:
  --no-color               без ANSI

Конфиг:
  --config FILE            путь к конфигу
  --save-config            сохранить флаги
  --unset-config KEY       удалить ключ (можно несколько)

Отладка:
  --log FILE               лог в файл
  --debug                  debug в stderr
EOF
}

parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help) usage; exit 0 ;;
            --version) echo "$CURRENT_VERSION"; exit 0 ;;
            --no-update) OPT_NO_UPDATE=1 ;;
            --update-now) OPT_UPDATE_NOW=1 ;;
            --check-update) OPT_CHECK_UPDATE=1 ;;
            --force) OPT_FORCE=1 ;;
            -i|--interactive) OPT_INTERACTIVE=1 ;;
            --no-cache) OPT_NO_CACHE=1 ;;
            --no-cache-accs) OPT_NO_CACHE_ACCS=1 ;;
            --save) shift; OPT_SAVE="${1:-}" ;;
            --save-mode) shift; OPT_SAVE_MODE="${1:-a}" ;;
            --export) shift; OPT_EXPORT="${1:-txt}" ;;
            --csv-header) OPT_CSV_HEADER=1 ;;
            --csv-delimiter) shift; OPT_CSV_DELIMITER="${1:-,}" ;;
            --limit) shift; OPT_LIMIT="${1:-$DEFAULT_LIMIT}" ;;
            --all) OPT_ALL=1 ;;
            --min-games) shift; OPT_MIN_GAMES="${1:-0}" ;;
            --full-games) OPT_FULL_GAMES=1 ;;
            --stats) OPT_STATS=1 ;;
            --stats-top) shift; OPT_STATS_TOP="${1:-10}" ;;
            --by) shift; OPT_BY="${1:-games}" ;;
            --no-color) OPT_NO_COLOR=1 ;;
            --config) shift; OPT_CONFIG="${1:-}" ;;
            --save-config) OPT_SAVE_CONFIG=1 ;;
            --unset-config) shift; OPT_UNSET_CONFIG+=("${1:-}") ;;
            --dry-run) OPT_DRY_RUN=1 ;;
            --log) shift; OPT_LOG="${1:-}" ;;
            --debug) OPT_DEBUG=1 ;;
            --) shift; break ;;
            -*) echo "  [!] Неизвестный флаг: $1" >&2; exit 2 ;;
            *)  OPT_QUERY="$1" ;;
        esac
        shift
    done

    # Валидация
    [[ "$OPT_MIN_GAMES" =~ ^[0-9]+$ ]] || { echo "  [!] --min-games must be >= 0" >&2; exit 2; }
    [[ "$OPT_STATS_TOP" =~ ^[1-9][0-9]*$ ]] || { echo "  [!] --stats-top must be > 0" >&2; exit 2; }
    [[ "$OPT_LIMIT" =~ ^[0-9]+$ ]] || { echo "  [!] --limit must be >= 0" >&2; exit 2; }
    [ "$OPT_CSV_HEADER" = "1" ] && [ "$OPT_EXPORT" != "csv" ] && { echo "  [!] --csv-header requires --export csv" >&2; exit 2; }
    [ "$OPT_ALL" = "1" ] && OPT_LIMIT=0
    [ "$OPT_DRY_RUN" = "1" ] && { [ -n "$OPT_QUERY" ] || [ -n "$OPT_SAVE" ] || [ "$OPT_STATS" = "1" ]; } && {
        echo "  [!] --dry-run несовместим с QUERY, --save, --stats" >&2; exit 2; }
    if [ "$OPT_BY" = "password" ] && [ -n "$OPT_SAVE" ] && [ "$OPT_FORCE" != "1" ]; then
        echo "  [!] --save с --by password требует --force (пароли в открытом виде)" >&2
        exit 2
    fi

    [ "$OPT_NO_COLOR" = "1" ] && { YELLOW=""; GREEN=""; GRAY=""; CYAN=""; RED=""; RESET=""; }
}

setup_log() {
    if [ -n "$OPT_LOG" ]; then
        exec 3>>"$OPT_LOG"
        dbg() { [ "$OPT_DEBUG" = "1" ] && echo "[debug] $*" >&3; }
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────────────────────────────────────

NETWORK_OK=0

main() {
    parse_args "$@"
    setup_log

    # Загрузить конфиг
    local cfg_path="${OPT_CONFIG:-$CONFIG_PATH}"
    if [ -f "$cfg_path" ]; then
        while IFS='=' read -r k v; do
            [ -n "$k" ] && CONFIG["$k"]="$v"
        done < <(read_config "$cfg_path")
    fi

    local no_update="$OPT_NO_UPDATE"
    [ -z "${no_update:-}" ] && no_update=$(cfg_bool no_update 0)
    local no_cache_accs="$OPT_NO_CACHE_ACCS"
    [ "$no_cache_accs" = "0" ] && no_cache_accs=$(cfg_bool no_cache_accs 0)

    local use_cache=1
    [ "$OPT_NO_CACHE" = "1" ] && use_cache=0
    local use_accs_cache=1
    [ "$no_cache_accs" = "1" ] && use_accs_cache=0

    # --unset-config
    if [ "${#OPT_UNSET_CONFIG[@]}" -gt 0 ]; then
        local changed=0
        local -a kv=()
        for key in "${OPT_UNSET_CONFIG[@]}"; do
            if [ -n "${CONFIG[$key]:-}" ]; then
                unset CONFIG["$key"]
                changed=1
            fi
        done
        if [ "$changed" = "1" ]; then
            for k in "${!CONFIG[@]}"; do kv+=("$k=${CONFIG[$k]}"); done
            write_config "$cfg_path" "${kv[@]}"
        else
            echo "  Конфиг не изменён (ключи не найдены)."
        fi
        return 0
    fi

    # --save-config
    if [ "$OPT_SAVE_CONFIG" = "1" ]; then
        local -a kv=()
        for k in "${!CONFIG[@]}"; do kv+=("$k=${CONFIG[$k]}"); done
        [ "$OPT_NO_UPDATE" = "1" ] && kv+=("no_update=true")
        [ "$OPT_NO_CACHE_ACCS" = "1" ] && kv+=("no_cache_accs=true")
        write_config "$cfg_path" "${kv[@]}"
        return 0
    fi

    local interactive=0
    [ "$OPT_INTERACTIVE" = "1" ] || [ -z "$OPT_QUERY" ] && interactive=1

    clear_screen
    echo
    if [ "$OPT_UPDATE_NOW" = "1" ]; then
        check_for_updates 1
    elif [ "$OPT_CHECK_UPDATE" = "1" ] || [ "$no_update" != "1" ]; then
        echo "  Проверка обновлений..."
        check_for_updates 0
    fi

    clear_screen
    echo
    echo "  Загрузка списка аккаунтов..."
    echo

    download_accounts "$use_cache" "$use_accs_cache" || exit 1

    echo "  Загрузка синонимов..."
    load_synonyms "$use_cache"

    local total
    total=$(parse_records | wc -l)
    [ "$total" -eq 0 ] && echo "  [!] Список аккаунтов пуст — возможно, файл повреждён."
    echo "  Аккаунтов загружено: $total"
    echo "  Готово."
    sleep 0.3

    if [ "$OPT_DRY_RUN" = "1" ]; then
        clear_screen; echo
        stats_records "$OPT_STATS_TOP" "$OPT_MIN_GAMES"
        return 0
    fi

    open_save

    if [ "$OPT_STATS" = "1" ]; then
        clear_screen; echo
        stats_records "$OPT_STATS_TOP" "$OPT_MIN_GAMES"
        return 0
    fi

    local limit="$OPT_LIMIT"
    [ "$OPT_ALL" = "1" ] && limit=""

    if [ -n "$OPT_QUERY" ] && [ "$OPT_INTERACTIVE" != "1" ]; then
        run_search "$OPT_QUERY" "$limit" "$OPT_MIN_GAMES" "$OPT_BY" "$OPT_FULL_GAMES"
        return 0
    fi

    interactive_loop "$limit"
    return 0
}

main "$@"

# Автоочистка кэша аккаунтов, если сеть была доступна
if [ "$NETWORK_OK" = "1" ] && [ "${OPT_NO_CACHE:-0}" != "1" ]; then
    delete_cache "$CACHE_ACCS"
fi
