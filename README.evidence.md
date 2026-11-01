# EVIDENCE and EVIDEDIT on the PMD 85

EVIDENCE 1.0 is a small database program by Tomas Svec (Praha), tape SWK 8 of the CONSUL 2717 software set
(INCOTEX Brno). It is made of two programs:

- **EVIDEDIT** defines the form of a file (the names, types and places of the items) and saves an empty data file.
- **EVIDENCE** keeps the records: browse, edit, search, sort, save and load them, print them.

The manual (Czech, 19 pages, scan) is `pmd85doc_C2717-Evidence.zip` at
<https://pmd85.borik.net/?action=download&did=173>. This page is a summary of it with the notes for this emulator.
The example data files are `ZAJ.CIN`, `CLEN.ZAK`, `PROGRAMY` and `SEZNAM`.

## Start in the emulator

1. Open the games list (Up or [E] in the menu), category `Programy`, and start `EVIDENCE` (or `EVIDEDIT`).
   The tape is loaded by itself (`MGLD 00`, `JUMP 0000`).
2. EVIDENCE asks for **`Maximalni adresa`**. Press [Enter] (the default is `7FFF`; a smaller value, at least `4000`,
   leaves the memory above it free for a printer routine; digits `A-F` are capital letters).
3. It asks for **today's date**, `day.month.year` (`16.8.89`), parts separated by a dot or a space, then [Enter].
4. It asks for **the name of the file to load** from the tape (8 characters). Type one of the names below, or only
   spaces or dots to load the first file found.
5. Wait for `LOAD - Zapni magnetofon` and `Nahravam: <name>`. The file is read from the tape of the game.
   `Zadna data` and a key, the date of the last update and a key bring you to the main menu.

The tape of the game holds the program, EVIDEDIT and the four example files. The file name has **8 characters**
including the spaces: `ZAJ.CIN` + one space, `CLEN.ZAK`, `PROGRAMY`, ` SEZNAM ` (a space on both sides).
[F11] switches the capital letters (it also types a stray character, so press it before the name and clear the field).

What you save from EVIDENCE (`M`, `S`, `C`) or from EVIDEDIT goes to `saves/EVIDENCE` in the share directory
(see `TAPESAVE` in [doc/games.md](doc/games.md)); the next time EVIDENCE asks for a file that is not on the tape of the game,
it is read from there. A new save replaces the old one, so there is **one saved file** at a time.

## Keys

| Manual | PC keyboard |
|---|---|
| `EOL` (confirm an item) | [Enter] |
| `WRK` (finish editing) | [Insert] |
| `C-D` (accent: acute, caron, diaeresis, repeated) | [Delete] |
| `RCL` (restore the item) | Numpad [+] |
| `INS`, `DEL`, `CLEAR` | [Home], [Up], [PageUp] |
| `<-`, `->`, `HOME`, `END` | [Left], [Right], Numpad [5], [Down] |
| `I<-`, `I->` (previous, next item) | [End], [PageDown] |
| `F11` (capital / small letters) | [F11] |
| `F0`-`F10` (Czech letters) | [F1]-[F11] are K0-K10, so `F0` is [F1] |
| `STOP` (stop sorting) | [Ctrl], hold it |

Y and Z are swapped on the PMD 85 (see [doc/keyboard.md](doc/keyboard.md)). The shifted forms `IHOME`, `IEND`, `ICLEAR` of the manual are probably [Shift] with the key (not tested).

Czech letters: either one key (`F0`..`F10` give `U E S C R Z Y A I E U` with a caron or acute, in this order), or
[C-D] first (once an acute, twice a caron, three times a diaeresis) and then the letter, e.g. `C-D, A` is `A` with
an acute. The chosen accent is shown at the start of the information line and works for one letter.

The picture has the main part (48 x 13 characters) and the **information line** at the bottom: a blinking rectangle
(empty = small letters, `C` = capitals), the accent, and the number of the record, the number of records and the free memory.

