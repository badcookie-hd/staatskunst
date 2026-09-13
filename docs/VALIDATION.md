# Prüfung von Version 0.3.0

Godot 4.5.1 stable, Windows x64, 13. September 2026.

- **413 Simulationsprüfungen bestanden.** Reale Kandidatenlisten für alle 33 Land-/Epochenkombinationen, deutsche CDU/CSU und historisches Zentrum, getrennte Staatsämter, verbotene Parteien, demokratischer Alternativpfad, Kaiser-Rückkehr, Koalitionswechsel, Ressortzuweisung und Doppelämtersperre. Haushaltsgleichung, Besteuerung, Versorgung, Kredit/Tilgung, steigende Schuldzinsen, Sektorausbau, Handelsbilanz mit Erhaltung von Geld und Gütern, Lieferstopp bei Mangel und Krieg. Verzögerter Kriegssieg, Verluste/Kosten/Schäden, Wochenberichte, Kriegsarchiv, Waffenstillstand, Speichern/Laden und Ablehnung ungültiger Kandidatenreferenzen. Beide Epochen über 720 Tagesaufrufe sowie ein zusätzlicher autonomer KI-Durchlauf geprüft.
- **72 UI-Prüfungen bestanden.** Alle sechs Bereiche, Ministerwahl über echte Buttons, Bauauftrag, Zeitsteuerung, Menüs, Wechsel 1936/2026, 33 klickbare Ländermittelpunkte, Kriegsberichte und Layoutbreite bei 1440 × 900 sowie 1152 × 720. Gerenderten Kabinetts-, Wirtschafts- und Kriegsbildschirm visuell geprüft. Längere Inhalte sind scrollbar.
- **Zwei echte ENet-Prozesse für jede Epoche bestanden.** Host und Gast auf 127.0.0.1: Länderzuweisung, Szenarioübertragung, Steuergesetz, Koalitionsaufnahme, Ministerernennung, Wirtschaftssnapshot und Rückübertragung. Host-Staat unverändert; Gast kann die Host-Zeit nicht starten. Ungültiger Parteibefehl wird verworfen.
- **Windows-x64-Export erstellt und separat mit OpenGL gestartet**, Exit-Code 0. Parteidaten und neue Wirtschaftsmodule sind im eingebetteten Spielpaket enthalten.

Die Windows-Sandbox meldet einen Fehler beim Lesen des System-Zertifikatsspeichers. Das Spiel nutzt keine HTTPS-Verbindungen. Kein Gameplay- oder GDScript-Fehler in den abschließenden Läufen.

Die CI wiederholt Import, Simulation, UI und beide ENet-Durchläufe unter Linux. Deren Ergebnis ist im GitHub-Actions-Lauf des Release-Commits sichtbar.

Nicht praktisch geprüft: zwei physische Rechner, echte Router-Portweiterleitung, acht gleichzeitig verbundene Spieler und längerer Netzwerkbetrieb. Die Wirtschaft ist ein Spielmodell, nicht an amtlichen makroökonomischen Daten kalibriert. Die historische und moderne Parteienauswahl ist kuratiert, nicht vollständig.
