#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import base64
import binascii
import csv
import ctypes
import json
import logging
import os
import re
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request
from collections import Counter
from dataclasses import dataclass, field
from functools import lru_cache
from pathlib import Path

__version__ = "1.5.0"

# ──────────────────────────────────────────────────────────────────────────────
# Конфигурация
# ──────────────────────────────────────────────────────────────────────────────

CURRENT_VERSION = __version__
RAW_URL = (
    "https://raw.githubusercontent.com/mz-seller-funpay/"
    "dfiuh48unfasdimnf78934hnfsdfg4i9m/refs/heads/main/"
    "cse4uymth98e7yehx97e4x90gs%2Cdrlhng580w7"
)
VERSION_URL = (
    "https://raw.githubusercontent.com/mz-seller-funpay/"
    "dfiuh48unfasdimnf78934hnfsdfg4i9m/refs/heads/main/"
    "dUHBIy7bversiond4fonewui"
)
SCRIPT_URL = (
    "https://raw.githubusercontent.com/mz-seller-funpay/"
    "dfiuh48unfasdimnf78934hnfsdfg4i9m/refs/heads/main/"
    "sjdddassdlSCRIPTSlsdunh298ndsaaa/python.py"
)
SYNONYMS_URL = (
    "https://raw.githubusercontent.com/mz-seller-funpay/"
    "dfiuh48unfasdimnf78934hnfsdfg4i9m/refs/heads/main/"
    "1345synnom3gd435ndfhZDFony5464mGGs"
)

USER_AGENT = f"steam-search/{CURRENT_VERSION}"
SHORT_QUERY_WORDBOUND = True
HTTP_RETRIES = 3
CACHE_TTL_SECONDS = 3600
DEFAULT_LIMIT = 50
MAX_RAW_BYTES = 10 * 1024 * 1024
MIN_ALT_LEN = 2

M_GAMES = "🎮"
M_LOGIN = "👤"
M_PASS = "🔒"
PREFIX_GAMES = f"{M_GAMES} Игры: "
PREFIX_LOGIN = f"{M_LOGIN} Логин: "
PREFIX_PASS = f"{M_PASS} Пароль: "

FALLBACK_SYNONYMS = {
    "ведьмак": "witcher", "гта": "grand theft auto", "gta": "grand theft auto",
    "гта 5": "gta 5", "гта онлайн": "gta online",
    "скайрим": "skyrim", "фоллаут": "fallout", "фаллаут": "fallout",
    "фоллаут 4": "fallout 4", "фоллаут нью вегас": "fallout new vegas",
    "киберпанк": "cyberpunk", "киберпанк 2077": "cyberpunk 2077",
    "дарк соулс": "dark souls", "дс": "dark souls", "дс3": "dark souls 3",
    "елден": "elden ring", "элден": "elden ring",
    "секиро": "sekiro", "бладборн": "bloodborne",
    "резидент": "resident evil", "ре4": "resident evil 4",
    "ре вилладж": "resident evil village",
    "фифа": "fc", "фк 25": "fc 25", "еа фк": "fc 25",
    "кс": "cs", "кс2": "cs2", "кске": "cs2", "ксго": "csgo",
    "дота": "dota 2", "майнкрафт": "minecraft", "роблокс": "roblox",
    "фортнайт": "fortnite", "апекс": "apex legends",
    "nba": "nba 2k", "нба": "nba 2k",
    "год оф вар": "god of war", "бог войны": "god of war",
    "паук": "spider-man", "человек паук": "spider-man",
    "ласт оф ас": "last of us", "хорайзон": "horizon",
    "анчартед": "uncharted", "метро": "metro", "сталкер": "s.t.a.l.k.e.r",
    "батлфилд": "battlefield", "колда": "call of duty",
    "нид фор спид": "need for speed", "форза": "forza",
    "симс": "the sims", "стардью": "stardew valley",
    "террария": "terraria", "сабнавтика": "subnautica",
    "раст": "rust", "валхейм": "valheim",
    "палворлд": "palworld", "хадес": "hades", "дед селс": "dead cells",
    "балатро": "balatro", "холлоу найт": "hollow knight",
    "undertale": "undertale", "омори": "omori", "селеста": "celeste",
}

# ──────────────────────────────────────────────────────────────────────────────
# Контекст
# ──────────────────────────────────────────────────────────────────────────────

@dataclass
class Record:
    games: str
    login: str
    password: str
    games_count: int

@dataclass
class Data:
    text: str = ""
    synonyms: dict = field(default_factory=dict)
    records: list = field(default_factory=list)
    network_ok: bool = False

@dataclass
class UI:
    color: bool = sys.stdout.isatty()
    export: str = "txt"
    save_fh: object = None
    csv_writer: object = None
    header_written: bool = False

@dataclass
class App:
    debug: bool = False
    script_path: str = ""
    interactive: bool = False
    data: Data = field(default_factory=Data)
    ui: UI = field(default_factory=UI)