## The main menu

```
Data MGF Tisk Smazat Pocet X-tridit ?
```

Press the capital letter: `D`, `M`, `T`, `S`, `P`, `X`. A blinking `?` means the program waits for a key.
The file is kept in memory (about 20 kB on a CONSUL 2717, about 300 simple records; with `7FFF` up to 28 kB).

### D - Data

[Left], [Right], [Home], [End] (here the PMD keys `<-`, `->`, `HOME`, `END`) show the previous, next,
first and last record. Only the records that match the search form are seen (see `Hledat`).

Submenu: **`Opravit ed.Radku ed.Dat Pridat Vlozit Smazat Hledat Konec`**

- **O (Opravit)**: edit the current record. A blinking cursor is on the first item.
  - Text items accept any characters, number and date items only digits, spaces and dots. A `Vycet` (choice) item
    changes with any key. A date must be one of `1.1.1989` (`01.01.1989`), `31.12.89` (year 1989), `01.01.0089`,
    `0.0.0000` or `........` (nothing); a wrong date does not let you leave the item.
  - In an item: [Left], [Right], [Home], [End] move the cursor; `CLEAR` clears the item (fills it with dots), `ICLEAR`
    (the shifted key) clears it from the cursor; `RCL` restores the item; `INS` inserts a space, `DEL` deletes
    the character under the cursor.
  - Between items: `I<-` and `I->` (previous, next), `IHOME`, `IEND` (first, last item),
    `EOL` (next item, on the last one it ends the editing), `WRK` (ends the editing at once). A record that does not fit
    into the memory is dropped with `Soubor je plny` and a beep.
- **P (Pridat)**: an empty form like the search form, fill in the item and leave it with `WRK` or `EOL` on the last
  item. The record is sorted in the right place when the file is sorted, otherwise it goes to the end.
- **V (Vlozit)**: the same, before the current record in an unsorted file.
- **S (Smazat)**: deletes the current record.
- **H (Hledat)**: the search form (see below). **K (Konec)**: back to the main menu.

**Searching**: the search form is a record that you fill in and leave with `WRK`. Only the records that match are
seen until you change the form (a message `Zadna data` says that no record matches; clear the form). All items
must match (AND). More words in one item (separated by a space or a dot) must all be in it, in any order. Accents and
case do not matter (`Tomas` = `TOMAS`). A number item is like a text. A date: an exact date matches only itself, `0`
in a part of the date matches anything (`0.8.89` is the whole month, `00.1.0000` every January), a year over 3000
is an interval of years: `0.0.3070` is `X.X.1930 - X.X.1970`, `0.0.7030` is `X.X.7030`.

### M - MGF (the tape)

Submenu: **`MGF Save Load Merge Hledat Check Jmeno Konec ?`** (`S`, `L`, `M`, `H`, `C`, `J`, `K`)

- **S (Save)**: asks `Cely soubor Vybrana data Konec`: `C` all records, `V` only the records of the search form
  (it lets you split a big file or keep a part, `M` merges two files again). Then "start the tape recorder and press a key".
  The file has the name set with `J` (or the name it was loaded with, shown at the top right).
- **L (Load)**: asks for the name; only spaces and dots load the first file. When the loading started, you cannot return
  to the menu. `Chyba nahravani !` and a key repeat the question. The date of the last update is shown.
- **M (Merge)**: joins the file in memory with a second file of the same form (the print and search forms are not read).
- **H (Hledat)**: reads the next header from the tape and shows it (and the extended header with the full 20 character name).
- **C (Check)**: like Load, but nothing is written to the memory.
- **J (Jmeno)**: the name of the file for `Save` (20 characters).

In the emulator the tape is the file `saves/EVIDENCE`, so the "tape recorder" needs no key from you.

### T - Tisk (printer)

