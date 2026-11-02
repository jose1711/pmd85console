# doom85 – raycaster (styl Wolfenstein/Doom) pro PMD 85-1

Pohled z první osoby v assembleru 8080 (`doom.asm` + tabulky z `gen.py`, ~1,8 kB), pásku `DOOM85` sestaví `build.py`.

- pohled 48 sloupců (jeden bajt = 6 bodů) × 128 řádků, 1 paprsek na sloupec, střed obrazovky je videopaměť od řádku 64 (`D000h`)
- mapa 16×16 se generuje při každé hře na PMD 85 (úvodní obrazovka, semínko z doby čekání na mezerník, LFSR): bludiště 7×7 buněk
  (prohledávání do hloubky, `gen_maze`), 30 pokusů o proražení zdi, typy zdí 1–4 podle oblasti; zdi jsou celé buňky, takže nevzniknou diagonální
  mezery a vše je spojené (`t_maze.py` to ověří pro 48 semínek); příšery na náhodných buňkách daleko od startu, 64 úhlů otáčení, pohyb s kolizemi a klouzáním po zdi
- paprsek se posouvá po kroku 1/8 buňky; směr vychází z roviny kamery (`dir ± plane`), takže vzdálenost je rovnou kolmá
  (bez rybího oka) a počet kroků `n` je přímo index do tabulky výšky zdi. Krok se po `adi/aci` opravuje samomodifikací
  kódu (`mx1`, `mx2`, `my1`, `my2`) a počet kroků se počítá v SP (`dcx sp`, přerušení vypnuta)
- stínování podle vzdálenosti: 6 úrovní (bílá, šedá = atribut jasu bit 6, šachovnice bílá a šedá, řídká šedá), strop černý, podlaha má 4 pásy jasu podle řádku (tma u obzoru, světlejší blíž)
- klávesnice se čte přímo z matice (`out F4` = sloupec, `in F5` = řádky, 0 = stisknuto): šipky vlevo/vpravo otáčí,
  nahoru/dolů chodí

## Rychlost (po optimalizaci)
Stěny se kreslí rozdílově: pro každý sloupec se pamatuje výška a vzor z minulé snímky (`PWP`, `PSIG`) a překreslí se jen rozdíl (pásy nahoře a dole, kde se změnila hranice stěny, stropu a podlahy). Sloupce, kam minule sahaly příšery nebo zbraň (`DIRTY`), se kreslí celé. `t_delta.py` ověří, že rozdílové kreslení dá po každé snímce stejný obraz jako plné překreslení (87 snímků, 0 rozdílů). Viditelné příšery jsou v krátkém seznamu `SLIST`, `ustep` je z tabulky a nota hudby trvá 12 ms. Snímka za pohybu: asi 170 ms (z 227 ms), tj. 5,8 snímku za sekundu.

## Paprsky: interpolace (7,4 snímku/s)
Paprsek se vrhá jen pro sudé sloupce a sloupec 47 (v bludišti v průměru 27 z 48). Lichý sloupec se vypočítá ze sousedů, pokud trefili stejnou buňku a vzdálenosti se liší nejvýš o 4 (`n = (levý + pravý) / 2`), jinak se jeho paprsek vrhne. Proti plnému vrhání se na 400 náhodných pohledech nelišila buňka ani jednou, `n` se lišilo nejvýš o 2 (průměr 0,06). `t_speed.py` měří průměrnou snímku při skriptovaném pohybu: 162 ms -> 135 ms (hudba ve hře je od teď vypnutá, M ji zapne).

**Krok paprsku:** `lxi b,krok / dad b` s opraveným 16bitovým krokem (obě složky se zapisují do kódu přímo jako 16bitová čísla) místo `adi/aci` po bajtech a souřadnice Y je posunutá o `MAPHI*256`, takže ukazatel do mapy se skládá jen z `mov c,h / mov b,d`. Krok paprsku: 129 -> 89 cyklů, `cast` 38 -> 27 ms, snímka při pohybu 135 -> 128 ms (7,8 snímku/s). Zkoušeno: hrubší krok paprsku (x2 až x4) s doladěním jemnými kroky mění výsledek u 0,9 % až 2,7 % sloupců, proto se nepoužívá.

**Zkoušený a zahozený nápad: DDA.** Paprsek po hranicích buněk (tabulka převrácených hodnot a násobení čtvrtkvadráty pro počáteční vzdálenosti) sedí s referencí bit po bitu, ale na 8080 je pomalejší (180 ms proti 162 ms): příprava paprsku (dvě násobení 16x8) stojí víc, než ušetří kratší smyčka, protože průměrný paprsek v bludišti vrhá jen asi 21 kroků po 1/8 buňky.

