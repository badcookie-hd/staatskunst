# Prüfung von Version 0.8.0

Godot 4.5.1 stable, Windows x64, 20. September 2026.

Version 0.8: **13 neue Kartografieprüfungen** mit echtem OpenGL bestanden: Offline-Relief, Hauptstadtdaten, unterschiedliche Nachbarfarben, korrekte UV-Zuordnung, Kartenhöhe über 70 % bei 1440 × 900 und 1152 × 720, kollisionsfreie Beschriftung bei drei Zoomstufen und Kabinett bei Mindestauflösung. Welt-, Europa-, Detail- und Kabinettsansicht gerendert und visuell geprüft. Zusätzlich 25 WASD-, 81 UI- und 32 Grafik-/Menüprüfungen erneut bestanden.

Die **4.293 Atlasprüfungen** wurden mit OpenGL wiederholt und bestanden. Die fertige Windows-EXE besteht die 13 Kartografieprüfungen ebenfalls mit OpenGL sowie die Ressourcenprüfung aller 710 Porträteinträge, Illustrationen und 242 Weltregionen/Länderakten. Keine fehlenden Ressourcen oder GDScript-Fehler. Die CI enthält jetzt auch die neue Kartografieprüfung.

Vorheriger Prüfstand und fortlaufende Regressionen:

- **25 neue Steuerungsprüfungen bestanden**, im Projekt und erneut direkt in der exportierten Windows-EXE. Alle WASD-Richtungen, Loslassen, gehaltene Tasten im Frame-Loop, gleiche Geschwindigkeit bei 30 und 144 FPS, normalisierte Diagonalen, Umschalt, gegensätzliche Tasten, Weltgrenzen und gesperrte Bewegung bei Hauptmenü, Pausemenü, Ländersuche, LAN-Dialog, LineEdit/TextEdit, ausgeblendeter Karte und inaktiver Anwendung. Fortsetzung nach Fokuswechsel geprüft.
- **32 Grafik- und 81 UI-Prüfungen erneut bestanden.** Fertigen Export separat mit OpenGL gestartet (Exit-Code 0) und alle 710 Porträteinträge, Illustrationen sowie 242 Weltregionen und Länderakten daraus geladen (0 Fehler).

Die folgenden umfassenden Prüfungen stammen aus Version 0.7.0; die CI führt sie auch für den neuen Release-Commit aus:

- **4.293 Atlasprüfungen bestanden.** Alle 242 Länder-/Gebietsakten in beiden Epochen, Quellenangaben, lesbare Personennamen, 402 zusätzliche Porträteinträge samt Texturen und Lizenzangaben, echte Klickauswahl der USA und von vier Kleinstaaten, Suchfilter und Auswahl mit Enter. Kollisionsfreie Ländernamen bei vier Zoomstufen und zwei Fenstergrößen. USA, Japan und die neue Weltansicht mit OpenGL gerendert und visuell geprüft. Historische Datenlücken und fehlende Fotos werden ausdrücklich ausgewiesen.

- **32 neue Grafik- und Menüprüfungen bestanden.** Hauptmenü, neue Kampagne, Pause und Fortsetzen, Einstellungen vor Spielbeginn, gespeicherte Kartenoptionen und Konfigurations-Roundtrip. 242 Weltregionen, Trefferprüfung auf fünf Kontinenten, Trennung von Referenzregionen und Kampagnenländern, mauszentrierter Zoom und erhaltene geografische Position beim Öffnen einer Akte. Lesbare Haushaltszahlen sowie passende Höhe von Hauptmenü, Szenarioauswahl, Pausemenü und Einstellungen bei 1152 × 720. Hauptmenü, Weltkarte, Kabinett, Wirtschaft und Einstellungen mit OpenGL gerendert und visuell geprüft.

- **1.419 zusätzliche Porträtprüfungen bestanden.** 314 eindeutige Personen aus beiden Epochen, ladbare Texturen, vorhandene Urheber und Quellen, alle Parteikarten und Kabinette in 33 Land-/Epochenkombinationen, keine leeren Bilder und Porträtklick mit passendem Staatsoberhaupt und Urhebernachweis. 307 Fotos, eine gekennzeichnete historische KI-Interpretation und sechs fiktive CfD-Gesichter. Gerenderte Kontaktbögen und aktualisierte Spielansichten geprüft. Die Bilddateien werden lokal geladen.