APP = App()
LOG = logging.getLogger("steam-search")


# ──────────────────────────────────────────────────────────────────────────────
# Утилиты
# ──────────────────────────────────────────────────────────────────────────────


def dbg(*args) -> None:
    if APP.debug:
        LOG.debug(" ".join(str(a) for a in args))


def is_windows() -> bool:
    return sys.platform.startswith("win")


HIDDEN_ATTR = 0x02
SYSTEM_ATTR = 0x04


def hide_file(path: Path) -> None:
    if is_windows():
        try:
            attrs = ctypes.windll.kernel32.GetFileAttributesW(str(path))
            if attrs != -1:
                ctypes.windll.kernel32.SetFileAttributesW(
                    str(path), (attrs | HIDDEN_ATTR) & 0xFFFFFFFF)
        except Exception as e:
            dbg(f"hide_file failed: {e}")


def unhide_file(path: Path) -> None:
    if is_windows():
        try:
            attrs = ctypes.windll.kernel32.GetFileAttributesW(str(path))
            if attrs != -1:
                new = attrs & ~HIDDEN_ATTR & ~SYSTEM_ATTR & 0xFFFFFFFF
                ctypes.windll.kernel32.SetFileAttributesW(str(path), new)
        except Exception as e:
            dbg(f"unhide_file failed: {e}")


def clear_screen() -> None:
    if not sys.stdout.isatty():
        return
    sys.stdout.write("\033[2J\033[H")
    sys.stdout.flush()


def safe_write(s: str) -> None:
    try:
        sys.stdout.write(s)
        sys.stdout.flush()
    except UnicodeEncodeError:
        sys.stdout.write(s.encode("utf-8", "replace").decode("utf-8", "replace"))
        sys.stdout.flush()
    except BrokenPipeError:
        sys.exit(0)


def safe_print(s: str = "") -> None:
    safe_write(s + "\n")


def safe_input(prompt: str) -> str:
    safe_write(prompt)
    try:
        line = sys.stdin.readline()
    except (EOFError, KeyboardInterrupt):
        raise
    if line == "":
        raise EOFError
    return line.rstrip("\r\n")


def color(code: str) -> str:
    return code if APP.ui.color else ""


def paint(code: str, s: str) -> str:
    c = color(code)
    return f"{c}{s}{color('\033[0m')}"


# ──────────────────────────────────────────────────────────────────────────────
# HTTP с ETag
# ──────────────────────────────────────────────────────────────────────────────

_ETAG_CACHE: dict[str, tuple[str, bytes]] = {}


def http_get(url: str, timeout: int = 30, use_etag: bool = False) -> bytes:
    last_err = None
    headers = {"User-Agent": USER_AGENT}
    if use_etag and url in _ETAG_CACHE:
        headers["If-None-Match"] = _ETAG_CACHE[url][0]

    for attempt in range(HTTP_RETRIES):
        try:
            req = urllib.request.Request(url, headers=headers)
            with urllib.request.urlopen(req, timeout=timeout) as resp:
                # 304 может прийти без исключения — проверяем статус вручную
                status = getattr(resp, "status", None) or resp.getcode()
                if status == 304 and use_etag and url in _ETAG_CACHE:
                    dbg(f"http_get 304 Not Modified: {url}")
                    return _ETAG_CACHE[url][1]
                data = resp.read()
                if use_etag:
                    etag = resp.headers.get("ETag")
                    if etag:
                        _ETAG_CACHE[url] = (etag, data)
                return data
        except urllib.error.HTTPError as e:
            if e.code == 304 and use_etag and url in _ETAG_CACHE:
                dbg(f"http_get 304 (HTTPError): {url}")
                return _ETAG_CACHE[url][1]
            last_err = e
            dbg(f"http_get HTTP {e.code} attempt {attempt + 1}: {url}")
            if 400 <= e.code < 500 and e.code != 429:
                raise
            if attempt < HTTP_RETRIES - 1:
                time.sleep(1 + attempt)
        except Exception as e:
            last_err = e
            dbg(f"http_get attempt {attempt + 1} failed: {e}")
            if attempt < HTTP_RETRIES - 1:
                time.sleep(1 + attempt)
    raise last_err  # type: ignore[misc]


def normalize_space(s: str) -> str:
    return " ".join(s.split())


def normalize_query(q: str) -> str:
    return normalize_space(q.strip().lower())


def strip_prefix(line: str, prefix: str) -> str:
    return line[len(prefix):] if line.startswith(prefix) else line


def should_wordbound(q: str) -> bool:
    return SHORT_QUERY_WORDBOUND and len(q) < 3


@lru_cache(maxsize=512)
def _wordbound_re(n_lower: str) -> re.Pattern:
    return re.compile(r"(?<!\w)" + re.escape(n_lower) + r"(?!\w)")


def _match(text: str, needle: str, wordbound: bool) -> bool:
    if not needle:
        return False
    t = normalize_space(text.lower())
    n = normalize_space(needle.lower())
    if wordbound and should_wordbound(n):
        return _wordbound_re(n).search(t) is not None
    return n in t


