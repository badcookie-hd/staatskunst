# Spielillustrationen und Politikerfotos

Die ursprünglichen Illustrationen wurden mit dem eingebauten OpenAI-Bildgenerierungswerkzeug erstellt, ohne CLI/API-Fallback. Sechs Personen sind erfundene Spielfiguren für die fiktive Partei **Christen für Deutschland (CfD)**. Zufällige Namensähnlichkeiten mit realen Menschen sind nicht beabsichtigt.

Version 0.5 ergänzt 307 Fotos realer Personen. Dateien, Urheber und Lizenzen stehen in [PORTRAIT-CREDITS.md](PORTRAIT-CREDITS.md) und `data/portraits.json`. Sie werden unverändert als Wikimedia-Vorschaubilder mitgeliefert. Zwei GIF-Dateien (Hermann Obrecht und Eduard von Steiger) wurden ohne visuelle Bearbeitung verlustfrei als PNG gespeichert, damit Godot sie laden kann. WebP-Dateien bleiben WebP. Die Oberfläche skaliert die Aufnahmen mit erhaltenem Seitenverhältnis. Fotos sind keine MIT-Assets.

Für **Manuel Giménez Fernández** konnte keine passend lizenzierte Aufnahme gefunden werden. `assets/portraits/gimenez-illustration.png` ist deshalb eine neue, im Spiel gekennzeichnete KI-Interpretation. Sie ist **keine Archivaufnahme; historische Ähnlichkeit ist nicht gesichert**. Der reale Politiker wird dadurch nicht als fiktive Person eingeordnet. Die Originalausgabe des eingebauten Bildwerkzeugs wurde unverändert in das Projekt kopiert.

## Prompt für die ergänzte Spielillustration (0.5)

Use case: historical-scene. Asset type: single politician portrait for the Godot strategy game Staatskunst. Create an original, visibly hand-painted editorial portrait representing the historical Spanish politician and professor Manuel Giménez Fernández (1896–1968), CEDA, around 1936 at age 40. This will be explicitly labeled in-game as an AI-generated artistic interpretation, not an archival photograph or a verified likeness. Use your knowledge of this historical person where available. Head and shoulders, centered complete head, restrained thoughtful expression, period-appropriate civilian dark suit, white shirt and tie, simple dark navy background, muted warm ochre highlights, painterly brushwork and paper texture. Square image, no text, no party emblems, no flags, no watermarks, no other people. Avoid photographic realism; this must read as a game illustration.

## Dateien

- `assets/cfd-portraits.png`: ein Atlas aus sechs Porträts, drei Spalten und zwei Zeilen. Godot liest die einzelnen Bildbereiche über AtlasTexture, ohne zusätzliche Bildbearbeitung.
- `assets/parliament.png`: dekorative Parlamentsillustration für Übersicht und Verfassungsbereich.
- `assets/cfd-emblem.svg`: eigenes einfaches Vektorzeichen mit Kreuz, direkt im Projekt erstellt.

Die Bilddateien werden mit dem Spiel exportiert. Sie werden nicht zur Laufzeit heruntergeladen. Originalausgaben wurden in das Projekt kopiert.

## Verwendeter Porträt-Prompt

Create ONE game-ready portrait atlas for the political strategy game Staatskunst. Asset type stylized-concept, original painted editorial portraits of six entirely FICTIONAL German politicians. Exact layout: a seamless rectangular 3-column by 2-row grid of six equal SQUARE cells, overall 3:2 aspect ratio, ideally 1536x1024. No gutters, no borders, no text, no logos, no watermarks. Each cell contains exactly one centered shoulders-and-head portrait, complete head with space above, on identical dark navy blue studio background. Elegant realistic oil-painted strategy-game character art, restrained lighting, muted navy/gold/teal palette, distinct believable faces, formal timeless civilian clothing, no weapons, no uniforms. Cell order left-to-right top then bottom: 1 fictional Jan Mertens, male age 52, dark slightly grey hair, rectangular glasses, navy suit gold tie; 2 fictional Clara Winter, female age 45, short chestnut hair, cream blouse and dark blue jacket; 3 fictional Tobias Falk, male age 40, brown wavy hair, trimmed beard, charcoal suit green tie; 4 fictional Miriam Seidel, female age 48, dark shoulder-length curly hair, teal jacket; 5 fictional Lukas Ahrens, male age 57, silver hair, clean-shaven, dark suit burgundy tie; 6 fictional Elisabeth Voss, female age 60, silver bob, glasses, navy blazer and muted gold scarf. These are invented characters for a fictional party, not portraits of any existing people. Consistent framing and scale across all six cells. The game will use each square cell independently as a portrait texture.

## Verwendeter Parlaments-Prompt

Use case: stylized-concept. Create a single wide 3:1 cinematic game illustration banner for a German-language political grand strategy game, elegant hand-painted realism with dark navy, warm gold and teal palette. View from the rear gallery into a generic European parliamentary chamber with curved rows of blue seats, a central lectern, warm daylight and tall windows; distant faceless tiny silhouettes only, no identifiable real politicians. Architecture inspired by democratic civic buildings but do not copy a precise real photograph. Rich subtle texture and depth, restrained not triumphant. Keep the center and left visually quiet enough for game UI overlays. No text, no flags, no political logos, no watermarks, no emblems. This is decorative political decision-making artwork for an actual playable game interface, not a UI mockup.
