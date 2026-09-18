# Quellen und Szenariomodell

## Geografische Basis

- Natural Earth, `ne_110m_admin_0_countries.geojson`, abgerufen für Version 0.2.0: [Originaldatei](https://github.com/nvkelso/natural-earth-vector/blob/master/geojson/ne_110m_admin_0_countries.geojson).
- [Natural Earth Terms of Use](https://www.naturalearthdata.com/about/terms-of-use/): Public Domain.
- `data/world.json` enthält ab Version 0.6 alle 177 Referenzregionen einschließlich Antarktika. `tools/build_world.mjs` übernimmt Außenringe und deutsche Beschriftungen aus der Originaldatei, mit vier Nachkommastellen. Innenlöcher werden weggelassen; selbstberührende Ringe werden bei der Darstellung normalisiert. Die Genauigkeit entspricht einer strategischen Übersicht, nicht einer Vermessungskarte.
- Darüber liegen die bisherigen europäischen Kampagnengeometrien. Nur diese Länder sind spielbar. Die Welt außerhalb der Kampagnenländer verwendet moderne Referenzgrenzen und Namen auch 1936, keine historische globale Grenzrekonstruktion.

## Historische Einordnung

- Deutsches Historisches Museum, [NS-Regime und Außenpolitik](https://www.dhm.de/lemo/kapitel/ns-regime/aussenpolitik): Deutschland unter nationalsozialistischer Diktatur, außenpolitische Entwicklung vor den Annexionen 1938/39.
- Deutsches Historisches Museum, [Chronik 1936](https://www.dhm.de/lemo/jahreschronik/1936): zeitliche Einordnung des Startjahres.
- Haus der Geschichte Österreich, [Juliabkommen 1936](https://hdgoe.at/juliabkommen): eigenständiger österreichischer Staat vor dem Anschluss 1938.
- Bundeszentrale für politische Bildung, [Beginn des Spanischen Bürgerkriegs](https://www.bpb.de/kurz-knapp/hintergrund-aktuell/231078/vor-80-jahren-beginn-des-spanischen-buergerkriegs/): Spanien startet am 1. Januar 1936 als Republik; es wird nicht bereits als Franco-Diktatur initialisiert.

Die Geometrien für Deutschland einschließlich Ostpreußen, Polen, die Tschechoslowakei einschließlich Karpatenruthenien und Italiens nordöstliches Grenzgebiet sind **eigene grobe Anpassungen** auf Natural-Earth-Basis. Es werden keine Grenzdateien aus dem Projekt historical-basemaps oder CShapes weitergegeben. Linien sind schematisch und nicht als präzise Grenzverläufe von 1936 zu verstehen. Danzig wird nicht als eigener Staat modelliert. Kolonien und internationale Organisationen sind nicht abgebildet.

Der 2026-Modus verwendet die heutigen Staatsgebiete der 17 ausgewählten europäischen Staaten. Hintergrundstaaten haben keine eigene Simulation. Es werden weder aktuelle Frontverläufe noch Besatzungszonen aus Echtzeitdaten übernommen.

## Politische und wirtschaftliche Abstraktion

Die ursprünglichen Parteien und Personen sind kuratierte reale Identitäten; die separat markierte CfD ist eine fiktive Ergänzung ab Version 0.4. Die Auswahl ist nicht vollständig. Bezugspunkt ist der 1. Januar der Epoche; spätere Amtswechsel und Lebensläufe werden nicht nachgespielt. Parteianteile, Koalitionen, Ministerprofile, Wirtschaft und Armeen sind Modellwerte. Parteilosengruppen stellen reale Personen ohne behauptete Parteimitgliedschaft bereit. Startkoalitionen außerhalb Deutschlands sind stark vereinfacht. Deutschland verwendet vier zeitgenössische Ressortinhaber; sonst entstehen Spielkabinette aus verfügbaren Kandidaten, mit möglichen Vakanzen. Die generierten `sources`-Felder sind biografische Rechercheeinstiege, keine Belege für das gesamte jeweilige Parteiverzeichnis.

Dokumentierte Bezugspunkte:

- Deutscher Bundestag: [Zusammensetzung der Bundesregierung vom 6. Mai 2025](https://www.bundestag.de/dokumente/textarchiv/2025/kw19-de-kanzlerwahl-bundesregierung-1063886): Merz sowie Klingbeil, Reiche, Pistorius und Wadephul; Grundlage der deutschen Ressorts im Januar-2026-Start.
- Bundespräsident: [Frank-Walter Steinmeier](https://www.bundespraesident.de/DE/bundespraesident/frank-walter-steinmeier_node.html).
- Deutsches Historisches Museum: [Heinrich Brüning](https://www.dhm.de/lemo/biografie/heinrich-bruening), [Gleichschaltung](https://www.dhm.de/lemo/kapitel/ns-regime/etablierung/gleichschaltung): Zentrum und Unterdrückung anderer Parteien unter der NS-Diktatur.
- Deutsches Historisches Museum: [Hjalmar Schacht](https://www.dhm.de/lemo/biografie/hjalmar-schacht), [Schwerin von Krosigk](https://www.dhm.de/lemo/biografie/johann-ludwig-lutz-graf-von-schwerin-von-krosigk): Wirtschafts- und Finanzressort im historischen Start.
- Élysée: [Ernennung Sébastien Lecornus, 10. Oktober 2025](https://www.elysee.fr/emmanuel-macron/2025/10/10/nomination-de-sebastien-lecornu-premier-ministre): französischer Regierungschef zum modernen Szenariostart.
- Assemblée nationale: [Pierre Laval](https://www.assemblee-nationale.fr/gouv_parl/fiches_personnalites/Laval.asp): französischer Regierungschef Anfang 1936.
- Dänisches Staatsministerium: [Regierung Stauning III](https://stm.dk/regeringen/regeringer-siden-1848/regeringen-stauning-iii/): historische dänische Regierung.
- Norwegische Regierung: [Johan Nygaardsvold](https://www.regjeringen.no/no/om-regjeringa/tidligere-regjeringer-og-historie/historiske-artikler/embeter/statsminister-1814-/johan-nygaardsvold/id463389/).
- Schwedische Regierung: [Geschichte des Ministerpräsidentenamtes](https://www.regeringen.se/sa-styrs-sverige/statsministerambetet-i-sverige/).
- Schweizer SECO: [WEF-Treffen Januar 2026](https://www.seco-cooperation.admin.ch/en/newnsb/BB2yuZ1ufxIdCfGI4be_C): Einordnung damaliger Regierungsvertreter, unter anderem Parmelin, De Wever und Schoof.

Wilhelm II. als zurückkehrender Kaiser und Paul Löbe als Übergangspräsident sind ausdrücklich alternative Spielentwicklungen, keine historischen Ämter im Jahr 1936. Die demokratische Freischaltung verbotener Parteien abstrahiert Freilassungen, Rückkehr aus dem Exil und Wiederzulassungen.

1936 starten Deutschland und Italien als Diktaturen sowie Österreich, Polen, Ungarn und Portugal als autoritäre Staaten. Dort gibt es keine freien Kampagnen oder automatischen Regierungswechsel, bis die Spieler eine demokratische Verfassung beschließen. Der weitere Verlauf folgt den Spielentscheidungen, nicht einem historischen Ereignisskript.

## Karten reproduzieren

Mit Node.js und der oben verlinkten Originaldatei im Repository-Verzeichnis:

```sh
node tools/build_maps.mjs /path/to/ne_110m_admin_0_countries.geojson
```

Das erzeugt `data/scenarios.json`. Die Grenzanpassungen sind direkt im Skript enthalten. Zur Laufzeit sind keine Downloads nötig.

## Parteien reproduzieren

Im Repository-Verzeichnis: `node tools/build_politics.mjs`. Die kuratierten Identitäten stehen im Skript; der Generator erzeugt `data/politics.json`. Fachprofile sind bewusst Spielrollen. Es werden keine Personenfotos, Logos oder fremden Beschreibungstexte verteilt.

## Ergänzungen für Version 0.4

Die CfD (Christen für Deutschland) und ihre sechs Politiker sind ausdrücklich erfunden, in beiden Epochen als solche markiert. [Bilder und vollständige Prompts](ART.md).

Grundgesetz-Panel: [Artikel 1](https://www.gesetze-im-internet.de/gg/art_1.html), [Artikel 5](https://www.gesetze-im-internet.de/gg/art_5.html), [Artikel 20](https://www.gesetze-im-internet.de/gg/art_20.html), [Artikel 21](https://www.gesetze-im-internet.de/gg/art_21.html), [Artikel 38](https://www.gesetze-im-internet.de/gg/art_38.html) und [Artikel 79](https://www.gesetze-im-internet.de/gg/art_79.html), Gesetze im Internet. Die Ewigkeitsklausel wird nicht als regulär abschaltbare Gesetzesoption dargestellt. Der Machtpfad ist ein abstrakter, ausdrücklich verfassungswidriger Alternativverlauf, keine Tatsachenbehauptung über das zukünftige Verhalten einer realen Partei.

## Politikerfotos (Version 0.5)
307 Fotos aus Wikimedia Commons; eindeutige Identitäten über Wikipedia/Wikidata und manuell geprüfte Namensauflösung. [Einzelne Bildnachweise und Lizenzen](PORTRAIT-CREDITS.md). Eine gekennzeichnete KI-Interpretation für Manuel Giménez Fernández und sechs erfundene CfD-Gesichter: [ART.md](ART.md). D66-Kandidat Jan Paternotte korrigiert.
