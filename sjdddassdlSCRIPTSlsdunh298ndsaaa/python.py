import base64
import os
import sys
import urllib.request
import re
import time
import subprocess
from difflib import SequenceMatcher

def ensure_pymorphy3():
    try:
        import pymorphy3  # noqa: F401
        return True
    except ImportError:
        pass
    print("  Установка зависимости pymorphy3 (один раз)...")
    try:
        subprocess.check_call(
            [sys.executable, "-m", "pip", "install", "--quiet", "pymorphy3"],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
        )
        import pymorphy3  # noqa: F401
        print("  Готово.")
        return True
    except Exception as e:
        print(f"  [!] Не удалось установить pymorphy3: {e}")
        print("  Продолжаем без нормализации русских слов.")
        return False


HAS_MORPH = ensure_pymorphy3()
if HAS_MORPH:
    import pymorphy3
    MORPH = pymorphy3.MorphAnalyzer()
else:
    MORPH = None

CURRENT_VERSION = "1.0.1"
RAW_URL = "https://raw.githubusercontent.com/mz-seller-funpay/dfiuh48unfasdimnf78934hnfsdfg4i9m/refs/heads/main/cse4uymth98e7yehx97e4x90gs%2Cdrlhng580w7"
VERSION_URL = "https://raw.githubusercontent.com/mz-seller-funpay/dfiuh48unfasdimnf78934hnfsdfg4i9m/refs/heads/main/dUHBIy7bversiond4fonewui"
SCRIPT_URL = "https://raw.githubusercontent.com/mz-seller-funpay/dfiuh48unfasdimnf78934hnfsdfg4i9m/refs/heads/main/sjdddassdlSCRIPTSlsdunh298ndsaaa/python.py"

SYNONYMS = {
    "ведьмак": "witcher", "паук": "spider", "гта": "grand theft auto", "gta": "grand theft auto",
    "ведьмак 3": "witcher 3", "скайрим": "skyrim", "дум": "doom", "мортал": "mortal kombat",
    "резидент": "resident evil", "обитель": "resident evil", "томб райдер": "tomb raider",
    "дайинг": "dying light", "киберпанк": "cyberpunk", "хогвартс": "hogwarts",
    "бог войны": "god of war", "год оф вар": "god of war", "человек паук": "spider-man",
    "последний из нас": "last of us", "ласт оф ас": "last of us", "мафия": "mafia",
    "душа": "souls", "елден": "elden ring", "элден": "elden ring", "кольцо": "elden ring",
    "сталкер": "stalker", "метро": "metro", "фоллаут": "fallout", "фаллаут": "fallout",
    "ассасин": "assassin", "крид": "creed",  "фар край": "far cry", "фаркрай": "far cry",
    "батлфилд": "battlefield", "колда": "call of duty", "кол оф дьюти": "call of duty",
    "фифа": "fc", "фифа 25": "fc 25", "сталкер": "S.T.A.L.K.E.R", "еа фк": "fc 25",
    "форза": "forza", "хорайзон": "horizon", "зелда": "zelda", "марио": "mario",
    "сонс оф форест": "sons of the forest", "форест": "the forest", "лес": "the forest",
    "рафт": "raft", "портал": "portal", "майнкрафт": "minecraft",
    "террария": "terraria", "тетрис": "tetris", "варкрафт": "warcraft", "старкрафт": "starcraft",
    "ведьмак дикая охота": "witcher 3 wild hunt", "киберпанк 2077": "cyberpunk 2077",
    "данганронпа": "danganronpa", "данганронпа 2": "danganronpa 2", "данганронпа v3": "danganronpa v3",
    "данганронпа 3": "danganronpa v3", "данга": "danganronpa",
}


def enable_ansi():
    if os.name == "nt":
        os.system("")


def set_title(title):
    if os.name == "nt":
        os.system(f"title {title}")


def clear():
    os.system("cls" if os.name == "nt" else "clear")


def normalize_word(word):
    w = word.lower().strip()
    if MORPH and re.match(r'^[а-яё]+$', w):
        return MORPH.parse(w)[0].normal_form
    return w


def fuzzy_match(text, query, threshold=0.75):
    if not text or not query:
        return False
    t = text.lower()
    q = query.lower()
    if q in t:
        return True
    if SequenceMatcher(None, t, q).ratio() >= threshold:
        return True
    for word in re.split(r'[^a-zа-яё0-9]+', t):
        if word and SequenceMatcher(None, word, q).ratio() >= threshold:
            return True
    return False


