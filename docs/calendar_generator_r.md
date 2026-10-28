# Deutscher Kalendergenerator in R

[`R/generate_calendar_de.R`](../R/generate_calendar_de.R) erzeugt einen Einkaufs-
und Ferienkalender nach den am 28.10.2026 beschriebenen fachlichen Regeln.
Regelversion 1.1.0 ergänzt Halloween und Valentinstag im selben R-Skript.
Das Skript benötigt weder HypoForge noch Agentic Analytics Studio und verändert
weder die manuelle Kalenderreferenz noch die Umsatzgeneratoren oder Modelle.

## Einkaufslogik

Markiert wird der **letzte mögliche Einkaufstag vor dem Feiertag**. Einkaufstage
sind Montag bis Samstag, ausgenommen gesetzliche Feiertage im jeweiligen
Bundesland. Öffnungszeiten und halbe Verkaufstage werden nicht modelliert.

| Fall | Markierung |
|---|---|
| Weihnachten 2023 | Samstag, 23.12. → **KW 51**, nicht die Weihnachtsfeiertagswoche KW 52 |
| 24.12. ist Montag, z. B. 2018 | Der Montag selbst bleibt Einkaufstag und wird markiert |
| 1. Mai ist Montag, z. B. 2023 | Samstag davor → Vorwoche des Feiertags |
| Karfreitag / Ostermontag | Letzter Einkaufstag vor jedem der beiden Feiertage; normalerweise Donnerstag und Samstag. Beide in `Karfreitag`, wie bisher in WKR. |
| Pfingstmontag / Himmelfahrt | Normalerweise Samstag / Mittwoch davor |
| Neujahr | Letzter Einkaufstag davor in `Silvester`; auch über die Jahresgrenze |
| Halloween, 31.10. | Letzter Einkaufstag davor: Montag 31.10.2022 → Samstag 29.10., KW 43 statt KW 44; Dienstag 31.10.2023 → Montag 30.10., KW 44 |
| Valentinstag, 14.02. | Letzter Einkaufstag davor: Montag 14.02.2022 → Samstag 12.02., KW 6 statt KW 7; Dienstag 14.02.2023 → Montag 13.02., KW 7 |

Die Spalten `Halloween` und `Valentinstag` stehen sowohl in der Tagesausgabe als
auch als binäre Wochenmerkmale zur Verfügung. Auch für diese Anlässe wird der
Anlasstag selbst nicht als Einkaufstag markiert. Sonntage und gesetzliche
Feiertage werden bei der Suche nach dem letzten möglichen Einkaufstag übersprungen.
Die Anlässe werden dadurch nicht selbst zu gesetzlichen Feiertagen.

Die beiden Weihnachtsfeiertage führen gewöhnlich zum selben letzten Einkaufstag.
`Einkauf_vor_Feiertag` umfasst zusätzlich alle aus der Quelle geladenen regionalen
gesetzlichen Feiertage. Die bekannten WKR-Spalten bleiben erhalten: Es sind
Einkaufsmerkmale, keine gesetzlichen Feiertagsflags.

## Ferienlogik

Veröffentlichte Schulferien und belegte zusätzliche schulfreie Tage werden
zuerst vereinigt; danach werden zusammenhängende Intervalle erweitert:

1. Beginn am Montag → vorherigen Samstag und Sonntag einbeziehen.
2. Beginn am Dienstag und der Montag davor ist gesetzlicher Feiertag →
   vorherigen Samstag, Sonntag und den Feiertagsmontag einbeziehen.
3. Ende am Freitag → folgenden Samstag einbeziehen, **sofern dieser kein
   gesetzlicher Feiertag ist**. Der Sonntag danach wird nicht zusätzlich als
   Ferientag eingeführt.

Ein belegter schulfreier Montag vor einem Feiertagsdienstag erzeugt damit die
beschriebene zusammenhängende freie Zeit ab Samstag. Ursprüngliche Schulferien,
Zusatzferien, gesetzliche Feiertage und erweiterte Ferientage bleiben getrennt
sichtbar.

## Ausführen

