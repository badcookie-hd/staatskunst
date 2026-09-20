# Weltatlas 0.7

Alle **242 Länder und Gebiete** der Natural-Earth-Karte besitzen eine aufrufbare Länderakte. Die Suche akzeptiert deutsche und englische Namen sowie Kartenkürzel. Kleinstaaten erhalten Mindest-Klickflächen und Punkte ab Zoomstufe 2. Referenzregionen bleiben von den 16 beziehungsweise 17 simulierten Kampagnenstaaten getrennt.

## Politische Angaben

Die Akten enthalten Staatsoberhäupter, Regierungsführung, Parteizugehörigkeiten aus den Personenquellen, Hauptstadt, Währung und eine ausdrücklich datierte Bevölkerungsschätzung. Staatsämter beziehen sich auf **1. Januar 1936** beziehungsweise **1. Januar 2026**. Sie entwickeln sich in den Referenzregionen nicht mit der Simulation weiter. Die bisherigen Kampagnenländer zeigen stattdessen ihre tatsächlich simulierte Regierung, Parteien und Politiker.

Stand des Quellenabrufs: 19. September 2026. **238 Regionen haben Angaben zur Staatsführung für 2026, 85 für 1936.** Die vier Regionen ohne zugeordnetes Staatsamt für 2026 sind Antarktika, Siachen, Westsahara und das Britische Territorium im Indischen Ozean. Dies ist kein vollständiges historisches Weltmodell. Insbesondere für ehemalige Kolonien und später entstandene Staaten bestehen 1936 Lücken. Fehlende Angaben werden sichtbar benannt; die 2026-Akte bleibt separat erreichbar. Eine fehlende Angabe bedeutet nicht, dass es damals keine Regierung gab.

Abhängige Gebiete ohne lokale Amtsangaben zeigen, soweit zuordenbar, ausdrücklich die Staatsführung ihres Bezugsstaats. Taiwan verweist 1936 auf Japan. Die Weltgeometrie bleibt eine moderne Referenzkarte; die bisherigen schematischen Kampagnengrenzen von 1936 liegen darüber. Umstrittene und abhängige Gebiete in Natural Earth sind keine Aussage über diplomatische Anerkennung.

Wikidata ist eine gemeinschaftlich gepflegte Datenbank. Der Import kombiniert datierte Länderangaben (`P35`, `P6`), Ämter (`P1906`, `P1313`, `P1308`) und datierte Amtsverläufe von Personen (`P39`, `P580`, `P582`). Die neueste zum Stichtag passende Amtszeit wird verwendet. Unvollständige oder widersprüchliche Quellenangaben können verbleiben. Bei Parteizugehörigkeiten fehlen teilweise vollständige Zeitangaben; dies ist kein vollständiges Parteienverzeichnis jedes Landes. Geografische Angaben stammen aus Natural Earth beziehungsweise Wikidata und sind keine aktuellen Wirtschaftswerte.

Die im Quellenabgleich erkannten Fehler für Nepal, Vanuatu, Sudan, Tschad, St. Vincent und Libyen wurden anhand amtlicher beziehungsweise UN-Veröffentlichungen in `data/world_overrides.json` korrigiert. Libyen zeigt die konkurrierenden Regierungen getrennt. Die jeweilige Akte verlinkt diese Belege zusätzlich:

- [Nepal: Staatsbesuch des Präsidenten im Januar 2026](https://www.mofa.go.jp/s_sa/sw/np/pageite_000001_00001.html), [Amt der Premierministerin](https://opmcm.gov.np/minister-detail/2/).
- [Vanuatu: Wahl von Jotham Napat](https://www.pmnec.gov.pg/prime-minister-marape-congratulates-hon-jotham-napat-on-election-as-vanuatus-new-prime-minister/).
- [Sudan: Vereidigung von Kamil Idris](https://www.suna.sd/posts/dr-kamil-idris-takes-oath-as-prime-minister-before).
- [Tschad: Regierungsbildung im Februar 2025](https://presidencetchad.org/actualites/formation-nouveau-gouvernement-37-membres/).
- [St. Vincent: Regierungsbildung im Dezember 2025](https://www.gov.vc/index.php/media-center/4080-government-of-st-vincent-and-the-grenadines-swearing-in-ceremony-of-new-cabinet-ministers-marks-a-new-chapter-of-governance).
- [Libyen: UNSMIL zu den konkurrierenden Regierungen](https://unsmil.unmissions.org/en/speeches-and-statements/transcript-srsg-hanna-tettahs-interview-with-al-hadath-on-22-may).

## Karte und Bilder

[Natural Earth 1:50m Countries](https://www.naturalearthdata.com/download/downloads/50m-cultural-vectors/) liefert detailliertere Küsten und Inseln als die bisherige 1:110m-Karte. Die Außenringe werden mit 0,035 Grad Toleranz vereinfacht. Dreiecksnetze werden einmal vorbereitet und wiederverwendet. Die Karte verwendet eine zusammenhängende Palette aus gedämpftem Blau-Grau und Grün; Gold markiert die Auswahl. Beschriftungen werden nach Größe priorisiert, an den Zoom angepasst und nur ohne Überschneidung gezeichnet. Vollständige Namen bleiben per Tooltip und Länderakte erreichbar.

[Wikidata strukturierte Daten: CC0](https://www.wikidata.org/wiki/Wikidata:Licensing), [Natural Earth: Public Domain](https://www.naturalearthdata.com/about/terms-of-use/). Die zusätzlichen Politikerfotos behalten ihre eigenen Lizenzen: [WORLD-PORTRAIT-CREDITS.md](WORLD-PORTRAIT-CREDITS.md). Fotos und Quelldaten sind vollständig offline enthalten. Wo kein frei verwendbares Foto erfasst wurde, steht ausdrücklich „Foto nicht verfügbar“ anstelle eines erfundenen Porträts.

## Erzeugung der Daten

Die mitgelieferten JSON-Dateien genügen zum Spielen und Bauen. Für eine neue Recherche ist Node.js mit Netzwerkzugang nötig; der Cache bleibt außerhalb des Repositorys. Live-Quellen können sich ändern, deshalb anschließend Amtszeiten, Sonderfälle und Bildnachweise prüfen.

```text
node tools/build_world.mjs /path/to/ne_50m_admin_0_countries.geojson
node tools/build_world_profiles.mjs /path/to/ne_50m_admin_0_countries.geojson /path/to/cache
node tools/fetch_world_offices.mjs 1936 /path/to/cache
node tools/fetch_world_offices.mjs 2026 /path/to/cache
node tools/build_world_profiles.mjs /path/to/ne_50m_admin_0_countries.geojson /path/to/cache
node tools/fetch_world_portraits.mjs /path/to/cache
```