# ──────────────────────────────────────────────────────────────────────────────
# Кэш
# ──────────────────────────────────────────────────────────────────────────────

CACHE_ACCS_NAME = ".steam_accs_cache.txt"
CACHE_SYN_NAME = ".steam_synonyms_cache.json"


def cache_dir() -> Path:
    return Path(tempfile.gettempdir())


def accs_cache_path() -> Path:
    return cache_dir() / CACHE_ACCS_NAME


def syn_cache_path() -> Path:
    return cache_dir() / CACHE_SYN_NAME


def write_hidden(path: Path, data: bytes) -> None:
    try:
        path.write_bytes(data)
        hide_file(path)
        dbg(f"hidden cache written: {path}")
    except Exception as e:
        dbg(f"cache write failed ({path}): {e}")


def read_hidden(path: Path, ttl: int | None = None) -> bytes | None:
    try:
        if not path.is_file():
            return None
        if ttl is not None:
            if time.time() - path.stat().st_mtime > ttl:
                delete_cache(path)
                return None
        return path.read_bytes()
    except Exception as e:
        dbg(f"cache read failed ({path}): {e}")
        return None


def delete_cache(path: Path) -> None:
    try:
        if path.is_file():
            unhide_file(path)
            path.unlink()
            dbg(f"cache deleted: {path}")
    except Exception as e:
        dbg(f"cache delete failed ({path}): {e}")


# ──────────────────────────────────────────────────────────────────────────────
# Синонимы
# ──────────────────────────────────────────────────────────────────────────────


def _parse_synonyms(raw: bytes) -> dict | None:
    try:
        data = json.loads(raw.decode("utf-8"))
    except Exception as e:
        dbg(f"synonyms json parse failed: {e}")
        return None
    if not isinstance(data, dict):
        return None
    out = {}
    for k, v in data.items():
        if not isinstance(k, str):
            continue
        if isinstance(v, str):
            if len(v) >= MIN_ALT_LEN:
                out[normalize_query(k)] = v
        elif isinstance(v, list):
            parts = [str(x) for x in v if isinstance(x, str) and len(x) >= MIN_ALT_LEN]
            if parts:
                out[normalize_query(k)] = "|".join(parts)
    return out


def _split_alt(alt: str) -> list[str]:
    return [a for a in alt.split("|") if len(a) >= MIN_ALT_LEN]


def load_synonyms(use_cache: bool = True) -> dict:
    local = Path(APP.script_path).with_name("synonyms.json")
    if local.is_file():
        try:
            data = _parse_synonyms(local.read_bytes())
            if data:
                dbg(f"synonyms loaded from {local}: {len(data)}")
                return data
        except Exception as e:
            dbg(f"failed to load local synonyms: {e}")

    try:
        raw = http_get(SYNONYMS_URL, timeout=20, use_etag=True)
        data = _parse_synonyms(raw)
        if data:
            dbg(f"synonyms downloaded: {len(data)}")
            if use_cache:
                write_hidden(syn_cache_path(), raw)
            return data
    except Exception as e:
        dbg(f"failed to download synonyms: {e}")

    if use_cache:
        raw = read_hidden(syn_cache_path(), ttl=CACHE_TTL_SECONDS)
        if raw:
            data = _parse_synonyms(raw)
            if data:
                print("  [!] Синонимы загружены из кэша (сеть недоступна).")
                return data

    print("  [!] synonyms.json недоступен — используется встроенный fallback.")
    return dict(FALLBACK_SYNONYMS)


# ──────────────────────────────────────────────────────────────────────────────
# Обновление
# ──────────────────────────────────────────────────────────────────────────────


def _validate_script(data: bytes) -> bool:
    text = data.decode("utf-8", "ignore")
    return "CURRENT_VERSION" in text and "def check_for_updates" in text