Getestete Laufzeit: R 4.5.1; für API/JSON zusätzlich `jsonlite` (getestet: 2.0.0).
Die Rechenregeln und Offline-Tests verwenden Base R. In R einmal installieren:

```r
install.packages("jsonlite", repos = "https://cloud.r-project.org")
```

Aus der Repository-Wurzel, z. B. in PowerShell:

```powershell
Rscript R/generate_calendar_de.R --start-year 2017 --end-year 2026 --output outputs/calendar-r-run1 --legacy data/raw/datumlanderferienfeiertage.csv
```

Falls nötig, den tatsächlichen Installationspfad zu `Rscript.exe` verwenden.
Das Ausgabeziel muss neu sein; bestehende Ergebnisse werden nicht überschrieben.
Fehlende Abhängigkeiten, ungültige Eingaben oder gescheiterte Abrufe führen zum
Abbruch. Ein unvollständiger Abruf ist kein erfolgreicher Ergebnislauf.

Standard sind die sieben bisherigen WKR-Bundesländer: Berlin, Brandenburg,
Bremen, Niedersachsen, Nordrhein-Westfalen, Sachsen-Anhalt, Thüringen.
Eine Teilmenge wählen: `--states DE-BE,DE-NI`. Ein Generator für alle 16
Bundesländer ist damit noch nicht implementiert.

