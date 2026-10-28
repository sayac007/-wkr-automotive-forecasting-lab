# R-Kalender und Deutschland-CSV herunterladen

[WKR_Kalender_2017-2026_R_und_CSV.zip](WKR_Kalender_2017-2026_R_und_CSV.zip)
(404,835 Bytes). Auf GitHub **Download raw file** wählen.

Version **1.2.0**, 2017–2026, alle **16 Bundesländer**, inklusive Halloween und
Valentinstag. Das Paket enthält R-Skript, vier erzeugte Kalender-CSVs,
Destatis-Bevölkerungseingabe, Herkunftsnachweis, Anleitung und SHA-256-Prüfsummen.

| Datei | Zeilen |
|---|---:|
| `calendar_daily.csv` | 58432 |
| `calendar_weekly.csv` | 8368 |
| `calendar_weekly_de.csv` | 523 |
| `datumlanderferienfeiertage.csv` | 48485 |

`calendar_weekly_de.csv` enthält die gewünschten Bevölkerungsgewichte als
Aggregationen: Ferien zählen nur an Öffnungstagen. Gewichtete Ferientage und
Anteile mit unterschiedlichen Nennern sind ausdrücklich getrennt.
Bevölkerungsstichtag ist fest der 31.12.2025, 83.467.117 Einwohner insgesamt.

Feiertage werden auf Bundeslandebene berücksichtigt; kommunale Sonderfälle
(insbesondere das teilweise bayerische Mariä Himmelfahrt) sind nicht vollständig
aufgelöst und werden als Scope in der CSV kenntlich gemacht.

Alle Nutzdateien und ZIP-CRC wurden geprüft. Erzeugte Kalender entsprechen
bytegleich dem ausgeführten Lauf; die acht Lauf-Ausgaben wurden offline
wiederholt und waren byte-identisch. 129 R-Regelprüfungen bestanden.
Quellenangaben und Ausführungsanleitung sind direkt im ZIP enthalten.
Keine manuelle Referenz, Roh-API-Antworten oder Zugangsdaten enthalten.
Eine neue Ausführung kann spätere Quellenrevisionen laden.

SHA-256, auch in der [Prüfsummendatei](WKR_Kalender_2017-2026_R_und_CSV.zip.sha256):

```text
bffd0b8d18e89c1bd9484888650ca9d3ab0439f37ee21b13e21f6644255d4279
```

[Fachregeln und Formeln](../docs/calendar_generator_r.md)
