import base64
import os
import sys
import urllib.request
import re
import time
import subprocess
from difflib import SequenceMatcher

# --- Автоустановка pymorphy3 при первом запуске ---
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

CURRENT_VERSION = "1.1.0"
RAW_URL = "https://raw.githubusercontent.com/mz-seller-funpay/dfiuh48unfasdimnf78934hnfsdfg4i9m/refs/heads/main/cse4uymth98e7yehx97e4x90gs%2Cdrlhng580w7"
VERSION_URL = "https://raw.githubusercontent.com/mz-seller-funpay/dfiuh48unfasdimnf78934hnfsdfg4i9m/refs/heads/main/dUHBIy7bversiond4fonewui"
SCRIPT_URL = "https://raw.githubusercontent.com/mz-seller-funpay/dfiuh48unfasdimnf78934hnfsdfg4i9m/refs/heads/main/sjdddassdlSCRIPTSlsdunh298ndsaaa/python.py"

SYNONYMS = {
    # --- Базовые ---
    "ведьмак": "witcher", "паук": "spider", "гта": "grand theft auto", "gta": "grand theft auto",
    "ведьмак 3": "witcher 3", "скайрим": "skyrim", "дум": "doom", "мортал": "mortal kombat",
    "резидент": "resident evil", "обитель": "resident evil", "томб райдер": "tomb raider",
    "дайинг": "dying light", "киберпанк": "cyberpunk", "хогвартс": "hogwarts",
    "бог войны": "god of war", "год оф вар": "god of war", "человек паук": "spider-man",
    "последний из нас": "last of us", "ласт оф ас": "last of us", "мафия": "mafia",
    "душа": "souls", "елден": "elden ring", "элден": "elden ring", "кольцо": "elden ring",
    "сталкер": "stalker", "метро": "metro", "фоллаут": "fallout", "фаллаут": "fallout",
    "ассасин": "assassin", "крид": "creed", "фар край": "far cry", "фаркрай": "far cry",
    "батлфилд": "battlefield", "колда": "call of duty", "кол оф дьюти": "call of duty",
    "фифа": "fc", "фифа 25": "fc 25", "еа фк": "fc 25",
    "форза": "forza", "хорайзон": "horizon", "зелда": "zelda", "марио": "mario",
    "сонс оф форест": "sons of the forest", "форест": "the forest", "лес": "the forest",
    "рафт": "raft", "портал": "portal", "майнкрафт": "minecraft",
    "террария": "terraria", "тетрис": "tetris", "варкрафт": "warcraft", "старкрафт": "starcraft",
    "ведьмак дикая охота": "witcher 3 wild hunt", "киберпанк 2077": "cyberpunk 2077",
    "данганронпа": "danganronpa", "данганронпа 2": "danganronpa 2", "данганронпа v3": "danganronpa v3",
    "данганронпа 3": "danganronpa v3", "данга": "danganronpa",
    # --- Ведьмак ---
    "ведьмак 2": "witcher 2", "ведьмак 1": "witcher", "ведьмак 3 дикая охота": "witcher 3 wild hunt",
    "гвинт": "gwent", "киберпанк 2": "cyberpunk 2", "ведьмак 4": "witcher 4",
    # --- Соулслайки ---
    "дарк соулс": "dark souls", "дарк соулз": "dark souls", "дарк соулс 3": "dark souls 3",
    "дарк соулс 2": "dark souls 2", "дс": "dark souls", "дс3": "dark souls 3",
    "секиро": "sekiro", "секиро тени умирают дважды": "sekiro", "бладборн": "bloodborne",
    "блудборн": "bloodborne", "армор кор": "armored core", "арморд кор": "armored core",
    "армор кор 6": "armored core 6", "нио": "nioh", "нио 2": "nioh 2", "лайс оф пи": "lies of p",
    "лордс оф зе фоллен": "lords of the fallen",
    # --- GTA / Rockstar ---
    "гта 5": "gta 5", "гта5": "gta 5", "gta 5": "gta 5", "гта 6": "gta 6", "gta 6": "gta 6",
    "гта 4": "gta 4", "гта сан": "gta san andreas", "сан андреас": "gta san andreas",
    "рдр": "red dead redemption", "рдр 2": "red dead redemption 2",
    "ред дед": "red dead redemption", "ред дед 2": "red dead redemption 2",
    "мафия 2": "mafia 2", "мафия 3": "mafia 3", "мафия 1": "mafia definitive edition",
    "буллы": "bully", "ла нойр": "l.a. noire",
    # --- Bethesda ---
    "скайрим 2": "skyrim", "обливион": "oblivion", "морровинд": "morrowind",
    "фоллаут 4": "fallout 4", "фоллаут 3": "fallout 3", "фоллаут 76": "fallout 76",
    "фоллаут нью вегас": "fallout new vegas", "нью вегас": "fallout new vegas",
    "старфилд": "starfield", "дум 2016": "doom 2016", "дум этернал": "doom eternal",
    "дум 3": "doom 3", "квикс": "quake", "вольфенштейн": "wolfenstein",
    # --- Ubisoft ---
    "ассасин крид": "assassin's creed", "ассасин 2": "assassin's creed 2",
    "ассасин 4": "assassin's creed 4", "ассасин блэк флаг": "assassin's creed black flag",
    "ассасин вальгалла": "assassin's creed valhalla", "вальгалла": "assassin's creed valhalla",
    "ассасин ориджинс": "assassin's creed origins", "ориджинс": "assassin's creed origins",
    "ассасин одессей": "assassin's creed odyssey", "одессей": "assassin's creed odyssey",
    "ассасин мираж": "assassin's creed mirage", "миража": "assassin's creed mirage",
    "фар край 3": "far cry 3", "фар край 4": "far cry 4", "фар край 5": "far cry 5",
    "фар край 6": "far cry 6", "примал": "far cry primal", "фар край нью давн": "far cry new dawn",
    "дивижн": "the division", "дивижн 2": "the division 2", "рэйнбоу сикс": "rainbow six",
    "р6": "rainbow six siege", "рэйнбоу сикс сидж": "rainbow six siege",
    "принс оф персия": "prince of persia", "принц персии": "prince of persia",
    "сплинтер селл": "splinter cell", "сплинтер": "splinter cell",
    "варч": "watch dogs", "вотч догс": "watch dogs", "вотч догс 2": "watch dogs 2",
    "вотч догс лиджн": "watch dogs legion", "легион": "watch dogs legion",
    "фор хонор": "for honor", "гоуст рикон": "ghost recon", "гоуст рекон": "ghost recon",
    "тхе крю": "the crew", "трекмания": "trackmania", "райман": "rayman",
    # --- Шутеры ---
    "колда": "call of duty", "колда мв2": "call of duty mw2", "мв2": "call of duty mw2",
    "мв3": "call of duty mw3", "варзона": "call of duty warzone", "варзоне": "call of duty warzone",
    "код": "call of duty", "батла": "battlefield", "батлфилд 1": "battlefield 1",
    "батлфилд 4": "battlefield 4", "батлфилд 2042": "battlefield 2042", "бф4": "battlefield 4",
    "апекс": "apex legends", "апекс легендс": "apex legends", "титанфолл": "titanfall",
    "титанфолл 2": "titanfall 2", "дестини": "destiny", "дестини 2": "destiny 2",
    "овервотч": "overwatch", "овервоч": "overwatch", "оверватч": "overwatch", "ов": "overwatch",
    "ов 2": "overwatch 2", "овервотч 2": "overwatch 2", "паладинс": "paladins",
    "валорaнт": "valorant", "валорант": "valorant", "кске": "cs2", "кс 2": "cs2",
    "кс го": "csgo", "ксго": "csgo", "контра": "counter-strike", "контер страйк": "counter-strike",
    "р6с": "rainbow six siege", "хитмен": "hitman", "хитман 3": "hitman 3",
    # --- Спорт / гонки ---
    "фифа 24": "fc 24", "фифа 23": "fifa 23", "фифа 22": "fifa 22", "фифа 21": "fifa 21",
    "фк 24": "fc 24", "фк 25": "fc 25", "еа фк 25": "fc 25", "нхл": "nhl", "нба": "nba 2k",
    "нба 2к": "nba 2k", "мадден": "madden", "уефа": "uefa", "ф1": "f1", "ф1 24": "f1 24",
    "скайфолл": "skyfall", "нид фор спид": "need for speed", "нфс": "need for speed",
    "нид фор спид мост вантед": "need for speed most wanted", "мост вантед": "need for speed most wanted",
    "нид фор спид хит": "need for speed heat", "хит нфс": "need for speed heat",
    "анбаунд": "need for speed unbound", "нфс анбаунд": "need for speed unbound",
    # --- RPG / стратегии ---
    "биошок": "bioshock", "биошок 2": "bioshock 2", "биошок инфинити": "bioshock infinite",
    "бордерлендс": "borderlands", "бордерлендс 2": "borderlands 2", "бордерлендс 3": "borderlands 3",
    "блур": "borderlands", "сивилизейшн": "civilization", "цива": "civilization",
    "цивилизация": "civilization", "цив 6": "civilization 6", "цива 6": "civilization 6",
    "ксеком": "xcom", "ксеном": "xcom", "ксеном 2": "xcom 2", "мафия дефинитив": "mafia definitive edition",
    # --- Persona / Atlus ---
    "персона": "persona", "персона 5": "persona 5", "персона 4": "persona 4", "персона 3": "persona 3",
    "персона 5 роял": "persona 5 royal", "п5р": "persona 5 royal", "п5": "persona 5",
    "соул хакерс": "soul hackers", "шх2": "soul hackers 2", "метафор": "metaphor refantazio",
    "метафора": "metaphor refantazio", "катсураги": "catherine", "кетрин": "catherine",
    "ярн": "yakuza", "якудза": "yakuza", "якудза 0": "yakuza 0", "якудза лайк э драгон": "yakuza like a dragon",
    "лайк э драгон": "yakuza like a dragon", "джаджмент": "judgment", "лондон": "yakuza",
    "сонік": "sonic", "соник": "sonic", "соник фронтьерс": "sonic frontiers",
    "тотал вар": "total war", "тотал вор": "total war", "тотал вар вархаммер": "total war warhammer",
    "тв вархаммер": "total war warhammer", "футбал менеджер": "football manager", "фм": "football manager",
    # --- Nintendo ---
    "зельда": "zelda", "зельда ботв": "zelda breath of the wild", "ботв": "zelda breath of the wild",
    "тотк": "zelda tears of the kingdom", "тиарс оф зе киндом": "zelda tears of the kingdom",
    "марио карт": "mario kart", "марио карт 8": "mario kart 8", "марио оддиси": "mario odyssey",
    "супер марио": "super mario", "супер марио брос": "super mario bros", "смб": "super mario bros",
    "покемон": "pokemon", "покемоны": "pokemon", "покемон го": "pokemon go",
    "покемон ск��рлет": "pokemon scarlet", "покемон вайолет": "pokemon violet",
    "свитч": "switch", "ниндтендо": "nintendo", "нинтендо": "nintendo", "свич": "switch",
    "сплэтун": "splatoon", "сплатун": "splatoon", "метроид": "metroid", "метроид дред": "metroid dread",
    "кирби": "kirby", "донки конг": "donkey kong", "дк": "donkey kong", "энимал кроссинг": "animal crossing",
    "анимал кроссинг": "animal crossing", "энимал кросинг": "animal crossing", "аnimal": "animal crossing",
    # --- PlayStation ---
    "анчартед": "uncharted", "анчартед 4": "uncharted 4", "анчартед 2": "uncharted 2",
    "анч": "uncharted", "бог войны 2018": "god of war 2018", "год оф вар рагнарок": "god of war ragnarok",
    "рагнарек": "god of war ragnarok", "рагнарок": "god of war ragnarok",
    "год оф вар 3": "god of war 3", "год 3": "god of war 3",
    "хорайзон зеро давн": "horizon zero dawn", "хорайзон 2": "horizon forbidden west",
    "запретный запад": "horizon forbidden west", "хорайзон форбидден вест": "horizon forbidden west",
    "ласт оф ас 2": "last of us 2", "ласт оф ас парт 2": "last of us part 2", "лоу 2": "last of us 2",
    "ласт оф ас 1": "last of us part 1", "ласт оф ас ремейк": "last of us part 1",
    "гоуст оф цушима": "ghost of tsushima", "гоуст": "ghost of tsushima", "цусима": "ghost of tsushima",
    "гоуст оф цусима": "ghost of tsushima", "спайдермен": "spider-man", "спайдер мен": "spider-man",
    "человек паук 2": "spider-man 2", "спайдермен 2": "spider-man 2", "человек-паук 2": "spider-man 2",
    "майлз моралес": "spider-man miles morales", "майлз": "spider-man miles morales",
    "ратчет и кланк": "ratchet and clank", "ратчет": "ratchet and clank",
    "бладборн 2": "bloodborne 2", "ретурнал": "returnal", "демонс соулс": "demon's souls",
    "демон соулс": "demon's souls", "сайлент хилл": "silent hill", "сайлент хилл 2": "silent hill 2",
    "дес стрендинг": "death stranding", "дес стрендинг 2": "death stranding 2", "дс2": "death stranding 2",
    "дэйс ган": "days gone", "дейс ган": "days gone", "инфэмос": "infamous", "инфамос": "infamous",
    "киллзоун": "killzone", "гран туризмо": "gran turismo", "гт": "gran turismo", "гт7": "gran turismo 7",
    # --- Capcom ---
    "резидент ивел": "resident evil", "резидент ивел 2": "resident evil 2", "ре2": "resident evil 2",
    "резидент ивел 4": "resident evil 4", "ре4": "resident evil 4", "резидент 4": "resident evil 4",
    "резидент ивел 7": "resident evil 7", "ре7": "resident evil 7", "резидент 7": "resident evil 7",
    "резидент ивел вилладж": "resident evil village", "вилладж": "resident evil village", "ре вилладж": "resident evil village",
    "ре3": "resident evil 3", "резидент ивел 3": "resident evil 3", "резидент 3": "resident evil 3",
    "девил мэй край": "devil may cry", "дмс": "devil may cry", "дмк": "devil may cry",
    "девил мей край 5": "devil may cry 5", "дмк 5": "devil may cry 5", "дмс 5": "devil may cry 5",
    "монстер хантер": "monster hunter", "мх": "monster hunter", "монстер хантер ворлд": "monster hunter world",
    "мх ворлд": "monster hunter world", "монстер хантер райз": "monster hunter rise", "мх райз": "monster hunter rise",
    "монстер хантер вайлдс": "monster hunter wilds", "мх вайлдс": "monster hunter wilds",
    "драгонс догма": "dragon's dogma", "драгон догма 2": "dragon's dogma 2", "дд2": "dragon's dogma 2",
    "онимьюша": "onimusha", "онемуша": "onimusha", "асура": "asura's wrath",
    # --- Файтинги ---
    "стрит файтер": "street fighter", "сф": "street fighter", "стрит файтер 6": "street fighter 6",
    "стф 6": "street fighter 6", "теккен": "tekken", "теккен 8": "tekken 8", "т8": "tekken 8",
    "соулкалибур": "soulcalibur", "соул калибур": "soulcalibur", "мортал комбат": "mortal kombat",
    "мк": "mortal kombat", "мк1": "mortal kombat 1", "мк 11": "mortal kombat 11", "мортал 11": "mortal kombat 11",
    "мортал комбат 1": "mortal kombat 1", "инджастис": "injustice", "инджастис 2": "injustice 2",
    # --- Final Fantasy / JRPG ---
    "финал фэнтези": "final fantasy", "фф": "final fantasy", "финалка": "final fantasy",
    "фф7": "final fantasy 7", "финал фэнтези 7": "final fantasy 7", "фф7 ремейк": "final fantasy 7 remake",
    "фф7 ребёрс": "final fantasy 7 rebirth", "фф16": "final fantasy 16", "финал фэнтези 16": "final fantasy 16",
    "фф14": "final fantasy 14", "фф15": "final fantasy 15", "фф10": "final fantasy 10",
    "кингдом хартс": "kingdom hearts", "кх": "kingdom hearts", "кингдом хартс 3": "kingdom hearts 3",
    "драгон квест": "dragon quest", "дк": "dragon quest", "драгон квест 11": "dragon quest 11",
    "ниер": "nier", "ниер автомата": "nier automata", "нир автомата": "nier automata",
    "ниер репликант": "nier replicant", "нир репликант": "nier replicant",
    "драгон квест билдерс": "dragon quest builders", "октопат": "octopath traveler",
    "октопат 2": "octopath traveler 2", "триангл": "triangle strategy", "бравелли": "bravely default",
    "паразит ив": "parasite eve", "кронос": "chrono trigger", "хроно": "chrono trigger",
    # --- Соулслайки (доп) ---
    "дарк соулс ремастер": "dark souls remastered", "дср": "dark souls remastered",
    "элден ринг шэдоу": "elden ring shadow of the erdtree", "эрдтри": "elden ring shadow of the erdtree",
    "арморд кор 6": "armored core 6", "ас6": "armored core 6", "аc6": "armored core 6",
    "теккен 7": "tekken 7", "т7": "tekken 7", "соул калибур 6": "soulcalibur 6", "ск6": "soulcalibur 6",
    # --- Аниме-игры ---
    "наруто": "naruto", "наруто шиппуден": "naruto shippuden", "наруто ултимейт": "naruto ultimate ninja storm",
    "ултимейт ниндзя шторм": "naruto ultimate ninja storm", "ултимейт ниндзя сторм": "naruto ultimate ninja storm",
    "джамп форс": "jump force", "дрэгон бол": "dragon ball", "дрэгон болл": "dragon ball",
    "драгон бол": "dragon ball", "драгонбол": "dragon ball", "дбз": "dragon ball z",
    "драгон болл з": "dragon ball z", "какарот": "dragon ball z kakarot",
    "драгон болл файтерз": "dragon ball fighterz", "дбфз": "dragon ball fighterz",
    "ван пис": "one piece", "уан пис": "one piece", "уанпис": "one piece",
    # --- Sonic / Yakuza ---
    "соник 2": "sonic 2", "соник адвенчер": "sonic adventure", "соник мэния": "sonic mania",
    "соник суперстарз": "sonic superstars", "соник и сотс": "sonic and the secret rings",
    "якудза 6": "yakuza 6", "якудза 7": "yakuza 7", "якудза кивами": "yakuza kiwami",
    "якудза кивами 2": "yakuza kiwami 2", "исчин": "yakuza ishin",
    "лост джаджмент": "lost judgment", "like a dragon gaiden": "like a dragon gaiden",
    "лайк э драгон гайден": "like a dragon gaiden", "лайк э драгон инфинит": "like a dragon infinite wealth",
    # --- Blizzard / стратегии ---
    "сталкрафт 2": "starcraft 2", "ст2": "starcraft 2", "старкрафт 2": "starcraft 2",
    "варкрафт 3": "warcraft 3", "вк3": "warcraft 3", "варкрафт 2": "warcraft 2",
    "ворлд оф варкрафт": "world of warcraft", "вов": "world of warcraft", "вов классик": "wow classic",
    "диабло": "diablo", "диабло 2": "diablo 2", "диабло 3": "diablo 3", "диабло 4": "diablo 4", "д3": "diablo 3",
    "д4": "diablo 4", "диабло 2 резурректед": "diablo 2 resurrected", "д2р": "diablo 2 resurrected",
    "овервотч классик": "overwatch classic", "пат оф экзайл": "path of exile", "поэ": "path of exile",
    "поэ 2": "path of exile 2", "пат оф экзайл 2": "path of exile 2", "грим давн": "grim dawn",
    "титан квест": "titan quest", "титан квест 2": "titan quest 2", "торчлайт": "torchlight",
    "аге оф эмпайрс": "age of empires", "аое": "age of empires", "аге оф эмпайрс 2": "age of empires 2",
    "аое 2": "age of empires 2", "аге оф эмпайрс 4": "age of empires 4", "аое 4": "age of empires 4",
    "комманд энд конкер": "command and conquer", "кнк": "command and conquer", "ред алерт": "red alert",
    "ред алерт 2": "red alert 2", "ра2": "red alert 2", "тиберриум": "tiberium",
    "анно": "anno", "anno 1800": "anno 1800", "анно 1800": "anno 1800", "анно 2070": "anno 2070",
    "ситис скаяйнс": "cities skylines", "сити скаяйнс": "cities skylines", "ситис 2": "cities skylines 2",
    "симс": "the sims", "симс 4": "the sims 4", "симс 5": "the sims 5", "симс 3": "the sims 3",
    "планет костер": "planet coaster", "планет коустер": "planet coaster", "планет зоо": "planet zoo",
    "фростпанк": "frostpunk", "фростпанк 2": "frostpunk 2", "тропико": "tropico", "тропико 6": "tropico 6",
    "сурвайвинг марс": "surviving mars", "сурвайвинг": "surviving mars",
    "энной": "anno", "факторио": "factorio", "факторио 2": "factorio 2", "сатисфактори": "satisfactory",
    "рифтвorld": "riftworld", "рифтворлд": "riftworld", "валхейм": "valheim", "валхейм 2": "valheim 2",
    "раст": "rust", "раст 2": "rust 2", "арк": "ark survival evolved", "арк сурвайвал": "ark survival evolved",
    "арк 2": "ark 2", "палворлд": "palworld", "пал ворлд": "palworld", "эншраудед": "enshrouded",
    # --- Хорроры / кооп ---
    "дед бай дейлайт": "dead by daylight", "дбд": "dead by daylight", "дед бай": "dead by daylight",
    "фрайдей 13": "friday the 13th", "фрайдэй": "friday the 13th", "лефт фор дед": "left 4 dead",
    "л4д": "left 4 dead", "лефт фор дед 2": "left 4 dead 2", "л4д2": "left 4 dead 2",
    "бэк 4 блад": "back 4 blood", "бэк фор блад": "back 4 blood", "б4б": "back 4 blood",
    "верминтайд": "vermintide", "верминтайд 2": "vermintide 2", "дарктайд": "darktide",
    "дип рок": "deep rock galactic", "дрг": "deep rock galactic", "хеллдайверс": "helldivers",
    "хеллдайверс 2": "helldivers 2", "хд2": "helldivers 2", "хеллдавэрс": "helldivers",
    "гта онлайн": "gta online", "гтао": "gta online", "рдр онлайн": "red dead online", "рдо": "red dead online",
    "зе форест": "the forest", "сонс оф зе форест": "sons of the forest",
    "соны фореста": "sons of the forest", "грин хелл": "green hell", "гринхелл": "green hell",
    "сабнавтика": "subnautica", "сабнотика": "subnautica", "сабнавтика 2": "subnautica 2",
    "сабнавтика бз": "subnautica below zero", "белоу зиро": "subnautica below zero",
    "ноу мэнс скай": "no man's sky", "номанс скай": "no man's sky", "номанскай": "no man's sky",
    "стардев вэлли": "stardew valley", "стардью": "stardew valley", "стардью вэлли": "stardew valley",
    "анимал кроссинг нью хорайзонс": "animal crossing new horizons", "аснх": "animal crossing new horizons",
    "гравити фоллс": "gravity falls", "гравити": "gravity falls", "хадес": "hades", "хадес 2": "hades 2",
    "дед селс": "dead cells", "дед селлс": "dead cells", "скул": "skul", "скул зе хироу": "skul the hero slayer",
    "инскрипшн": "inscryption", "инскрипшен": "inscryption", "слэй зе спайр": "slay the spire",
    "слэй": "slay the spire", "балатро": "balatro", "вампир сурвайворс": "vampire survivors",
    "вампир сурвайвор": "vampire survivors", "бротато": "brotato",
    # --- Minecraft / Roblox ---
    "майнкрафт 2": "minecraft 2", "майнкрафт данженс": "minecraft dungeons", "майн данженс": "minecraft dungeons",
    "майнкрафт легендс": "minecraft legends", "майн легендс": "minecraft legends",
    "роблокс": "roblox", "роблокс 2": "roblox 2", "роблокс студио": "roblox studio",
    "фортнайт": "fortnite", "форточка": "fortnite", "фортнайт 2": "fortnite 2",
    "апекс легенд": "apex legends", "колда варзона": "call of duty warzone",
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
