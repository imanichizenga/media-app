"""Bilingual demo copy. Every person, company and event is invented; places are only names on a map."""

# (sw, en) everywhere.
type T = tuple[str, str]

PLACES: list[T] = [
    ("Dodoma", "Dodoma"),
    ("Mwanza", "Mwanza"),
    ("Arusha", "Arusha"),
    ("Mbeya", "Mbeya"),
    ("Tanga", "Tanga"),
    ("Morogoro", "Morogoro"),
    ("Zanzibar", "Zanzibar"),
    ("Kigoma", "Kigoma"),
    ("Iringa", "Iringa"),
    ("Mtwara", "Mtwara"),
]
PEOPLE = [
    "Neema Kasanga",
    "Baraka Mwinuka",
    "Dkt. Zawadi Lema",
    "Juma Kitwana",
    "Profesa Anna Mushi",
    "Salome Ngowi",
    "Hamisi Mtoro",
    "Rehema Chuwa",
]
REPORTERS: list[tuple[str, T, str]] = [
    ("Asha Mwakalinga", ("Mhariri wa Siasa", "Politics Editor"), "siasa"),
    ("Daudi Kimaro", ("Mwandishi wa Biashara", "Business Reporter"), "biashara"),
    ("Fatma Abeid", ("Mwandishi wa Afya", "Health Reporter"), "afya"),
    ("Godfrey Sanga", ("Mwandishi wa Michezo", "Sports Reporter"), "michezo"),
    ("Happiness Mollel", ("Mwandishi wa Mazingira", "Environment Reporter"), "mazingira"),
    ("Ibrahim Pazi", ("Mwandishi wa Teknolojia", "Technology Reporter"), "teknolojia"),
    ("Joyce Macha", ("Mwandishi wa Elimu", "Education Reporter"), "elimu"),
    ("Khalid Omari", ("Mwandishi, Afrika Mashariki", "East Africa Correspondent"), "afrika-mashariki"),
    ("Lilian Tarimo", ("Mwandishi wa Burudani", "Culture Reporter"), "burudani"),
    ("Musa Nyerenda", ("Mwandishi wa Kilimo", "Farming Reporter"), "biashara"),
    ("Nuru Salehe", ("Mwandishi wa Maisha", "Lifestyle Reporter"), "maisha"),
    ("Omary Ligate", ("Mpiga picha", "Photojournalist"), "habari"),
    ("Pendo Shayo", ("Mwandishi wa Data", "Data Reporter"), "biashara"),
    ("Rashid Hamad", ("Mwandishi wa Dunia", "World Reporter"), "dunia"),
    ("Sophia Urio", ("Mhariri wa Maoni", "Opinion Editor"), "maoni"),
]
BIO: T = (
    "{name} ameandika habari za {beat} kwa zaidi ya miaka kumi, akisafiri katika mikoa mbalimbali ili kusikiliza "
    "watu wanaoguswa na maamuzi. Kabla ya kujiunga nasi alifanya kazi katika redio ya jamii.",
    "{name} has covered {beat} for more than ten years, travelling across the country to hear from the people "
    "decisions affect. Before joining us they worked in community radio.",
)