## Rychlost (původní měření)
Sloupec = cca 3 100 T cyklů kreslení + paprsek (130 T cyklů na krok). Snímka v simulátoru: 200 až 340 tisíc T cyklů,
tj. 100 až 170 ms při 2 MHz (6 až 10 snímků za sekundu). Kreslí se přímo do viditelné videopaměti, proto je vidět
postupné vykreslování zleva doprava.

## Testy
`t_doom.py` spustí jednu snímku v simulátoru (`../mpy85/sim8080.py`) a porovná všech 6144 bajtů pohledu s referenčním
renderérem v Pythonu (`ref`), rozdíl musí být 0. Klávesy se simulují přes `Sim.inport[0xF5]`.

`t_maze.py` ověří 48 vygenerovaných bludišť (okraj, bez diagonálních mezer, souvislost, umístění příšer); generování trvá cca 170 ms.

## Náboje
Hráč má 30 nábojů. V bludišti leží 5 balíčků (malá bedna na podlaze, 10 nábojů, nejvýš 99): sebere je, když vstoupí do buňky balíčku. Když náboje dojdou, HUD ukáže BEZ NABOJOV a střelba se ignoruje. Balíčky jsou v poli objektů za příšerami (index >= 4, vlastní textura `TEX2` a poloviční velikost).

## Zvuk
Reproduktor je bit 2 portu C (`out F6`), program ho přepíná sám (čtvercová vlna, doba půlperiody = smyčky `dcr/jnz`). Efekty: výstřel (šum a pád tónu), zásah, smrt příšery (klesající tón), sebrání balíčku (dva vzestupné tóny), zranění, cvaknutí bez nábojů; úvodní obrazovka hraje melodii (32 not, `MUSTAB` z `gen.py`) a stejná melodie hraje ve hře po jedné notě (18 ms) na snímek, jen když neznělo něco jiného; klávesa M hudbu vypíná a zapíná. Znělky při prohře a výhře jsou v `JOVER` a `JWIN`.

## Zbraň
Pistole je bitmapa 8x10 buněk po 4 řádcích (`GUNT`, 0 = průhledné, `D` černý obrys, `G` šedá, `X` bílá) kreslená po sloupcích 20-27 hned za stěnou. Při výstřelu odskočí nahoru (`RECOIL` 3, 2, 1, 0 = 6, 3, 1, 0 řádků, `GOFFT`) a nad hlavní se na jednu snímku objeví záblesk (`FLT`). Sloupce zbraně se překreslují celé jen v snímku, kdy se její poloha změní (`gunprep`), jinak stačí zbraň překreslit přes rozdílově kreslenou stěnu.

## Příšery: AI
Příšera chodí po buňkách. V patrole zvolí na křižovatce náhodný směr (nevrací se, jen ve slepé uličce). Když je cesta k hráči kratší než 10 buněk, začne ho honit (vzdá to při 15) a v každé buňce zvolí souseda s menší vzdáleností z mapy `DMAP` (BFS od buňky hráče, `bfs`, počítá se jen při změně buňky hráče a jen do vzdálenosti 15, offset `F0` v řádcích mapy). Rychlost 9 (patrola) a 14 (honba) jednotek na snímek. Blízká honba ve vzdálenosti do 5 buněk vrčí (`sfx_growl`, nejvýš jednou za 14 snímků). `t_ai.py` ověří mapu vzdáleností proti BFS v Pythonu (0 chyb) a že příšery zůstávají v otevřených buňkách a chodí jen po sousedních.

## Výška pohledu (měření)
`VH` (výška pohledu v řádcích) je parametr: `DOOM_VH=96 python3 gen.py && python3 build.py`. Průměrná snímka při skriptovaném pohybu (`t_speed.py`, simulátor, 2 MHz): 128 řádků 130 ms, 112 řádků 129 ms, 96 řádků 128 ms, 80 řádků 126 ms, 64 řádky 124 ms. Rozdílové kreslení stěn spotřebuje málo času na řádky, takže zmenšení pohledu skoro nepomáhá. Zbytek (paprsky, sprity, režie sloupců) závisí na počtu sloupců, ne řádků. BFS prodlouží jednu snímku o asi 35 ms při každé změně buňky hráče (~ každých 16 snímků).

