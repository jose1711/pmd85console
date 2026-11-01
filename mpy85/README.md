# mpy85 – podmnožina Pythonu (REPL) pro PMD 85-1

Interpreter v assembleru 8080 (`mpy.asm`, ~4,6 kB kódu), běží na PMD 85-1 s monitorem M1 (32 kB RAM).
Zdroj se interpretuje přímo z textu (bez bajtkódu), proto je pomalejší (fib(15) ≈ 7 M instrukcí).

## Jazyk
- typy: celé číslo 16 bit se znaménkem, řetězec, `None`, `True`/`False`, funkce
- operátory: `+ - * // / %` (`/` je celočíselné dělení, `//` a `%` mají sémantiku Pythonu, tj. floor),
  `== != < <= > >=`, `and or not` (s vyhodnocením nakrátko, vrací operand), unární `-`, `+`
- příkazy: `x = ...`, `x += -= *= //= %=`, `if/elif/else`, `while`, `for x in range(a[,b[,c]])`,
  `break`, `continue`, `pass`, `def f(a,b):` + `return`, rekurze (do hloubky cca 150), jednořádkové `if x: ...`
- vestavěné: `print len str int chr ord abs input peek poke`
- lokální proměnné ve funkci, globální jen ke čtení (bez `global`); výraz zadaný v REPL se vypíše
- identifikátory a klíčová slova nerozlišují velikost písmen, vstup se převádí na velká písmena
  (písmo PMD 85 nemá malá písmena); `\n` v řetězci = nový řádek
- Enter potvrzuje, Backspace/šipka vlevo maže, šipky nahoru/dolů listují historií (512 B, `6000–61FF`), víceřádkový blok (řádek končící `:`) se ukončí prázdným řádkem

## Paměť
`0100–13C7` kód, `1C00–2EFE` tabulka symbolů (11 B), `2F00` proměnné, `3000` argumenty volání,
`3400` blok z REPL, `3800` řádkový buffer, `3900–4FFF` těla funkcí, `5000–5FFF` halda řetězců (bez GC,
uvolní se po příkazu, který nic neuložil do globální proměnné), zásobník od `7E00` dolů.

## Nástroje
- `asm8080.py` – vlastní dvouprůchodový assembler (labely, EQU, ORG/DB/DW/DS, makra bez parametrů)
- `sim8080.py` – simulátor 8080 s hooky na adresách
- `t_mpy.py`, `t_cmp.py` – spuštění v simulátoru a porovnání výsledků s CPythonem (`python3 -I t_cmp.py`)
- `make_tape.py` – sestaví `mpy.asm` a vyrobí pásku `simpmd/data/tapes/games-pmd1/MPY85`

Kódy kláves monitoru M1 (zjištěno sondou): nahoru `81h`, dolů `87h`, Enter `89h`, šipka vlevo/Backspace `83h`, Delete `8Ah`.