# slug → (names, icon, colour, scenes, children)
CATEGORIES: list[tuple[T, T, str, str, list[str], list[tuple[T, T] | tuple[T, T, T]]]] = [
    (("Habari", "News"), ("habari", "news"), "newspaper", "#0b5cad", ["city", "road"], []),
    (
        ("Siasa", "Politics"),
        ("siasa", "politics"),
        "landmark",
        "#5b3f9b",
        ["parliament", "city"],
        [
            (("Serikali", "Government"), ("serikali", "government")),
            (("Uchaguzi", "Elections"), ("uchaguzi", "elections")),
        ],
    ),
    (
        ("Biashara", "Business"),
        ("biashara", "business"),
        "trending-up",
        "#1f6b4a",
        ["chart", "market", "city"],
        [
            (("Kilimo", "Farming"), ("kilimo", "farming")),
            (("Fedha", "Finance"), ("fedha", "finance")),
            # A long name with the short one an editor gives it (R2).
            (
                ("Masoko ya Mitaji na Uwekezaji", "Capital Markets and Investment"),
                ("masoko-ya-mitaji", "capital-markets"),
                ("Masoko", "Markets"),
            ),
        ],
    ),
    (
        ("Michezo", "Sport"),
        ("michezo", "sport"),
        "trophy",
        "#a14a00",
        ["stadium"],
        [(("Soka", "Football"), ("soka", "football")), (("Riadha", "Athletics"), ("riadha", "athletics"))],
    ),
    (("Afya", "Health"), ("afya", "health"), "heart-pulse", "#0f6f78", ["clinic", "school"], []),
    (("Elimu", "Education"), ("elimu", "education"), "graduation-cap", "#7a4b12", ["school"], []),
    (("Teknolojia", "Technology"), ("teknolojia", "technology"), "cpu", "#3c4fa8", ["signal", "city"], []),
    (
        ("Burudani", "Culture"),
        ("burudani", "culture"),
        "music",
        "#8a2f6b",
        ["stage"],
        [(("Muziki", "Music"), ("muziki", "music")), (("Filamu", "Film"), ("filamu", "film"))],
    ),
    (
        ("Mazingira", "Environment"),
        ("mazingira", "environment"),
        "leaf",
        "#2f6b3a",
        ["savanna", "mountain", "dhow"],
        [],
    ),
    (
        ("Afrika Mashariki", "East Africa"),
        ("afrika-mashariki", "east-africa"),
        "globe",
        "#8a5a00",
        ["road", "mountain", "dhow"],
        [],
    ),
    (("Dunia", "World"), ("dunia", "world"), "earth", "#44546a", ["city", "dhow"], []),
    (
        ("Maoni", "Opinion"),
        ("maoni", "opinion"),
        "message-square-quote",
        "#6b4a3a",
        ["savanna", "school"],
        [],
    ),
]