## Tvář v HUD (jako v Doomu)
Pod pohledem (řádky 194-241, sloupce 20-27) je tvář 48x48 bodů, kreslená po jednotlivých bodech s odstíny šedé: každý bajt (6 bodů vedle sebe) je bílý nebo ztlumený (bit 6 = šedá), v obou případech rozptýlený uspořádaným ditherem 4x4. Je jich 26 (`FACES`, 26 x 384 B): 15 klidných (3 výrazy na každou z 5 úrovní zdraví 100-81, 80-61, 60-41, 40-21, 20-0; výraz se mění náhodně po ~14 snímcích), 5 bolestí (při poklesu zdraví, 3 snímky), 5 úsměvů (po zabití příšery, 8 snímků) a 1 mrtvá (konec hry; při výhře úsměv). Kreslí se jen při změně. Text HUD je pod tváří.
`faces.py` bitmapy vyrobí: bez argumentů nakreslenou tvář (výchozí, v repozitáři jako `faces.bin`); `python3 -I faces.py --sheet plansa.png` z desky obrázků 5 řádků zdraví x výrazy (rozloží ji podle pozadí, vyrobí `faces_local.bin` a `faces_local.png`); `faces.py foto.jpg` z jedné fotky (stavy se odvodí). `gen.py` použije `faces_local.bin`, pokud existuje (jinak `faces.bin`; `DOOM_FACES=default` vynutí výchozí), proto lokální tváře z cizích obrázků (např. sprity z Doomu) nejsou v gitu (`.gitignore`) a páska v repozitáři je s nakreslenou tváří. Pak `python3 -I gen.py && python3 -I build.py ../simpmd/data/tapes/games-pmd1/DOOM85`.

## Obtížnost
Na titulní obrazovce se volí 5 úrovní (číslice 1-5, nebo šipky nahoru a dolů a mezerník; výchozí je 3): `DIFFT` obsahuje počet příšer (nejvýš 6, `NEN`), jejich zdraví, poškození za snímek při doteku, rychlost v patrole a v honbě, dosah honby (v buňkách, vzdá se o 5 dál), náboje na začátku a náboje v balíčku.

| úroveň | příšer | zdraví | poškození | rychlost | dosah | náboje | balíček |
|---|---|---|---|---|---|---|---|
| 1 lehká | 2 | 1 | 1 | 7 / 10 | 7 | 40 | 15 |
| 2 střední | 3 | 2 | 1 | 8 / 12 | 9 | 35 | 12 |
| 3 normální | 4 | 2 | 2 | 9 / 14 | 10 | 30 | 10 |
| 4 těžká | 6 | 3 | 3 | 10 / 15 | 12 | 25 | 8 |
| 5 noční můra | 6 | 4 | 4 | 12 / 16 | 14 | 20 | 6 |

`t_diff.py` ověří, že se parametry zvolené úrovně dostanou do hry (počet živých příšer, zdraví, náboje). Hráč se pohybuje 16 jednotek na snímek, takže na úrovni 5 jsou příšery v honbě stejně rychlé jako on.

## Paměť
Kód 5,6 kB (včetně textů), tabulky 12,2 kB (z toho tváře 10 kB), celkem 17,9 kB od adresy 0100h do 46CFh. Datová oblast 4F00h-5FFFh (proměnné, mapa a pole), zásobník bludiště a fronta BFS 6000h-6163h, zásobník procesoru od 7E00h dolů.

## Nůž a střelci
- **Nůž:** klávesa 1 (2 = pistole). Bez nábojů, dosah do 10 kroků paprsku (~1,25 buňky), zasáhne jen polovina úderů (náhodně), hlava 1 zásah; úder se kreslí jako bitmapa `KNT` s odskokem a zvukem (`sfx_stab` zásah, `sfx_swish` vedle).
- **Střelci:** příšery s příznakem v bitu 3 bytu směru (poslední `NSHOT` z aktivních, podle úrovně 0, 1, 2, 3, 4 a poškození střely 0, 3, 3, 4, 5, tabulka `DIFFS`). Mají-li přímou čáru k hráči (stejný řádek nebo sloupec, do 8 buněk, mezi nimi volné buňky: `losck`), stojí a každých 16 snímků vystřelí ohnivou kouli (`fireprj`, 3 sloty `NPR`, nejvýš 3 současně): střela letí po přímce 24 jednotek na snímek (`prjstep`), mizí o stěnu, zasáhne hráče, když je do ~0,4 buňky (poškození `PDMG`). Střelec a koule mají vlastní textury `TEX4` a `TEX3` (koule jsou poloviční jako balíčky).
- `t_weapons.py` ověří: střelec s přímou čarou zasáhne hráče (zdraví klesne o `PDMG`), zeď v čáře střelbu zastaví, nůž zabije blízkou příšeru bez spotřeby nábojů a vzdálená nedostane zásah.

## Ovládání na PMD 85
PMD 85 nemá samostatné šipky nahoru a dolů: pravý blok klávesnice má ← a → a nad a pod HOME klávesy DEL a END, které se v emulátorech mapují na šipky nahoru a dolů. Dopředu = DEL, dozadu = END, otáčení ← →, střelba mezerník, 1 nůž, 2 pistole, M hudba. Hra čte klávesnicovou matici přímo (`keys`: sloupec 12 = ←, 13 = DEL a END, 14 = →).