def check_for_updates(force: bool = False) -> None:
    try:
        raw = http_get(VERSION_URL, timeout=10, use_etag=True)
        remote = raw.decode("utf-8", "ignore").strip()
    except Exception as e:
        print(f"  [!] Не удалось проверить обновления: {e}")
        return

    if not remote:
        print("  [!] Сервер вернул пустую версию — пропускаем проверку.")
        return

    if remote == CURRENT_VERSION and not force:
        print(f"  У вас последняя версия ({CURRENT_VERSION}).")
        return

    print()
    if remote == CURRENT_VERSION:
        print(f"  Версия не изменилась ({CURRENT_VERSION}). Переустановить?")
    else:
        print(f"  Доступна версия: {remote} (у вас {CURRENT_VERSION})")

    if not force:
        try:
            choice = safe_input("  Обновить скрипт? (y/n): ").strip().lower()
        except (EOFError, KeyboardInterrupt):
            return
        if choice != "y":
            print("  Пропускаем обновление.")
            return

    print("  Скачиваем новую версию...")
    tmp_file = None
    try:
        data = http_get(SCRIPT_URL, timeout=30)
        if not _validate_script(data):
            print("  [!] Скачанный файл не похож на скрипт. Обновление отменено.")
            return

        script_dir = os.path.dirname(APP.script_path) or "."
        fd, tmp_file = tempfile.mkstemp(
            prefix=".steam_upd_", suffix=".py", dir=script_dir,
        )
        with os.fdopen(fd, "wb") as f:
            f.write(data)

        try:
            os.replace(tmp_file, APP.script_path)
            tmp_file = None
        except OSError as e:
            print(f"  [!] Не удалось заменить файл: {e}")
            return

        try:
            os.chmod(APP.script_path, 0o755)
        except Exception:
            pass

        print("  Обновление завершено. Закрываем скрипт.")
        print("  Запустите его снова, чтобы использовать новую версию.")
        sys.exit(0)          # ← выход, ничего дальше не выполняется
    except SystemExit:
        raise
    except Exception as e:
        print(f"  [!] Не удалось обновить: {e}")
    finally:
        if tmp_file and os.path.exists(tmp_file):
            try:
                os.remove(tmp_file)
            except Exception:
                pass
        try:
            os.replace(tmp_file, APP.script_path)
            tmp_file = None
        except OSError as e:
            print(f"  [!] Не удалось заменить файл: {e}")
            return

        try:
            os.chmod(APP.script_path, 0o755)
        except Exception:
            pass

        print("  Обновление завершено.")
        print("  Перезапустите скрипт, чтобы использовать новую версию.")
    except Exception as e:
        print(f"  [!] Не удалось обновить: {e}")
    finally:
        if tmp_file and os.path.exists(tmp_file):
            try:
                os.remove(tmp_file)
            except Exception:
                pass


# ──────────────────────────────────────────────────────────────────────────────
# Загрузка аккаунтов
# ──────────────────────────────────────────────────────────────────────────────


def download_accounts(use_cache: bool, use_accs_cache: bool) -> str:
    try:
        raw = http_get(RAW_URL, timeout=30, use_etag=True)
        if len(raw) > MAX_RAW_BYTES:
            raise RuntimeError(f"файл слишком большой ({len(raw)} байт)")
        b64 = re.sub(rb"\s+", b"", raw)
        try:
            data = base64.b64decode(b64, validate=True)
        except binascii.Error as e:
            raise RuntimeError(f"base64 decode failed: {e}")
        text = data.decode("utf-8", "ignore")
        if "Логин:" not in text:
            raise RuntimeError("файл повреждён или не похож на список аккаунтов")
        if M_GAMES not in text:
            print("  [!] Формат файла не совпадает с ожидаемым (нет 🎮).")
        APP.data.network_ok = True
        if use_cache and use_accs_cache:
            write_hidden(accs_cache_path(), data)
        return text
    except Exception as e:
        if use_cache and use_accs_cache:
            cached = read_hidden(accs_cache_path(), ttl=CACHE_TTL_SECONDS)
            if cached:
                print(f"  [!] Сеть недоступна ({e}). Используем кэш из TEMP.")
                APP.data.network_ok = False
                return cached.decode("utf-8", "ignore")
        raise


# ──────────────────────────────────────────────────────────────────────────────
# Парсинг
# ──────────────────────────────────────────────────────────────────────────────


def games_list(games_line: str) -> list[str]:
    text = strip_prefix(games_line, PREFIX_GAMES)
    return [normalize_space(g) for g in text.split(", ") if g.strip()]


def parse_records(text: str) -> list[Record]:
    out: list[Record] = []
    games = login = password = ""

    def push():
        if games and login:
            out.append(Record(
                games=strip_prefix(games, PREFIX_GAMES),
                login=strip_prefix(login, PREFIX_LOGIN),
                password=strip_prefix(password, PREFIX_PASS),
                games_count=len(games_list(games)),
            ))

    for line in text.splitlines():
        if line.startswith(M_GAMES):
            push()
            games = line
            login = password = ""
        elif line.startswith(M_LOGIN):
            login = line
        elif line.startswith(M_PASS):
            password = line
        elif line.strip() == "":
            push()
            games = login = password = ""
    push()
    return out


# ──────────────────────────────────────────────────────────────────────────────
# Запросы: , (OR), + (AND), - (NOT)
# ──────────────────────────────────────────────────────────────────────────────


@dataclass
class Query:
    groups: list[list[str]] = field(default_factory=list)
    alts: list[list[str]] = field(default_factory=list)
    excludes: list[str] = field(default_factory=list)
    excludes_alt: list[str] = field(default_factory=list)

    def is_empty(self) -> bool:
        return not self.groups


def _resolve_alt(term: str, synonyms: dict) -> list[str]:
    syn = synonyms.get(term, "")
    return _split_alt(syn) if syn else []