def check_for_updates():
    try:
        req = urllib.request.Request(VERSION_URL, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=10) as r:
            remote_version = r.read().decode("utf-8").strip()
    except Exception:
        return

    if not remote_version or remote_version == CURRENT_VERSION:
        return

    print(f"\n  Доступна новая версия: {remote_version} (у вас {CURRENT_VERSION})")
    try:
        choice = input("  Обновить скрипт? (y/n): ").strip().lower()
    except (EOFError, KeyboardInterrupt):
        return
    if choice != "y":
        print("  Пропускаем обновление.\n")
        return

    print("  Скачиваем новую версию...")
    try:
        req = urllib.request.Request(SCRIPT_URL, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=30) as r:
            new_code = r.read().decode("utf-8")
    except Exception as e:
        print(f"  [!] Не удалось скачать обновление: {e}")
        return

    if "RAW_URL" not in new_code:
        print("  [!] Скачанный файл не похож на скрипт. Обновление отменено.")
        return

    try:
        with open(__file__, "w", encoding="utf-8") as f:
            f.write(new_code)
        print("  Скрипт обновлён! Перезапускаем...\n")
        time.sleep(1)
        os.execv(sys.executable, [sys.executable] + sys.argv)
    except Exception as e:
        print(f"  [!] Не удалось записать файл: {e}")
        print("  Возможно, нет прав на запись в эту папку.")


def download_and_decode():
    req = urllib.request.Request(RAW_URL, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=30) as r:
        b64 = r.read().decode("utf-8", errors="ignore")
    b64 = re.sub(r"\s", "", b64)
    raw = base64.b64decode(b64)
    text = raw.decode("utf-8", errors="replace")
    if "Логин:" not in text:
        raise ValueError("Файл не похож на список аккаунтов")
    return text.splitlines()


def format_games(games_line, query_list):
    games_text = re.sub(r"^🎮\s*Игры:\s*", "", games_line)
    games = [g.strip() for g in re.split(r",\s*", games_text) if g.strip()]
    total = len(games)
    matched = []
    for qq in query_list:
        for g in games:
            if g not in matched and (qq.lower() in g.lower() or fuzzy_match(g, qq)):
                matched.append(g)
    if total <= 3:
        return ", ".join(games)
    if matched:
        shown = matched[:3]
        rest = total - len(shown)
        return ", ".join(shown) + (f"  +{rest} игр" if rest > 0 else "")
    else:
        shown = games[:3]
        return ", ".join(shown) + f"  +{total - 3} игр"


def search(lines, query):
    q = query.strip()
    if not q:
        return

    q_lower = q.lower()
    alt = SYNONYMS.get(q_lower)
    queries = [q]
    if alt:
        queries.append(alt)

    if MORPH and re.match(r'^[а-яё\s]+$', q_lower):
        norm = normalize_word(q_lower)
        if norm and norm not in queries:
            queries.append(norm)

    found = 0
    games = login = password = ""
    match = False

    def print_account(g, l, p):
        print(f"  \033[33m🎮 {format_games(g, queries)}\033[0m")
        print(f"     \033[32m{re.sub(r'^👤\s*Логин:\s*', 'Логин: ', l)}\033[0m")
        print(f"     \033[90m{re.sub(r'^🔒\s*Пароль:\s*', 'Пароль: ', p)}\033[0m")
        print()

    def is_match(line):
        for qq in queries:
            if qq.lower() in line.lower():
                return True
            if fuzzy_match(line, qq):
                return True
        return False

    for line in lines:
        if line.startswith("🎮"):
            games = line
            login = password = ""
            match = is_match(line)
        elif line.startswith("👤"):
            login = line
        elif line.startswith("🔒"):
            password = line
        elif line.strip() == "":
            if match:
                print_account(games, login, password)
                found += 1
                match = False

    if match:
        print_account(games, login, password)
        found += 1

    print("  \033[90m" + "─" * 42 + "\033[0m")
    if found == 0:
        print("  \033[91mНичего не найдено.\033[0m")
    else:
        print(f"  \033[96mНайдено: {found}\033[0m")
    if alt:
        print(f"  \033[90m(искали также: {alt})\033[0m")


def show_header():
    print()
    print("  ┌─────────────────────────────────────────┐")
    print("  │   ПОИСК АККАУНТОВ STEAM                 │")
    link = "\033]8;;https://funpay.com/users/12871901/\033\\MisterZidez\033]8;;\033\\"
    prefix = "  │   автор: "
    print(f"{prefix}{link}" + " " * 20 + "│")
    print(f"  │   версия: {CURRENT_VERSION}".ljust(44) + "│")
    print("  └─────────────────────────────────────────┘")
    print()


def main():
    enable_ansi()
    set_title("Поиск аккаунтов Steam — by MisterZidez")

    clear()
    print()
    print("  Проверка обновлений...")
    check_for_updates()

    clear()
    print()
    print("  Загрузка списка аккаунтов...")
    print()

    try:
        lines = download_and_decode()
        print("  Готово.")
    except Exception as e:
        print(f"  [!] Не удалось загрузить файл: {e}")
        input("  Нажмите Enter для выхода...")
        sys.exit(1)

    time.sleep(1)
    clear()

    while True:
        show_header()
        try:
            query = input("  Введите игру: ")
        except (EOFError, KeyboardInterrupt):
            break
        if not query.strip():
            clear()
            continue

        clear()
        print()
        print(f"  Поиск: {query}")
        print("  " + "─" * 42)
        print()

        search(lines, query)

        print()
        input("  Нажмите Enter для нового поиска...")
        clear()


if __name__ == "__main__":
    main()