- **425 Simulationsprüfungen bestanden.** Kandidatenlisten für alle 33 Land-/Epochenkombinationen einschließlich der fiktiven CfD, deutsche CDU/CSU und historisches Zentrum, getrennte Staatsämter, verbotene Parteien, demokratischer Alternativpfad, Kaiser-Rückkehr, Koalitionswechsel, Ressortzuweisung und Doppelämtersperre. Haushaltsgleichung, Besteuerung, Versorgung, Kredit/Tilgung, steigende Schuldzinsen, Sektorausbau, Handelsbilanz mit Erhaltung von Geld und Gütern, Lieferstopp bei Mangel und Krieg. Verzögerter Kriegssieg, Verluste/Kosten/Schäden, Wochenberichte, Kriegsarchiv, Waffenstillstand, Speichern/Laden und Ablehnung ungültiger Kandidatenreferenzen. Beide Epochen über 720 Tagesaufrufe sowie ein zusätzlicher autonomer KI-Durchlauf geprüft.
- **41 zusätzliche Regressionen bestanden.** CfD-Regierungsübernahme und eigenes Kabinett; Diktatur ohne vorherige Machtübernahme gesperrt; Amtszeit und Stufenwartezeiten; Mindestzustimmung; AfD-Pfad; Abbruch durch Verfassungsverteidigung oder Regierungswechsel; demokratische Rückkehr; Speicherung einer Diktatur. Angezeigte Produktion entspricht der tatsächlichen Güterabrechnung; keine negativen Vorräte; reale Budgetauswirkung; Handelsraten im Saldo; Geldbestand und Tagesabschluss stimmen überein; Kündigung und Eigentumsprüfung von Verträgen; Projekte im Kontobuch; sichtbare Kreditaufnahme.
- **81 UI-Prüfungen bestanden.** Alle sieben Bereiche, Ministerwahl über echte Buttons, Bauauftrag, Zeitsteuerung, Menüs, Wechsel 1936/2026, 33 klickbare Ländermittelpunkte, Kriegsberichte und Layoutbreite bei 1440 × 900 sowie 1152 × 720. CfD-Regierung, Verfassungspfad und Bestätigungsdialog geprüft. Gerenderte Porträts, Kabinetts-, Wirtschafts-, Verfassungs- und Kriegsbildschirme visuell geprüft. Längere Inhalte sind scrollbar.
- **Zwei echte ENet-Prozesse für jede Epoche bestanden.** Host und Gast auf 127.0.0.1: Länderzuweisung, Szenarioübertragung, Steuergesetz, Koalitionsaufnahme, Ministerernennung, Wirtschaftssnapshot und Rückübertragung. Host-Staat unverändert; Gast kann die Host-Zeit nicht starten. Ungültige Partei- und Diktaturbefehle ohne Voraussetzungen werden verworfen.
- **Windows-x64-Export erstellt und separat mit OpenGL gestartet**, Exit-Code 0. Parteidaten, Verfassung, Wirtschaftsmodul und Bilder sind im eingebetteten Spielpaket enthalten.

Die Windows-Sandbox meldet einen Fehler beim Lesen des System-Zertifikatsspeichers. Das Spiel nutzt keine HTTPS-Verbindungen. Kein Gameplay- oder GDScript-Fehler in den abschließenden Läufen.

Die CI wiederholt Import, Simulation, UI, Tastatursteuerung, Grafik-/Menüprüfungen, Porträtprüfungen, Verfassungs-/Wirtschaftsregressionen und beide ENet-Durchläufe unter Linux. Deren Ergebnis ist im GitHub-Actions-Lauf des Release-Commits sichtbar.

Nicht praktisch geprüft: zwei physische Rechner, echte Router-Portweiterleitung, acht gleichzeitig verbundene Spieler und längerer Netzwerkbetrieb. Die Wirtschaft ist ein Spielmodell, nicht an amtlichen makroökonomischen Daten kalibriert. Die historische und moderne Parteienauswahl ist kuratiert, nicht vollständig.

Zusätzliche Prüfung des fertigen Windows-Exports: Kampagnen- und Atlasporträts, CfD-Atlas, Hauptmenüillustration, 242 Weltregionen und Länderakten direkt aus der exportierten EXE geladen, 0 fehlende Ressourcen. Separater OpenGL-Spielstart: Exit-Code 0.