def parse_query(raw: str, synonyms: dict) -> Query:
    q = Query()
    positive_parts = []
    for chunk in raw.split(","):
        chunk = chunk.strip()
        if not chunk:
            continue
        terms = []
        for tok in chunk.split():
            if tok.startswith("-") and len(tok) > 1:
                term = normalize_query(tok[1:])
                if term:
                    q.excludes.append(term)
                    q.excludes_alt.extend(_resolve_alt(term, synonyms))
            else:
                terms.append(tok)
        if "+" in terms:
            parts = [t for t in terms if t != "+"]
        else:
            parts = terms
        normalized = [normalize_query(p) for p in parts if normalize_query(p)]
        if normalized:
            positive_parts.append(normalized)

    for terms in positive_parts:
        q.groups.append(terms)
        q.alts.append([a for t in terms for a in _resolve_alt(t, synonyms)])
    return q


def _query_line_matches(line: str, q: Query) -> bool:
    if not q.groups:
        return False
    matched_group = False
    for terms, alts in zip(q.groups, q.alts):
        all_terms = True
        for t in terms:
            if not _match(line, t, wordbound=True):
                all_terms = False
                break
        if all_terms:
            matched_group = True
            break
        all_alts = True
        for a in alts:
            if not _match(line, a, wordbound=False):
                all_alts = False
                break
        if all_alts and alts:
            matched_group = True
            break
    if not matched_group:
        return False
    for ex in q.excludes:
        if _match(line, ex, wordbound=True):
            return False
    for ex in q.excludes_alt:
        if _match(line, ex, wordbound=False):
            return False
    return True


# ──────────────────────────────────────────────────────────────────────────────
# Вывод
# ──────────────────────────────────────────────────────────────────────────────


def format_games(rec: Record, q: Query, full: bool = False) -> str:
    games = games_list(rec.games)
    total = len(games)
    if full:
        return ", ".join(games)
    if total <= 3:
        return ", ".join(games)

    all_q = [t for group in q.groups for t in group]
    all_alt = [a for group in q.alts for a in group]

    matched = []
    for g in games:
        hit = any(_match(g, t, wordbound=True) for t in all_q) or \
              any(_match(g, a, wordbound=False) for a in all_alt)
        if hit and g not in matched:
            matched.append(g)

    if matched:
        shown = matched[:3]
        rest = len(matched) - len(shown)
        base = ", ".join(shown)
        return f"{base}  +{rest} совпадений" if rest > 0 else base

    shown = games[:3]
    return f"{', '.join(shown)}  +{total - 3} игр"


def format_account(rec: Record, q: Query, full: bool = False) -> str:
    yellow = color("\033[33m")
    green = color("\033[32m")
    gray = color("\033[90m")
    reset = color("\033[0m")
    games_str = format_games(rec, q, full)
    return (
        f"  {yellow}{M_GAMES} {games_str}{reset}\n"
        f"     {green}Логин: {rec.login}{reset}\n"
        f"     {gray}Пароль: {rec.password}{reset}\n"
    )


def write_record(rec: Record, q: Query, full: bool = False) -> None:
    out = APP.ui.save_fh
    if out is None:
        return
    export = APP.ui.export
    if export == "csv":
        APP.ui.csv_writer.writerow([rec.login, rec.password, rec.games, rec.games_count])
    elif export == "jsonl":
        out.write(json.dumps({
            "login": rec.login,
            "password": rec.password,
            "games": rec.games,
            "games_count": rec.games_count,
        }, ensure_ascii=False) + "\n")
    else:
        out.write(f"{format_games(rec, q, full)}\n")
        out.write(f"  Логин: {rec.login}\n")
        out.write(f"  Пароль: {rec.password}\n\n")
    out.flush()


def search_records(records, q, limit, min_games=0, full=False) -> int:
    header_written = False
    found = 0
    shown = 0

    for rec in records:
        if rec.games_count < min_games:
            continue
        if not _query_line_matches(PREFIX_GAMES + rec.games, q):
            continue

        found += 1
        if limit is not None and shown >= limit:
            continue

        if APP.ui.save_fh is not None and not header_written:
            flat = [t for g in q.groups for t in g]
            APP.ui.save_fh.write(
                f"\n=== {time.strftime('%Y-%m-%d %H:%M:%S')} | "
                f"{', '.join(flat) or '-'} ===\n"
            )
            header_written = True

        safe_print(format_account(rec, q, full))
        write_record(rec, q, full)
        shown += 1

    sep = color("\033[90m") + "  " + "─" * 42 + color("\033[0m")
    safe_print(sep)
    if found == 0:
        safe_print(paint("\033[91m", "  Ничего не найдено."))
    else:
        suffix = ""
        if limit is not None and found > shown:
            suffix = f"  (показано {shown}, используйте --all или --limit N)"
        safe_print(paint("\033[96m", f"  Найдено: {found}{suffix}"))
    if q.excludes:
        safe_print(paint("\033[90m", f"  исключено: {', '.join(q.excludes)}"))
    return found


