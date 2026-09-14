# Bilder in Version 0.4

Erstellt mit dem eingebauten OpenAI-Bildgenerierungswerkzeug, ohne CLI/API-Fallback. Die sechs Personen sind erfundene Spielfiguren für die fiktive Partei **Christen für Deutschland (CfD)**. Zufällige Namensähnlichkeiten mit realen Menschen sind nicht beabsichtigt. Reale Politiker erhalten durch diese Bilder keine erfundenen Gesichter.

## Dateien

- `assets/cfd-portraits.png`: ein Atlas aus sechs Porträts, drei Spalten und zwei Zeilen. Godot liest die einzelnen Bildbereiche über AtlasTexture, ohne zusätzliche Bildbearbeitung.
- `assets/parliament.png`: dekorative Parlamentsillustration für Übersicht und Verfassungsbereich.
- `assets/cfd-emblem.svg`: eigenes einfaches Vektorzeichen mit Kreuz, direkt im Projekt erstellt.

Die Bilddateien werden mit dem Spiel exportiert. Sie werden nicht zur Laufzeit heruntergeladen. Originalausgaben wurden in das Projekt kopiert.

## Verwendeter Porträt-Prompt

Create ONE game-ready portrait atlas for the political strategy game Staatskunst. Asset type stylized-concept, original painted editorial portraits of six entirely FICTIONAL German politicians. Exact layout: a seamless rectangular 3-column by 2-row grid of six equal SQUARE cells, overall 3:2 aspect ratio, ideally 1536x1024. No gutters, no borders, no text, no logos, no watermarks. Each cell contains exactly one centered shoulders-and-head portrait, complete head with space above, on identical dark navy blue studio background. Elegant realistic oil-painted strategy-game character art, restrained lighting, muted navy/gold/teal palette, distinct believable faces, formal timeless civilian clothing, no weapons, no uniforms. Cell order left-to-right top then bottom: 1 fictional Jan Mertens, male age 52, dark slightly grey hair, rectangular glasses, navy suit gold tie; 2 fictional Clara Winter, female age 45, short chestnut hair, cream blouse and dark blue jacket; 3 fictional Tobias Falk, male age 40, brown wavy hair, trimmed beard, charcoal suit green tie; 4 fictional Miriam Seidel, female age 48, dark shoulder-length curly hair, teal jacket; 5 fictional Lukas Ahrens, male age 57, silver hair, clean-shaven, dark suit burgundy tie; 6 fictional Elisabeth Voss, female age 60, silver bob, glasses, navy blazer and muted gold scarf. These are invented characters for a fictional party, not portraits of any existing people. Consistent framing and scale across all six cells. The game will use each square cell independently as a portrait texture.

## Verwendeter Parlaments-Prompt

Use case: stylized-concept. Create a single wide 3:1 cinematic game illustration banner for a German-language political grand strategy game, elegant hand-painted realism with dark navy, warm gold and teal palette. View from the rear gallery into a generic European parliamentary chamber with curved rows of blue seats, a central lectern, warm daylight and tall windows; distant faceless tiny silhouettes only, no identifiable real politicians. Architecture inspired by democratic civic buildings but do not copy a precise real photograph. Rich subtle texture and depth, restrained not triumphant. Keep the center and left visually quiet enough for game UI overlays. No text, no flags, no political logos, no watermarks, no emblems. This is decorative political decision-making artwork for an actual playable game interface, not a UI mockup.