Schulferienquelle: [OpenHolidays API](https://www.openholidaysapi.org/), CC BY 4.0.
Gesetzliche Feiertage: [Nager.Date API](https://date.nager.at/), mit Deutschland-,
Jahres-, Feiertagstyp- und Bundeslandprüfung. OpenHolidays lieferte im tatsächlichen
Abruf für 2017–2019 keine gesetzlichen Feiertage; leere Jahre dürfen nicht als
feiertagsfrei gelten. Deshalb verwendet dieses Skript für gesetzliche Feiertage
über den gesamten Zeitraum ausdrücklich Nager.Date. Die neun bundesweiten
Standardfeiertage müssen jedes Jahr enthalten sein; sonst Abbruch.

Es sind eigene Ableitungen durch Einkaufs- und Ferienerweiterungsregeln.
Die CC-BY-Angabe zu OpenHolidays wird nicht pauschal auf Nager.Date übertragen.
Originalantworten, URLs, Abrufzeiten und MD5-Prüfsummen werden unter `sources/`
gespeichert. MD5 dient der Kontrolle unveränderter Bytes, nicht als
Authentizitätsnachweis. Amtliche/KMK-Angaben bleiben die fachliche Prüfreferenz.
Der Kalender arbeitet auf Bundeslandebene; örtliche Sonderregeln innerhalb eines
Landes sind damit nicht vollständig abgebildet.

## Bewegliche Ferientage ergänzen

Die API belegt nicht die vollständige Erfassung aller lokalen beweglichen Tage.
Mit `--extra-school PFAD.csv` lassen sich belegte Tage ergänzen. UTF-8, **Komma**
als Trennzeichen, ISO-Daten und diese Pflichtspalten verwenden:

```csv
Bundesland,startDate,endDate,source
```

Je Zeile ein Intervall einschließlich beider Grenzen; bei einem einzelnen Tag
sind Start und Ende gleich. `source` enthält eine URL oder interne Belegreferenz.
Bundeslandnamen müssen genau passen. Nur für einzelne Schulen geltende Tage dürfen
nicht pauschal einem ganzen Bundesland zugeordnet werden; Schul-/Kreisauflösung
ist hier nicht implementiert. Die Eingabedatei wird unverändert im Ausgabeordner
gesichert. Interne Belege gehören nicht ins öffentliche Repository.

## Ausgaben und Aggregation

| Datei | Inhalt |
|---|---|
| `calendar_daily.csv` | Vollständiger Tageskalender je Bundesland einschließlich Sonntagen und Feiertagen |
| `datumlanderferienfeiertage.csv` | Bisherige WKR-Spalten plus `Halloween` und `Valentinstag`, ohne Sonntage und gesetzliche Feiertage; erweitertes `Ferien` |
| `calendar_weekly.csv` | ISO-Wochen je Bundesland; Wochenbeginn Montag, ISO-Jahr und KW getrennt |
| `sources/manifest.csv` und JSON-Originale | Tatsächlicher Quellenstand |
| `manifest.json` | Regelversion, Laufzeit, Quellen, Datei-Prüfsummen und ggf. Hash der manuellen Referenz |
| `calendar_comparison_summary.json`, `calendar_comparison_mismatches.csv` | Mit `--legacy`: Vergleich im gewählten Zeitraum und für die ausgewählten Bundesländer, einschließlich unterschiedlicher Zeilenabdeckung |
| `calendar_comparison_rows.csv` | Einzelne Datum/Bundesland-Schlüssel, die nur in der Referenz oder nur im erzeugten Kalender vorkommen |

`Schulferien` bedeutet: in der API aufgeführt; `Zusatzferien`: aus der separaten
Belegdatei. `Ferien` ist die erweiterte Vereinigungsmenge; beim Dienstagstart
gehört auch der überbrückende Feiertagsmontag dazu. `Feiertag` bezeichnet den
gesetzlichen Feiertag, `Verkaufstag` einen möglichen Einkaufstag. `Schulfrei`
umfasst Schulferien, Zusatzferien, Wochenenden und gesetzliche Feiertage.
Nicht gelistete lokale Tage bleiben eine Quellenlücke; eine Null beweist dort
keine vollständige schulische Anwesenheit.

Wochenmerkmale für Einkäufe verwenden **Maximum**: mindestens ein markierter Tag
in der Woche → 1. `Ferientage` ist dagegen eine Summe und
`Ferienanteil = Ferientage / Kalendertage`; ursprüngliche `Schulferientage` stehen
daneben. Angeschnittene Wochen an den Ausgabegrenzen erhalten die tatsächliche
Tageszahl und `VollstaendigeWoche=FALSE`. Ihr Anteil bezieht sich nur auf die
ausgegebenen Tage.

Es gibt keine stillschweigende bundesweite Gewichtung. Die bestehenden,
unterschiedlichen WKR-Gewichtungen in Umsatzgenerator und Prognosemodell bleiben
unverändert.
Fehlen die neuen Spalten in der Handreferenz, werden sie im Vergleich ausdrücklich
als `not_in_reference` ausgewiesen und nicht durch erfundene Nullen ergänzt.

## Offline wiederholen und testen

```powershell
Rscript R/generate_calendar_de.R --start-year 2017 --end-year 2026 --output outputs/calendar-r-replay --source-cache outputs/calendar-r-run1/sources --legacy data/raw/datumlanderferienfeiertage.csv
Rscript tests/test_calendar_de.R
```

Zeitraum und Bundesländer beim Replay identisch wählen. Eine verwendete
Zusatzferien-Datei erneut mit `--extra-school` angeben. Quellen-URLs und Hashes
müssen dem Cache entsprechen; sonst Abbruch. Es erfolgen keine neuen Downloads.
Bei gleichen Eingaben müssen die Daten-CSV-Dateien gleich bleiben; Zeitpunkte im
Ausführungsmanifest sind naturgemäß neu.

Die Offline-Tests decken die oben beschriebenen Einkaufs-/Ferienregeln,
Jahresgrenzen, Schaltjahr, ISO-Woche 53 sowie ungültige und unvollständige Eingaben
ab. Sie sind konstruierte Regelprüfungen, kein empirischer Datensatz.
Der [tatsächliche Vollvergleich 2017–2026 der Regelversion 1.0.0](../results/calendar_r/2026-10-28/README.md)
enthält alle verbleibenden Abweichungen und Zeilenunterschiede zur manuellen Referenz.
Der historische Vergleich mit 467 Ferien- und 42 Weihnachtsabweichungen steht in
[ADR 0003](decisions/0003-first-azure-ml-job.md). Ein neuer R-Lauf ist davon getrennt
zu bewerten; Abweichungen werden ausgegeben und nicht an die Referenz angepasst.