`TISK Vybrane Aktualni Definice Konec ?`: print the selected records, the current record, or define the print form
(`Definice`: the number of characters on a line and the number of spaces before it, then a table of up to about 180
items inserted with `INS` as `1` name, `2` data, `3` spaces, `4` CR LF, `5` number of the record, `6` byte, `7` pause;
`DEL` removes the first shown, `Pocet` sets the numbers). The emulator has no printer, so the function is of no use here.

### S - Smazat, P - Pocet, X - X-tridit

- **S (Smazat)**: the manual does not describe it (probably it deletes the selected records; not tested).
- **P (Pocet)**: shows the number of the selected records.
- **X (X-tridit)**: sorts the file. Type the numbers of the items (the sort keys) with `EOL`, `000` ends the list
  (the sorting by `Prijmeni` and `Jmeno` is `2 EOL 1 EOL 000`; `Cekej` is shown). It runs from small to large, a long file
  takes minutes, [Ctrl] (`STOP`) stops it (hold it a while); the file is then in a "half sorted" state. `000` as the first
  key means no sorting. The table is saved with the file; `Load` reads it back, `Merge` keeps the old one.

## EVIDEDIT: a new file

1. Start `EVIDEDIT`. It asks for the **name of the file** (the form is named by it): type it on the first line, `EOL`.
   Then the name under which it will be saved to the tape (use capitals without accents).
2. For every item the program asks:
   - `Zadejte nazev N. polozky`: the name (up to 2 lines, 96 characters); end it with `@` if the data must start
     after the spaces at the end of the name (the `@` is not shown), then `EOL`.
   - the type `Text Vycet Cislo Datum ?`: `T`, `V`, `C` or `D`. For `V` you type the choices (`' 5'`, `'10'`, `'NE'`,
     `'..'` ends the list); the length is the length of the longest.
   - `Zadejte delku dat` (up to 96 characters), `Zadejte souradnici X` (0 to 47) and `Y` (0 to 12): the place of the
     first character of the **name** on the 48 x 13 screen. Each answer ends with `EOL`.
3. The menu **`Dalsi polozku Ubrat Save Tisk Konec ?`**: `D` next item, `U` removes the last item, `S` saves the empty
   file for EVIDENCE, `T` prints the list of items (the numbers are needed for sorting and printing), `K` ends (a jump to the monitor).

Plan the form on squared paper first (48 columns, 13 rows). Example "Clenska zakladna" (the file `CLEN.ZAK`):

| # | Name | Length | Type |
|---|---|---|---|
| 001 | Jmeno: | 12 | Text |
| 002 | Prijmeni | 17 | Text |
| 003 | Dat.nar. | 10 | Datum |
| 004 | Odbornost | 10 | Text |
| 005 | Clen od | 10 | Datum |
| 006 | Adresa | 41 | Text |
| 007 | Zamestnavatel | 34 | Text |
| 008-009 | Telefon:, Telefon (zam.): | 10 | Text |
| 010 | Ridicsky prukaz: | 10 | Text |
| 011 | Clenske prispevky: | 4 | Vycet (` 5`, `10`, `NE`) |
| 012 | Klubove prispevky: | 4 | Cislo |
| 013-015 | Ucast na akcich:, Poznamka, (no name) | 20, 39, 39 | Text |

Typed for the first items, with `EOL` after each comma:
`Jmeno @, T, 12, 0, 0`, then `D`, `Dat.nar @, D, 0, 1`.

After `S` (save) quit with `K` and start EVIDENCE: it loads the new empty file, then add records with `D`, `V`.

> The creation of a new file with EVIDEDIT in this emulator is not tested yet.

## Remarks

- The maximum address matters only if you leave the program with `RST` and start it again: then set it below `7E00`, where the monitor keeps its data.
- The tape file keeps the 34 byte gap between the files; do not remove it from a converted tape (EVIDENCE would not find the files).

See also the main [README](README.md) and [doc/games.md](doc/games.md).
