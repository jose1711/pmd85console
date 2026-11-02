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

## Rychlost
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
