# Quellen und Szenariomodell

## Geografische Basis

- Natural Earth, `ne_110m_admin_0_countries.geojson`, abgerufen für Version 0.2.0: [Originaldatei](https://github.com/nvkelso/natural-earth-vector/blob/master/geojson/ne_110m_admin_0_countries.geojson).
- [Natural Earth Terms of Use](https://www.naturalearthdata.com/about/terms-of-use/): Public Domain.
- Aus der Weltkarte werden europäische Außenringe ausgeschnitten; außereuropäische Gebiete, kleine Inseln und Löcher werden teilweise weggelassen. Die Genauigkeit entspricht einer strategischen Übersicht, nicht einer Vermessungskarte.

## Historische Einordnung

- Deutsches Historisches Museum, [NS-Regime und Außenpolitik](https://www.dhm.de/lemo/kapitel/ns-regime/aussenpolitik): Deutschland unter nationalsozialistischer Diktatur, außenpolitische Entwicklung vor den Annexionen 1938/39.
- Deutsches Historisches Museum, [Chronik 1936](https://www.dhm.de/lemo/jahreschronik/1936): zeitliche Einordnung des Startjahres.
- Haus der Geschichte Österreich, [Juliabkommen 1936](https://hdgoe.at/juliabkommen): eigenständiger österreichischer Staat vor dem Anschluss 1938.
- Bundeszentrale für politische Bildung, [Beginn des Spanischen Bürgerkriegs](https://www.bpb.de/kurz-knapp/hintergrund-aktuell/231078/vor-80-jahren-beginn-des-spanischen-buergerkriegs/): Spanien startet am 1. Januar 1936 als Republik; es wird nicht bereits als Franco-Diktatur initialisiert.

Die Geometrien für Deutschland einschließlich Ostpreußen, Polen, die Tschechoslowakei einschließlich Karpatenruthenien und Italiens nordöstliches Grenzgebiet sind **eigene grobe Anpassungen** auf Natural-Earth-Basis. Es werden keine Grenzdateien aus dem Projekt historical-basemaps oder CShapes weitergegeben. Linien sind schematisch und nicht als präzise Grenzverläufe von 1936 zu verstehen. Danzig wird nicht als eigener Staat modelliert. Kolonien und internationale Organisationen sind nicht abgebildet.

Der 2026-Modus verwendet die heutigen Staatsgebiete der 17 ausgewählten europäischen Staaten. Hintergrundstaaten haben keine eigene Simulation. Es werden weder aktuelle Frontverläufe noch Besatzungszonen aus Echtzeitdaten übernommen.

## Politische und wirtschaftliche Abstraktion

Die politischen Strömungen, Unterstützungsanteile, Regierungsboni, Industrie, Geld, Stabilität, Qualität und Soldatenzahlen sind handbalancierte Spielwerte. Sie stammen nicht aus Volkswirtschafts-, Militär- oder Wahldaten. Sie sind keine Aussage über tatsächliche Regierungskoalitionen im Jahr 2026. Die vier Kategorien bündeln viele unterschiedliche Parteien; sie setzen deren Ideologien nicht gleich.

1936 starten Deutschland und Italien als Diktaturen sowie Österreich, Polen, Ungarn und Portugal als autoritäre Staaten. Dort gibt es keine freien Kampagnen oder automatischen Regierungswechsel, bis die Spieler eine demokratische Verfassung beschließen. Der weitere Verlauf folgt den Spielentscheidungen, nicht einem historischen Ereignisskript.

## Karten reproduzieren

Mit Node.js und der oben verlinkten Originaldatei im Repository-Verzeichnis:

```sh
node tools/build_maps.mjs /path/to/ne_110m_admin_0_countries.geojson
```

Das erzeugt `data/scenarios.json`. Die Grenzanpassungen sind direkt im Skript enthalten. Zur Laufzeit sind keine Downloads nötig.