def stats_records(records, top=10, min_games=0) -> None:
    records = [r for r in records if r.games_count >= min_games]
    total = len(records)
    no_games = sum(1 for r in records if r.games_count == 0)
    counter = Counter()
    display = {}
    dist = Counter()

    for rec in records:
        dist[rec.games_count] += 1
        for g in games_list(rec.games):
            key = normalize_space(g.strip().lower())
            counter[key] += 1
            display.setdefault(key, g.strip())

    safe_print(f"  Аккаунтов: {total}")
    if no_games:
        safe_print(f"  Аккаунтов без игр: {no_games}")
    safe_print(f"  Уникальных игр: {len(counter)}")
    safe_print()
    safe_print(paint("\033[96m", f"  Топ-{top} игр:"))
    for key, cnt in counter.most_common(top):
        safe_print(f"    {paint('\033[32m', f'{cnt:>5}')}  {display[key]}")
    safe_print()
    safe_print(paint("\033[96m", "  Распределение по числу игр:"))
    for n in sorted(dist):
        safe_print(f"    {paint('\033[32m', f'{n:>3}')} игр  —  {dist[n]} акк.")


def print_filter_info(records, min_games) -> None:
    if min_games <= 0:
        return
    passed = sum(1 for r in records if r.games_count >= min_games)
    safe_print(f"  Фильтр --min-games {min_games}: {passed} из {len(records)}")
    safe_print()


# ──────────────────────────────────────────────────────────────────────────────
# Конфиг
# ──────────────────────────────────────────────────────────────────────────────


def default_config_path() -> Path:
    return Path.home() / ".steam_search_config.json"


def read_config(path: Path) -> dict:
    try:
        if path.is_file():
            data = json.loads(path.read_text(encoding="utf-8"))
            return data if isinstance(data, dict) else {}
    except Exception as e:
        dbg(f"config read failed: {e}")
    return {}


def get_bool(cfg: dict, key: str, default: bool = False) -> bool:
    v = cfg.get(key, default)
    return bool(v) if isinstance(v, (bool, int)) else default


def write_config(path: Path, cfg: dict) -> None:
    try:
        path.write_text(json.dumps(cfg, ensure_ascii=False, indent=2),
                        encoding="utf-8")
        safe_print(f"  Конфиг сохранён: {path}")
    except Exception as e:
        safe_print(f"  [!] Не удалось сохранить конфиг: {e}")


# ──────────────────────────────────────────────────────────────────────────────
# CLI
# ──────────────────────────────────────────────────────────────────────────────


def parse_args(argv=None):
    p = argparse.ArgumentParser(
        prog="python.py",
        description="Поиск аккаунтов Steam по названию игры.",
    )
    p.add_argument("query", nargs="?", help="игра для поиска (без интерактива)")
    p.add_argument("--version", action="version", version=f"%(prog)s {CURRENT_VERSION}")
    p.add_argument("--no-update", action="store_true", default=None,
                   help="не проверять обновления")
    p.add_argument("--update-now", action="store_true", help="принудительно обновить")
    p.add_argument("--check-update", action="store_true",
                   help="проверить обновления, несмотря на конфиг")
    p.add_argument("--force", action="store_true",
                   help="разрешить опасные комбинации (--by password + --save)")
    p.add_argument("--interactive", "-i", action="store_true",
                   help="принудительно интерактивный режим")
    p.add_argument("--no-cache", action="store_true", help="не использовать кэш")
    p.add_argument("--no-cache-accs", action="store_true", default=None,
                   help="не кэшировать аккаунты")
    p.add_argument("--save", metavar="FILE", help="сохранять результаты в файл")
    p.add_argument("--save-mode", choices=["a", "w"], default="a")
    p.add_argument("--export", choices=["txt", "csv", "jsonl"], default="txt")
    p.add_argument("--csv-header", action="store_true",
                   help="писать заголовок CSV, если файл пустой")
    p.add_argument("--csv-delimiter", default=",", metavar="CHAR",
                   help="разделитель CSV (по умолчанию ',')")
    p.add_argument("--limit", type=int, default=DEFAULT_LIMIT, metavar="N",
                   help=f"максимум отображаемых результатов (0 — без лимита; "
                        f"по умолчанию {DEFAULT_LIMIT})")
    p.add_argument("--all", action="store_true", help="без лимита результатов")
    p.add_argument("--min-games", type=int, default=0, metavar="N",
                   help="только аккаунты с >= N играми")
    p.add_argument("--full-games", action="store_true",
                   help="показывать весь список игр аккаунта")
    p.add_argument("--stats", action="store_true", help="статистика и выход")
    p.add_argument("--stats-top", type=int, default=10, metavar="N",
                   help="сколько игр в топе статистики (по умолчанию 10)")
    p.add_argument("--by", choices=["games", "login", "password"], default="games",
                   help="по чему искать; ВНИМАНИЕ: --by password выводит пароли")
    p.add_argument("--no-color", action="store_true", help="без ANSI-цветов")
    p.add_argument("--config", metavar="FILE", default=None,
                   help="путь к конфигу (по умолчанию ~/.steam_search_config.json)")
    p.add_argument("--save-config", action="store_true",
                   help="сохранить текущие флаги в конфиг")
    p.add_argument("--unset-config", metavar="KEY", action="append", default=[],
                   help="удалить ключ из конфига (можно несколько раз)")
    p.add_argument("--dry-run", action="store_true",
                   help="загрузить данные, показать статистику, выйти")
    p.add_argument("--log", metavar="FILE", help="писать debug-лог в файл")
    p.add_argument("--debug", action="store_true", help="подробный вывод в stderr")
    args = p.parse_args(argv)

    if args.min_games < 0:
        p.error("--min-games must be >= 0")
    if args.stats_top <= 0:
        p.error("--stats-top must be > 0")
    if args.limit < 0:
        p.error("--limit must be >= 0")
    if args.csv_header and args.export != "csv":
        p.error("--csv-header requires --export csv")
    if args.all:
        args.limit = 0
    if args.dry_run and (args.query or args.save or args.stats):
        p.error("--dry-run несовместим с QUERY, --save, --stats")
    if args.by == "password" and args.save and not args.force:
        p.error("--save с --by password требует --force (пароли в открытом виде)")
    return args


