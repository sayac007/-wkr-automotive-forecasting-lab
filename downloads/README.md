# R-Kalender und CSV-Dateien herunterladen

[WKR_Kalender_2017-2026_R_und_CSV.zip](WKR_Kalender_2017-2026_R_und_CSV.zip)
(174.435 Bytes). Auf der GitHub-Dateiseite **Download raw file** wählen.

Das ZIP enthält das vollständige R-Skript, die drei tatsächlich erzeugten
CSV-Dateien, eine Startanleitung und SHA-256-Prüfsummen der vier Originaldateien.
Die Kalenderdateien und das Skript sind byte-identisch zum geprüften Lauf der
Regelversion 1.1.0. Keine Neuberechnung für dieses Paket.

- `calendar_daily.csv`: 25.564 Tageszeilen.
- `calendar_weekly.csv`: 3.661 regionale Wochenzeilen.
- `datumlanderferienfeiertage.csv`: 21.234 erzeugte Verkaufstagszeilen.
- Zeitraum 2017–2026; sieben WKR-Bundesländer; Halloween und Valentinstag enthalten.
- CSV: UTF-8, Semikolon als Trennzeichen, Dezimalkomma.

Nicht enthalten sind die manuelle Referenzdatei, API-Rohantworten, private Daten
oder Zugangsdaten. Quellenangaben und Hinweise zur Ferienabdeckung stehen auch
direkt im ZIP. Eine neue Skriptausführung lädt aktuelle Quellenstände und kann
später von diesem gespeicherten Kalenderstand abweichen.

SHA-256 des ZIP, zusätzlich in der [Prüfsummendatei](WKR_Kalender_2017-2026_R_und_CSV.zip.sha256):

```text
676aab380cd494ab11ae15a4c615567dc66fac2a369392959f679e8238767e68
```

Alle sechs ZIP-Einträge, CRC, ursprüngliche Datei-Hashes, CSV-Spalten und
Zeilenzahlen wurden geprüft. ZIP-Eintragszeitpunkte sind für reproduzierbare
Verpackung festgesetzt; sie bezeichnen keine Quellenabrufzeitpunkte.

[Fachregeln und vollständige Anleitung](../docs/calendar_generator_r.md)
