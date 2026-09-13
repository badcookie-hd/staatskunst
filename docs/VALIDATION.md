# Prüfung von Version 0.2.0

Geprüft mit Godot 4.5.1 stable unter Windows x64.

- **177 Simulationsprüfungen bestanden**: bisherige Ressourcen-, Wirtschafts-, Kriegs-, Wahl-, Projekt- und Save-Prüfungen, beide Siegbedingungen, 1.800 Tage KI-Simulation, beide Szenarien, symmetrische Grenzzugänge, autoritäre Systeme ohne freie Wahlen, demokratische Verfassungsreform, historische Länderauswahl, Technikstand sowie Szenariowechsel beim Speichern/Laden.
- **59 UI-Prüfungen bestanden**: Startfenster, beide Szenarioknöpfe, alle 33 Länder-Mittelpunkte, 1936/2026-Datum, historische Tschechoslowakei gegenüber moderner Slowakei, Weltwechsel, moderne Projekte, vier Reiter, Bauaufträge, Zeitsteuerung und Menüs.
- **Beide Szenarien mit zwei tatsächlichen ENet-Prozessen auf 127.0.0.1 bestanden**: Server und Client; Szenarioübertragung, Länderzuweisung, Welt-Snapshot, akzeptierter Client-Steuerbefehl, Rückübertragung des Ergebnisses, unveränderter Host-Staat und hosteigene Pause. Der Client startet dabei lokal mit 1936 und erhält im modernen Durchlauf das Szenario 2026 vom Host.
- **Gerenderte Karten für 1936 und 2026 visuell geprüft**, 1440 × 900; Länderumrisse, historische Grenzunterschiede, Beschriftung und Sidebar. Weitere Screenshots der vier Reiter sind im Ordner `docs` enthalten. Längere Inhalte sind scrollbar.
- Windows-x64-Release mit eingebettetem Spielinhalt exportiert und separat gestartet.

Die Windows-Sandbox meldet beim Zugriff auf den Zertifikatsspeicher einen Umgebungsfehler; das Spiel nutzt keine HTTPS-Verbindungen. Kein Gameplay- oder GDScript-Fehler in den abschließenden Läufen.

Nicht praktisch geprüft: zwei physische Rechner im LAN, reale Router-Portweiterleitung, acht gleichzeitig verbundene Spieler, Langzeit-Netzwerkbetrieb und andere Betriebssysteme. Der Loopback-Test belegt die lokale ENet-Verbindung, nicht die Konfiguration eines externen Routers. Die GitHub-CI prüft zusätzlich Linux, sobald der Workflow gelaufen ist.
