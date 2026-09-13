# Prüfung von Version 0.1.0

Geprüft mit Godot 4.5.1 stable unter Windows x64.

- **48 Simulationsprüfungen bestanden**: Ressourcen und Abklingzeiten, Bauzeiten, Projektlimit, Wahlkampf und Wahlausgang, Budget mit Regierungsbonus, Angreifer- und Verteidigersieg, Pattsituation, Waffenstillstand, Insolvenz, Ereignisse, Speichern/Laden, Zurückweisung beschädigter Daten, beide Siegbedingungen und 1.800 Tage KI-Simulation.
- **17 UI-Prüfungen bestanden**: Länderauswahl, Kartentreffer, vier Reiter und ihre Breiten, Bauauftrag per Button, Zeitfortschritt, Menü-Pause, LAN-Dialog und Hilfe.
- **Zwei tatsächliche ENet-Prozesse auf 127.0.0.1 bestanden**: Server und Client; Länderzuweisung, Welt-Snapshot, akzeptierter Client-Steuerbefehl, Rückübertragung des Ergebnisses, unveränderter Host-Staat und hosteigene Pause.
- **Vier gerenderte Screenshots visuell geprüft**, 1440 × 900; Karte, Kabinett, Politik, Wirtschaft und Ausland ohne horizontales Abschneiden. Längere Inhalte sind scrollbar.
- Windows-x64-Release mit eingebettetem Spielinhalt exportiert und separat gestartet.

Die Windows-Sandbox meldet beim Zugriff auf den Zertifikatsspeicher einen Umgebungsfehler; das Spiel nutzt keine HTTPS-Verbindungen. Bei der Prüfung außerhalb der Sandbox wird dieser Fehler nicht benötigt bzw. erwartet. Kein Gameplay- oder GDScript-Fehler in den abschließenden Läufen.

Nicht praktisch geprüft: zwei physische Rechner im LAN, reale Router-Portweiterleitung, acht gleichzeitig verbundene Spieler, Langzeit-Netzwerkbetrieb und andere Betriebssysteme. Der Loopback-Test belegt die lokale ENet-Verbindung, nicht die Konfiguration eines externen Routers. Die GitHub-CI prüft zusätzlich Linux, sobald der Workflow gelaufen ist.