def open_save(args) -> None:
    if not args.save:
        return
    try:
        path = Path(args.save)
        if path.resolve() in (accs_cache_path().resolve(), syn_cache_path().resolve()):
            raise RuntimeError("--save указывает на файл кэша")
        path.parent.mkdir(parents=True, exist_ok=True)
        is_empty = not path.exists() or path.stat().st_size == 0
        if args.save_mode == "w" and not is_empty:
            print(f"  [!] --save-mode w перезапишет {path}")
        fh = open(path, args.save_mode, encoding="utf-8", newline="")
        APP.ui.save_fh = fh
        if args.export == "csv":
            APP.ui.csv_writer = csv.writer(
                fh, delimiter=args.csv_delimiter, dialect="unix")
            if args.csv_header and is_empty:
                APP.ui.csv_writer.writerow(
                    ["login", "password", "games", "games_count"])
        dbg(f"results saved to {args.save} ({args.save_mode})")
    except Exception as e:
        safe_print(f"  [!] Не удалось открыть файл для сохранения: {e}")


def close_save() -> None:
    if APP.ui.save_fh is not None:
        try:
            APP.ui.save_fh.close()
        except Exception:
            pass
        APP.ui.save_fh = None


# ──────────────────────────────────────────────────────────────────────────────
# Режимы
# ──────────────────────────────────────────────────────────────────────────────


def run_search(raw_query: str, limit: int | None, min_games: int,
               by: str, full: bool) -> int:
    q = parse_query(raw_query, APP.data.synonyms)
    if q.is_empty():
        safe_print("  [!] Пустой запрос.")
        return 0

    records = APP.data.records

    if by != "games":
        if by == "password":
            safe_print("  [!] --by password: результаты содержат пароли в открытом виде.")
        filtered = []
        for rec in records:
            if rec.games_count < min_games:
                continue
            field = rec.login if by == "login" else rec.password
            if _query_line_matches(field, q):
                filtered.append(rec)
        safe_print(f"  Поиск по {by}: {raw_query}")
        safe_print("  " + "─" * 42)
        safe_print()
        shown = 0
        for rec in filtered:
            if limit is not None and limit > 0 and shown >= limit:
                continue
            safe_print(format_account(rec, q, full))
            write_record(rec, q, full)
            shown += 1
        if not filtered:
            safe_print(paint("\033[91m", "  Ничего не найдено."))
        else:
            suffix = ""
            if limit is not None and limit > 0 and len(filtered) > shown:
                suffix = f"  (показано {shown})"
            safe_print(paint("\033[96m", f"  Найдено: {len(filtered)}{suffix}"))
        return len(filtered)

    safe_print(f"  Поиск: {raw_query}")
    if q.excludes:
        safe_print(f"  Исключено: {', '.join(q.excludes)}")
    safe_print("  " + "─" * 42)
    safe_print()
    print_filter_info(records, min_games)
    return search_records(records, q, limit, min_games, full)