HEADLINES: dict[str, list[T]] = {
    "habari": [
        (
            "Barabara mpya ya {p} yafunguliwa baada ya miaka mitatu ya ujenzi",
            "New {p} road opens after three years of building",
        ),
        (
            "Wakazi wa {p} wapata maji safi kwa mara ya kwanza",
            "Clean water reaches {p} homes for the first time",
        ),
        (
            "Mvua kubwa zasababisha msongamano katika barabara za {p}",
            "Heavy rain brings traffic to a halt in {p}",
        ),
    ],
    "siasa": [
        (
            "Baraza la {p} lapitisha bajeti ya huduma za jamii",
            "{p} council passes its community services budget",
        ),
        (
            "Vijana wa {p} wataka sauti zaidi katika mipango ya mkoa",
            "Young people in {p} ask for more say in regional plans",
        ),
        ("Wagombea {p} wakubaliana kuhusu kampeni za amani", "{p} candidates agree on a peaceful campaign"),
    ],
    "biashara": [
        (
            "Bei ya mahindi yashuka {p} baada ya mavuno mazuri",
            "Maize prices fall in {p} after a good harvest",
        ),
        (
            "Soko jipya la {p} lafungua milango kwa wafanyabiashara 800",
            "New {p} market opens its doors to 800 traders",
        ),
        ("Vikundi vya akiba {p} vyakuza biashara ndogo", "Savings groups in {p} help small businesses grow"),
    ],
    "michezo": [
        ("{p} washinda kwa bao la dakika za mwisho", "{p} win with a goal in the final minutes"),
        ("Mkimbiaji chipukizi wa {p} avunja rekodi ya mkoa", "Young {p} runner breaks the regional record"),
        ("Uwanja wa {p} wakarabatiwa kabla ya msimu mpya", "{p} stadium renovated ahead of the new season"),
    ],
    "afya": [
        (
            "Kliniki tembezi zafika vijiji vya mbali vya {p}",
            "Mobile clinics reach remote villages around {p}",
        ),
        ("Wauguzi wa {p} wapata mafunzo ya huduma za dharura", "{p} nurses trained in emergency care"),
        ("Kampeni ya chanjo {p} yavuka lengo lake", "{p} vaccination campaign passes its target"),
    ],
    "elimu": [
        (
            "Maktaba ya jamii {p} yafungua usiku kwa wanafunzi",
            "{p} community library opens at night for students",
        ),
        ("Walimu wa {p} wabuni vifaa vya sayansi kutoka taka", "{p} teachers build science kits from scrap"),
        ("Shule za {p} zaanza mpango wa chakula cha mchana", "{p} schools begin a lunch programme"),
    ],
    "teknolojia": [
        (
            "Wabunifu wa {p} watengeneza programu ya kufuatilia mabasi",
            "{p} developers build an app that tracks buses",
        ),
        ("Mtandao wa kasi wafika mitaa ya pembezoni ya {p}", "Fast internet reaches the edges of {p}"),
        ("Wakulima wa {p} watumia simu kujua hali ya udongo", "{p} farmers use phones to read their soil"),
    ],
    "burudani": [
        ("Tamasha la muziki {p} lavutia maelfu ya mashabiki", "{p} music festival draws thousands of fans"),
        (
            "Filamu fupi kutoka {p} yashinda tuzo ya kimataifa",
            "Short film from {p} wins an international award",
        ),
        ("Ngoma za asili zarudi kwenye jukwaa la {p}", "Traditional dance returns to the {p} stage"),
    ],
    "mazingira": [
        ("Wanakijiji wa {p} wapanda miti laki moja", "Villagers near {p} plant a hundred thousand trees"),
        ("Samaki waongezeka baada ya hifadhi ya ufuo {p}", "Fish return after a shoreline reserve near {p}"),
        ("Mradi wa jua wawasha taa za vijiji karibu na {p}", "Solar project lights up villages near {p}"),
    ],
    "afrika-mashariki": [
        ("Njia mpya ya reli kuunganisha {p} na bandari", "New rail link will connect {p} to the port"),
        ("Wafanyabiashara wa mipakani wakutana {p}", "Cross-border traders meet in {p}"),
    ],
    "dunia": [
        ("Wanasayansi wakutana {p} kujadili hali ya hewa", "Scientists meet in {p} to discuss the climate"),
        ("Miji duniani yaiga mfumo wa usafiri wa {p}", "Cities around the world borrow {p}'s transport idea"),
    ],
    "maoni": [
        ("Kwa nini {p} inahitaji nafasi zaidi za kijani", "Why {p} needs more green space"),
        ("Tuzungumze kuhusu afya ya akili kazini", "We should talk about mental health at work"),
        ("Lugha yetu ni daraja, si ukuta", "Our language is a bridge, not a wall"),
    ],
}
STANDFIRST: list[T] = [
    (
        "Wakazi wanasema mabadiliko hayo yamerahisisha maisha, ingawa bado kuna kazi ya kufanya.",
        "Residents say the change has made life easier, though there is still work to do.",
    ),
    (
        "Viongozi wa eneo hilo wanaeleza kilichofanyika, gharama zake na hatua zinazofuata.",
        "Local leaders explain what was done, what it cost and what comes next.",
    ),
    (
        "Tulitumia siku tatu na watu walio katikati ya habari hii.",
        "We spent three days with the people at the centre of this story.",
    ),
    (
        "Takwimu mpya zinaonyesha mwelekeo ambao wengi hawakuutarajia.",
        "New figures show a trend few people expected.",
    ),
]
PARAGRAPHS: list[T] = [
    (
        "Mapema asubuhi, kabla jua halijapanda, makundi ya watu yalikuwa yameshakusanyika. Wengi walikuja kwa miguu, wengine kwa baiskeli, wakitaka kuona kwa macho yao kile kilichozungumzwa kwa miezi mingi.",
        "Early in the morning, before the sun was up, small crowds had already gathered. Many came on foot and others by bicycle, wanting to see for themselves what had been talked about for months.",
    ),
    (
        "Kulingana na taarifa tulizoziona, kazi hiyo ilianza mwaka uliopita na ilikabiliwa na changamoto kadhaa, zikiwemo upungufu wa vifaa na mvua zilizochelewesha usafirishaji.",
        "According to documents we have seen, work began last year and met several obstacles, including a shortage of materials and rain that held up transport.",
    ),
    (
        "Hata hivyo, si kila mtu ana matumaini. Baadhi ya wakazi wanasema hawakushirikishwa vya kutosha na wanataka mikutano ya wazi kabla ya hatua inayofuata kuanza.",
        "Not everyone is hopeful. Some residents say they were not consulted enough and want open meetings before the next stage begins.",
    ),
    (
        "Wataalamu wanasema mafanikio ya kudumu yatategemea matengenezo ya mara kwa mara, uwazi wa matumizi ya fedha na ushirikiano kati ya jamii na viongozi.",
        "Experts say lasting success will depend on regular maintenance, openness about spending, and cooperation between the community and its leaders.",
    ),
    (
        "Katika kijiji jirani, hali ni tofauti. Huko, kikundi cha wanawake kilianzisha mpango wao miaka miwili iliyopita na sasa kinafundisha wengine.",
        "In a neighbouring village things look different. There, a women's group started its own scheme two years ago and now teaches others.",
    ),
    (
        "Takwimu za robo ya mwaka zinaonyesha ongezeko la asilimia kumi na mbili, kiwango cha juu zaidi tangu kumbukumbu zianze kuwekwa katika eneo hilo.",
        "Figures for the quarter show a rise of twelve per cent, the highest since records began in the area.",
    ),
    (
        "Kwa familia nyingi, jambo kubwa ni muda. Safari iliyokuwa ikichukua saa mbili sasa inachukua dakika ishirini, na watoto wanafika shuleni wakiwa hawajachoka.",
        "For many families the main thing is time. A journey of two hours now takes twenty minutes, and children reach school without being tired.",
    ),
    (
        "Hatua inayofuata itajadiliwa mwezi ujao. Mpaka wakati huo, wakazi wanasema wataendelea kufuatilia kwa karibu na kuuliza maswali.",
        "The next step will be discussed next month. Until then, residents say they will keep watching closely and asking questions.",
    ),
]
QUOTES: list[T] = [
    (
        "Hatukusubiri mtu atufanyie. Tulianza na tulichokuwa nacho.",
        "We did not wait for someone to do it for us. We started with what we had.",
    ),
    (
        "Kazi ya kweli inaanza sasa, baada ya kamera kuondoka.",
        "The real work begins now, after the cameras leave.",
    ),
    (
        "Watoto wangu hawatajua maisha yalivyokuwa magumu, na hilo linanifurahisha.",
        "My children will not know how hard it was, and that makes me happy.",
    ),
]
FACTS: list[T] = [
    ("Mradi ulianza mwaka uliopita", "The project began last year"),
    ("Kaya 4,200 zinanufaika", "4,200 households benefit"),
    ("Awamu ya pili itaanza Machi", "The second phase starts in March"),
]
LIVE: list[T] = [
    (
        "Milango imefunguliwa na watu wanaendelea kuingia kwa utaratibu.",
        "The doors are open and people are coming in calmly.",
    ),
    (
        "Msemaji anasema taarifa kamili itatolewa saa kumi jioni.",
        "A spokesperson says a full statement will follow at four.",
    ),
    (
        "Mvua nyepesi imeanza, lakini ratiba haijabadilika.",
        "Light rain has started, but the schedule stands.",
    ),
    (
        "Kikao cha kwanza kimemalizika. Waandishi wetu wako ukumbini.",
        "The first session has ended. Our reporters are in the hall.",
    ),
    (
        "Matokeo ya awali yanatarajiwa ndani ya dakika thelathini.",
        "First results are expected within thirty minutes.",
    ),
]
STORIES: list[tuple[T, str]] = [
    (("Reli ya Kati", "The Central Railway"), "reli-ya-kati"),
    (("Msimu wa Mavuno 2026", "Harvest Season 2026"), "mavuno-2026"),
    (("Maji kwa Wote", "Water for All"), "maji-kwa-wote"),
    (("Kombe la Mikoa", "The Regional Cup"), "kombe-la-mikoa"),
]
TAGS: list[T] = [
    ("Maji", "Water"),
    ("Barabara", "Roads"),
    ("Vijana", "Young people"),
    ("Wanawake", "Women"),
    ("Kilimo cha kisasa", "Modern farming"),
    ("Hali ya hewa", "Climate"),
    ("Elimu ya juu", "Higher education"),
    ("Ajira", "Jobs"),
    ("Utamaduni", "Culture"),
    ("Usafiri", "Transport"),
    ("Nishati ya jua", "Solar power"),
    ("Bajeti", "Budget"),
]
# Blender Foundation open films, Creative Commons Attribution.
YOUTUBE: list[tuple[str, str, int]] = [
    ("aqz-KE-bpKQ", "Big Buck Bunny", 635),
    ("eRsGyueVLvQ", "Sintel", 888),
    ("R6MlUcmOul8", "Tears of Steel", 734),
    ("WhWc3b3KhnY", "Spring", 464),
]

# What an editor writes under a live story's ring: at most 24 characters, two short lines (R3).
RAIL_TITLES: list[T] = [
    ("Bunge: Bajeti ya Elimu", "Budget debate"),
    ("Mafuriko Morogoro", "Morogoro floods"),
    ("Kinachoendelea Bungeni", "Parliament, live"),
]
