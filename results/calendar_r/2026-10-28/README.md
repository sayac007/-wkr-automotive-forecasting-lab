# R-Kalender: tatsächlicher Vollvergleich vom 28.10.2026

Neue Ausführung, kein wiederhergestelltes historisches Azure-Artefakt.
Basis: WKR `main` bei `071056370247ac58bfd29a67b47482bd3143617c`.
Regelversion 1.0.0 entspricht den im Gespräch präzisierten Einkaufs- und
Ferienregeln; siehe [Anleitung](../../../docs/calendar_generator_r.md).
Keine Umsätze erzeugt und keine Modelle geschätzt.

Dieser Nachweis bleibt als Ausführung der Regelversion **1.0.0** unverändert
erhalten. Das [damals ausgeführte Skript](https://github.com/sayac007/-wkr-automotive-forecasting-lab/blob/66ba9f02319230406ab34000cce092fd6fafb62b/R/generate_calendar_de.R)
ist über den Commit abrufbar. Die spätere Version 1.1.0 ergänzt Halloween und
Valentinstag; die unten stehenden Originalhashes beziehen sich auf Version 1.0.0.

## Ergebnis

| Kennzahl | Tatsächlicher Wert |
|---|---:|
| Zeitraum / Bundesländer | 2017-01-01–2026-12-31 / 7 |
| Vollständige Tageszeilen | 25.564 |
| Regionale Wochenzeilen, einschließlich gekennzeichneter Randwochen | 3.661 |
| Zeilen im erzeugten WKR-Verkaufstagschema | 21.234 |
| Zeilen in der manuellen Referenz | 21.199 |
| Gemeinsame Datum/Bundesland-Schlüssel | 21.181 |
| Nur in der manuellen Referenz / nur erzeugt | 18 / 53 |

| Merkmal, auf den gemeinsamen Schlüsseln | Abweichungen | Übereinstimmung |
|---|---:|---:|
| Ferien | 235 | 98,890515 % |
| Weihnachten | 42 | 99,801709 % |
| Karfreitag | 0 | 100 % |
| Silvester | 0 | 100 % |
| ErsterMai | 0 | 100 % |
| Pfingsten | 0 | 100 % |
| Himmelfahrt | 0 | 100 % |

Anzeigen sind gerundet; die JSON-Datei enthält die berechneten Raten ohne diese
Anzeigerundung. Übereinstimmung ist ein Referenzvergleich, kein Wahrheitsnachweis.
Insbesondere bezieht sie sich nur auf gemeinsame Schlüssel, nicht auf alle
Kalendertage.

**Für die Wochenbetrachtung:** Ein zusätzlicher Vergleich aggregiert die sechs
Feiertagsmerkmale in beiden Kalendern mit Maximum je Bundesland/ISO-Woche.
Auf allen **3.654 gemeinsamen Wochen** gibt es bei keinem dieser Merkmale eine
Abweichung, auch nicht bei Weihnachten. Die sieben nur im vollständigen Kalender
vorhandenen Wochenzeilen betreffen die angeschnittene erste Woche: 01.01.2017,
ein Sonntag, je Bundesland. Die Zahlen stehen in
[`weekly_event_comparison.csv`](weekly_event_comparison.csv).

Dieser Zusatzvergleich betrifft binäre Einkaufsmerkmale. Ein Ferienanteil mit
allen sieben Kalendertagen als Nenner ist nicht automatisch derselbe Index wie
ein Anteil nur über vorhandene Verkaufstage. Diese Nenner werden nicht vermischt.

## Was bei Ferien offenbleibt

Bei identischen aktuellen Quelleneingaben und denselben 21.181 gemeinsamen
Schlüsseln ergeben **unveränderte API-Schulferienflags** 467 Abweichungen;
die mit den beschriebenen Regeln erweiterten Ferienflags ergeben 235.
335 vorher abweichende Werte stimmen nun überein; **103 vorher übereinstimmende
Werte weichen mit den neuen Regeln ab**. Die Nettoverringerung ist daher kein
Beweis, dass jede neue Tagesmarkierung dem alten Handkalender entspricht.

Von den 235 verbleibenden Fällen hat die Referenz 19-mal 1 und der Generator 0;
216-mal ist es umgekehrt. Mögliche Ursachen müssen anhand der einzelnen Belege
geprüft werden: ursprüngliche Eintragung, lokale bewegliche Tage, Quellendefinition
oder die jetzt ausdrücklich vereinbarte Erweiterungsregel. Keine Ursache wurde
allein aus der Abweichung als bewiesen eingetragen.

| Bundesland | Ferienabweichungen |
|---|---:|
| Berlin | 33 |
| Brandenburg | 45 |
| Bremen | 33 |
| Niedersachsen | 50 |
| Nordrhein-Westfalen | 22 |
| Sachsen-Anhalt | 23 |
| Thüringen | 29 |

Die 42 Weihnachtsabweichungen betreffen in allen sieben Ländern jeweils den
23./24. Dezember 2019, 2025 und 2026. Der Handkalender markiert dort den 23., die
beschriebene letzte-Einkaufstag-Regel den 24. Dezember. 2023 liegt die Markierung
korrekt am Samstag, 23.12., in KW 51; bei einem Montag am 24.12. bleibt dieser
Montag Einkaufstag. Es wurde keine Jahresausnahme zum Erzwingen der Übereinstimmung
eingebaut.
Die beiden unterschiedlichen Weihnachtstage liegen in den genannten Jahren
jeweils in derselben ISO-Woche; daher entstehen daraus keine Wochenabweichungen.

## Quellenlücke sichtbar gemacht

Im ersten, separat aufbewahrten Quellenabruf waren alle 21 vollständigen
OpenHolidays-Feiertagsantworten für sieben Länder × 2017–2019 leer.
Das ist fehlende Quellenabdeckung, keine Abwesenheit gesetzlicher Feiertage.
Die [Abrufdiagnostik](openholidays_public_coverage.csv) enthält die tatsächlichen
URLs, Zeitpunkte, Datensatzanzahlen und SHA-256-Werte dieser Antworten.

Der fertige R-Generator verwendet deshalb für gesetzliche Feiertage über alle
Jahre Nager.Date, mit Länder-/Jahres-/Typ-/Bundeslandprüfung und einer Prüfung auf
die neun bundesweiten Standardfeiertage je Jahr. Schulferien bleiben aus
OpenHolidays. Die 70 vollständigen Schulferien-Jahresantworten 2017–2026 waren
nicht leer; dies belegt noch keine Vollständigkeit aller lokalen beweglichen Tage.
In diesem Lauf wurde keine zusätzliche lokale Ferien-Datei verwendet.

Die übrigen 18/53 Abdeckungsunterschiede stehen einzeln in
[`calendar_comparison_rows.csv`](calendar_comparison_rows.csv). Sie werden nicht
als stillschweigende Nullen behandelt oder aus der Prüfdokumentation entfernt.

## Erhaltene Nachweise und Wiederholung

- [`calendar_comparison_summary.json`](calendar_comparison_summary.json): originale Vergleichszahlen.
- [`calendar_comparison_mismatches.csv`](calendar_comparison_mismatches.csv): alle 277 abweichenden Merkmalswerte.
- [`calendar_comparison_rows.csv`](calendar_comparison_rows.csv): alle 71 nur einseitig vorhandenen Schlüssel.
- [`source_manifest.csv`](source_manifest.csv): 96 tatsächlich verwendete Antworten, Original-URLs, Abrufzeiten und MD5.
- [`manifest.json`](manifest.json): originale Laufmetadaten, Regel-/Softwareversionen und Ausgabedatei-Hashes.
- [`weekly_event_comparison.csv`](weekly_event_comparison.csv): separat berechneter Wochenvergleich der sechs Einkaufsmerkmale aus Referenz und erzeugter Wochenansicht.

Die vollständigen generierten Kalender und API-Originalbytes liegen im lokalen
Ausgabe-/Quellenarchiv, nicht in diesen kompakten Vergleichsnachweisen. Für einen
bytegleichen Replay wird dieses Quellenarchiv benötigt. Ein neuer Download kann
einen anderen Quellenstand liefern und ist dann eine neue Ausführung. Amtliche
und lokale Nachweise sowie die Quellenbedingungen bleiben separat zu prüfen;
OpenHolidays wird mit CC BY 4.0 attribuiert, Nager.Date als eigene Quelle benannt.

Tatsächlich geprüft mit R 4.5.1, jsonlite 2.0.0:

```sh
Rscript tests/test_calendar_de.R
Rscript R/generate_calendar_de.R --start-year 2017 --end-year 2026 --output NEW_RUN --source-cache CAPTURED_SOURCES --legacy data/raw/datumlanderferienfeiertage.csv
Rscript R/generate_calendar_de.R --start-year 2017 --end-year 2026 --output NEW_REPLAY --source-cache NEW_RUN/sources --legacy data/raw/datumlanderferienfeiertage.csv
```

Die Platzhalter stehen für die getrennten tatsächlichen lokalen Ausgabeordner.
60 Offline-Regelprüfungen bestanden. Der vollständige Lauf und Replay wurden ohne
Container-Netzwerkverbindung ausgeführt: **alle sechs Kalender- und
Vergleichsdateien byte-identisch**. Geänderte Cachebytes wurden abgewiesen;
fehlendes jsonlite führte vor der Ausgabeerzeugung zum Abbruch. Zusätzlich wurde
der vollständige CLI-Abruf für Berlin 2023 mit den endgültigen Quellen ausgeführt.
Die ursprüngliche manuelle Referenz wurde nicht überschrieben.

SHA-256 der unveränderten manuellen Referenz:

```text
13e21d56d39fa47e2beebe764a3fca9c1e6aefe35312fcbf1881033dd9608d05
```

SHA-256 des ausgeführten R-Skripts:

```text
0e7891a205fc122cd8ff64e7c64513921384fe93e119cbce8be095f5e672f57f
```

Keine Gleichheit zwischen neuer Definition, historischem Python-Generator und
manueller Referenz behauptet; keine Anpassung der bestehenden Umsatzmodelle.