def interactive_loop(args, limit: int | None) -> None:
    while True:
        clear_screen()
        safe_print()
        safe_print("  ┌─────────────────────────────────────────┐")
        safe_print("  │   ПОИСК АККАУНТОВ STEAM                 │")
        safe_print("  │   автор: MisterZidez                    │")
        ver = CURRENT_VERSION[:28] + (".." if len(CURRENT_VERSION) > 30 else "")
        safe_print(f"  │   версия: {ver:<30}│")
        safe_print("  └─────────────────────────────────────────┘")
        safe_print()

        try:
            query = safe_input(
                "  Игра (q — выход, s/статистика, h/помощь): "
            ).strip()
        except (EOFError, KeyboardInterrupt):
            safe_print()
            return
        if not query:
            continue
        low = query.lower()
        if low in ("q", "quit", "exit", "выход"):
            return
        if low in ("s", "stat", "stats", "статистика"):
            clear_screen()
            safe_print()
            stats_records(APP.data.records, args.stats_top, args.min_games)
            safe_print()
            try:
                safe_input("  Enter — назад...")
            except (EOFError, KeyboardInterrupt):
                return
            continue
        if low in ("h", "?", "help", "помощь"):
            clear_screen()
            safe_print()
            safe_print("  Введите название игры.")
            safe_print("  ',' — OR, '+' — AND, '-' — исключить.")
            safe_print("  Пример: гта + ведьмак -кс")
            safe_print("  Синонимы подставляются автоматически (гта → grand theft auto).")
            safe_print("  q — выход, s — статистика, h — эта справка.")
            safe_print()
            try:
                safe_input("  Enter — назад...")
            except (EOFError, KeyboardInterrupt):
                return
            continue

        clear_screen()
        safe_print()
        run_search(query, limit, args.min_games, args.by, args.full_games)

        safe_print()
        try:
            nxt = safe_input("  Enter — новый поиск, q — выход: ").strip().lower()
        except (EOFError, KeyboardInterrupt):
            safe_print()
            return
        if nxt == "q":
            return


def setup_logging(args) -> None:
    handler = None
    if args.log:
        try:
            handler = logging.FileHandler(args.log, encoding="utf-8")
            handler.setFormatter(logging.Formatter(
                "%(asctime)s %(levelname)s %(message)s"))
        except Exception as e:
            print(f"  [!] Не удалось открыть лог: {e}", file=sys.stderr)
            handler = None
    if handler is None:
        handler = logging.StreamHandler(sys.stderr)
        handler.setFormatter(logging.Formatter("[%(levelname)s] %(message)s"))
    LOG.addHandler(handler)
    LOG.setLevel(logging.DEBUG if args.debug else logging.WARNING)


def main(argv=None) -> int:
    args = parse_args(argv)
    APP.debug = args.debug
    APP.script_path = os.path.abspath(sys.argv[0])
    APP.ui.export = args.export
    APP.ui.color = not args.no_color and sys.stdout.isatty()
    setup_logging(args)

    config_path = Path(args.config) if args.config else default_config_path()
    cfg = read_config(config_path)

    no_update = args.no_update if args.no_update is not None else get_bool(cfg, "no_update")
    no_cache_accs = (
        args.no_cache_accs if args.no_cache_accs is not None
        else get_bool(cfg, "no_cache_accs")
    )

    use_cache = not args.no_cache
    use_accs_cache = not no_cache_accs
    limit = None if args.limit == 0 else args.limit

    if args.unset_config:
        changed = False
        for key in args.unset_config:
            if key in cfg:
                cfg.pop(key, None)
                changed = True
        if changed:
            write_config(config_path, cfg)
        else:
            safe_print("  Конфиг не изменён (ключи не найдены).")
        return 0

    if args.save_config:
        if args.no_update is not None:
            cfg["no_update"] = args.no_update
        if args.no_cache_accs is not None:
            cfg["no_cache_accs"] = args.no_cache_accs
        write_config(config_path, cfg)
        return 0

    APP.interactive = bool(args.interactive or not args.query)

    clear_screen()
    safe_print()
    if args.update_now:
        check_for_updates(force=True)
    elif args.check_update or not no_update:
        safe_print("  Проверка обновлений...")
        check_for_updates()

    clear_screen()
    safe_print()
    safe_print("  Загрузка списка аккаунтов...")
    safe_print()

    try:
        APP.data.text = download_accounts(use_cache=use_cache,
                                          use_accs_cache=use_accs_cache)
    except Exception as e:
        safe_print(f"  [!] Не удалось получить список аккаунтов: {e}")
        return 1

    safe_print("  Загрузка синонимов...")
    APP.data.synonyms = load_synonyms(use_cache=use_cache)

    APP.data.records = parse_records(APP.data.text)
    if not APP.data.records:
        safe_print("  [!] Список аккаунтов пуст — возможно, файл повреждён.")
    safe_print(f"  Аккаунтов загружено: {len(APP.data.records)}")
    safe_print("  Готово.")
    time.sleep(0.3)

    if args.dry_run:
        clear_screen()
        safe_print()
        stats_records(APP.data.records, args.stats_top, args.min_games)
        return 0

    open_save(args)

    try:
        if args.stats:
            clear_screen()
            safe_print()
            stats_records(APP.data.records, args.stats_top, args.min_games)
            return 0

        if args.query and not args.interactive:
            run_search(args.query, limit, args.min_games, args.by, args.full_games)
            return 0

        interactive_loop(args, limit)
        return 0
    finally:
        close_save()
        if use_cache and use_accs_cache and APP.data.network_ok:
            delete_cache(accs_cache_path())


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        safe_print()
        sys.exit(0)
    except BrokenPipeError:
        sys.exit(0)
