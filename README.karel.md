# KAREL on the PMD 85

## KAREL3D (3D Karel v3.2 by Marian Vittek, Slovak)

No manual was found, the words below are the dictionary stored in the
tape (`strings simpmd/data/tapes/games-pmd1/KAREL3D`), their meaning is taken from the names and the error messages
(not tested in the game, the exact syntax is not known).

- Moves: `KROK` (step), `VLAVO-BOK`, `VPRAVO-BOK` (turn), `POLOZ` (put a mark), `ZDVIHNI` (pick it up)
- Conditions: `STENA`, `TEHLA`, `ZNACKA`, `VOLNO`, `PRAVDA`, `NEPRAVDA`, `JE`, `NIE`
- Control: `AK`, `TAK`, `INAK`, `KYM`, `UROB`, `KRAT`, `ROB` (also `*AK`, `*KYM`, `*UROB`)
- Own programs: `PRIKAZ` (new command), `PODMIENKA` (new condition), `ZACIATOK` ... `KONIEC`, `MIESTNOST`, `SLOVNIK`
- Program management: `ZRUS`, `TLAC`, `TLACM`, `ZMRAZ`, `ROZMRAZ`, `ZAPIS`, `CITAJ`, `ZAPISM`, `CITAJM` (probably save to and load from the tape)
- Other: `OZNAC`, `ODZNAC`, `PIP`, `RYCHLO`, `POMALY`

## KAREL (2D Karel, Czech)

 `KROK`, `VLEVO-VBOK`, `POLOZ`, `ZVEDNI`, `OPAKUJ`, `DOKUD`, `KDYZ`, `KONEC`; the game shows its own
buttons and asks for the commands in Czech.

See also the main [README](README.md).
