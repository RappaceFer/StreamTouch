package com.limelight.wowtouch;

import android.content.Context;
import android.preference.PreferenceManager;

import java.util.HashMap;
import java.util.Map;

/**
 * Streaming Touch, Made in Rappace : les textes du Grimoire dans les autres langues.
 * Le français et l'anglais sont écrits dans le code ; ici, pour chaque texte anglais : allemand, espagnol, italien,
 * portugais. Les autres langues reçoivent l'anglais.
 */
final class Traduction {
    private Traduction() {}

    /** Les langues proposées : valeur de la préférence Moonlight « list_languages » et nom affiché. */
    static final String[] CODES = {"default", "fr", "en", "de", "es", "it", "pt-BR"};
    static final String[] NOMS = {null, "Français", "English", "Deutsch", "Español", "Italiano", "Português"};

    /** La langue des textes : celle choisie dans l'appli, sinon celle du téléphone. */
    static String langue(Context c) {
        String choix = PreferenceManager.getDefaultSharedPreferences(c).getString("list_languages", "default");
        String l = choix.equals("default") ? c.getResources().getConfiguration().getLocales().get(0).getLanguage() : choix;
        if (l.startsWith("pt")) return "pt";
        return l.length() > 2 ? l.substring(0, 2) : l;
    }

    static String texte(Context c, String fr, String en) {
        String l = langue(c);
        if (l.equals("fr")) return fr;
        int i = l.equals("de") ? 0 : l.equals("es") ? 1 : l.equals("it") ? 2 : l.equals("pt") ? 3 : -1;
        if (i < 0) return en;
        String[] t = TABLE.get(en);
        return t != null ? t[i] : en;
    }

    private static final Map<String, String[]> TABLE = new HashMap<>();
    private static void m(String en, String de, String es, String it, String pt) { TABLE.put(en, new String[]{de, es, it, pt}); }

    static {
        // 1.3 : sous-menus, thèmes, statistiques, émaux des icônes.
        m("BACK", "ZURÜCK", "VOLVER", "INDIETRO", "VOLTAR");
        m("Touch mode", "Touch-Modus", "Modo táctil", "Modalità touch", "Modo tátil");
        m("Sticks and buttons on screen.", "Sticks und Tasten auf dem Bildschirm.", "Joysticks y botones en pantalla.",
                "Joystick e pulsanti sullo schermo.", "Joysticks e botões no ecrã.");
        m("When the game starts", "Beim Spielstart", "Al empezar la partida", "All'avvio del gioco", "Ao iniciar o jogo");
        m("Double tap on the screen", "Doppeltippen auf den Bildschirm", "Doble toque en la pantalla", "Doppio tocco sullo schermo",
                "Toque duplo no ecrã");
        m("Double-click", "Doppelklick", "Doble clic", "Doppio clic", "Duplo clique");
        m("Right-click", "Rechtsklick", "Clic derecho", "Clic destro", "Clique direito");
        m("Two single clicks", "Zwei einfache Klicks", "Dos clics simples", "Due clic semplici", "Dois cliques simples");
        m("Two quick taps in the same spot, anywhere outside the buttons.",
                "Zweimal schnell an dieselbe Stelle tippen, überall außerhalb der Tasten.",
                "Dos toques rápidos en el mismo sitio, en cualquier parte fuera de los botones.",
                "Due tocchi rapidi nello stesso punto, ovunque fuori dai pulsanti.",
                "Dois toques rápidos no mesmo sítio, em qualquer lado fora dos botões.");
        m("Like a mouse double-click: open, equip, confirm.", "Wie ein Doppelklick mit der Maus: öffnen, anlegen, bestätigen.",
                "Como un doble clic del ratón: abrir, equipar, confirmar.", "Come un doppio clic del mouse: aprire, equipaggiare, confermare.",
                "Como um duplo clique do rato: abrir, equipar, confirmar.");
        m("Like a long press: talk, loot, use, attack.", "Wie langes Drücken: sprechen, plündern, benutzen, angreifen.",
                "Como mantener pulsado: hablar, saquear, usar, atacar.", "Come tenere premuto: parlare, raccogliere, usare, attaccare.",
                "Como manter premido: falar, saquear, usar, atacar.");
        m("Nothing special: each tap stays a click.", "Nichts Besonderes: jedes Tippen bleibt ein Klick.",
                "Nada especial: cada toque sigue siendo un clic.", "Niente di speciale: ogni tocco resta un clic.",
                "Nada de especial: cada toque continua a ser um clique.");
        m("Button name", "Name der Taste", "Nombre del botón", "Nome del pulsante", "Nome do botão");
        m("Leave empty for the original name. For the icon only, untick the box below.",
                "Leer lassen für den ursprünglichen Namen. Nur das Symbol: Kästchen unten abwählen.",
                "Déjalo vacío para el nombre original. Para solo el icono, desmarca la casilla de abajo.",
                "Lascia vuoto per il nome originale. Per la sola icona, togli la spunta qui sotto.",
                "Deixa vazio para o nome original. Só para o ícone, desmarca a caixa abaixo.");
        m("Appearance", "Aussehen", "Apariencia", "Aspetto", "Aparência");
        m("Settings", "Einstellungen", "Ajustes", "Impostazioni", "Definições");
        m("Sticks", "Sticks", "Joysticks", "Joystick", "Joysticks");
        m("Size", "Größe", "Tamaño", "Dimensione", "Tamanho");
        m("Size and opacity", "Größe und Deckkraft", "Tamaño y opacidad", "Dimensione e opacità", "Tamanho e opacidade");
        m("Size, place, style and colours", "Größe, Platz, Stil und Farben", "Tamaño, sitio, estilo y colores",
                "Dimensione, posizione, stile e colori", "Tamanho, lugar, estilo e cores");
        m("Shape, colour, icon and icon colour.", "Form, Farbe, Symbol und Symbolfarbe.", "Forma, color, icono y color del icono.",
                "Forma, colore, icona e colore dell'icona.", "Forma, cor, ícone e cor do ícone.");
        m("Applied live by the phone. Each look uses a little battery.",
                "Live vom Handy angewendet. Jede Stimmung kostet etwas Akku.",
                "Aplicado en directo por el móvil. Cada ambiente gasta un poco de batería.",
                "Applicato dal vivo dal telefono. Ogni atmosfera consuma un po' di batteria.",
                "Aplicado em direto pelo telemóvel. Cada ambiente gasta um pouco de bateria.");
        m("Brightness, colours, sharpness, retro…", "Helligkeit, Farben, Schärfe, Retro…", "Brillo, colores, nitidez, retro…",
                "Luminosità, colori, nitidezza, retrò…", "Brilho, cores, nitidez, retro…");
        m("Light", "Licht", "Luz", "Luce", "Luz");
        m("Colours", "Farben", "Colores", "Colori", "Cores");
        m("Detail", "Details", "Detalle", "Dettagli", "Detalhe");
        m("Effects", "Effekte", "Efectos", "Effetti", "Efeitos");
        m("Super Resolution", "Super Resolution", "Superresolución", "Super risoluzione", "Super Resolução");
        m("Frame rate, latency, bitrate. Drag the panel to move it, tap it to shrink it.",
                "Bildrate, Latenz, Bitrate. Panel ziehen zum Verschieben, antippen zum Verkleinern.",
                "Imágenes por segundo, retardo, tasa de bits. Arrastra el panel para moverlo, tócalo para reducirlo.",
                "Fotogrammi al secondo, ritardo, bitrate. Trascina il pannello per spostarlo, toccalo per ridurlo.",
                "Imagens por segundo, atraso, débito. Arrasta o painel para o mover, toca nele para o reduzir.");
        m("Put the statistics back top left", "Statistiken wieder oben links", "Volver a poner las estadísticas arriba a la izquierda",
                "Rimetti le statistiche in alto a sinistra", "Repor as estatísticas no canto superior esquerdo");
        m("Your sliders, in “My look”.", "Deine Regler, in „Meine Einstellung“.", "Tus controles, en «Mi ajuste».",
                "I tuoi cursori, in «La mia regolazione».", "Os teus cursores, em «O meu ajuste».");
        m("Theme", "Design", "Tema", "Tema", "Tema");
        m("Changes the Grimoire, buttons, keyboard and windows.", "Ändert Grimoire, Tasten, Tastatur und Fenster.",
                "Cambia el Grimorio, los botones, el teclado y las ventanas.", "Cambia il Grimorio, i pulsanti, la tastiera e le finestre.",
                "Muda o Grimório, os botões, o teclado e as janelas.");
        m("Leather & gold", "Leder und Gold", "Cuero y oro", "Cuoio e oro", "Couro e ouro");
        m("Royal", "Königlich", "Real", "Reale", "Real");
        m("Arcane", "Arkan", "Arcano", "Arcano", "Arcano");
        m("Frost", "Frost", "Escarcha", "Gelo", "Geada");
        m("Ember", "Glut", "Brasa", "Brace", "Brasa");
        m("Grove", "Hain", "Arboleda", "Bosco", "Bosque");
        m("Shadow", "Schatten", "Sombra", "Ombra", "Sombra");
        m("Royal blood", "Königsblut", "Sangre real", "Sangue reale", "Sangue real");
        m("Icon colour", "Symbolfarbe", "Color del icono", "Colore dell'icona", "Cor do ícone");
        m("Gold", "Gold", "Oro", "Oro", "Ouro");
        m("Silver", "Silber", "Plata", "Argento", "Prata");
        m("Fire", "Feuer", "Fuego", "Fuoco", "Fogo");
        m("Nature", "Natur", "Naturaleza", "Natura", "Natureza");
        m("Holy", "Heilig", "Sagrado", "Sacro", "Sagrado");
        m("Blood", "Blut", "Sangre", "Sangue", "Sangue");
        m("Poison", "Gift", "Veneno", "Veleno", "Veneno");
        m("Ocean", "Ozean", "Océano", "Oceano", "Oceano");
        m("Rainbow", "Regenbogen", "Arcoíris", "Arcobaleno", "Arco-íris");
        m("Mode", "Modus", "Modo", "Modalità", "Modo");
        m("Controller mode", "Controller-Modus", "Modo mando", "Modalità controller", "Modo comando");
        m("Touch controls hidden: a real controller plays.", "Touch-Steuerung ausgeblendet: ein echter Controller spielt.",
                "Controles táctiles ocultos: juega un mando real.", "Comandi touch nascosti: gioca un vero controller.",
                "Controlos táteis ocultos: joga um comando real.");
        m("Start in controller mode", "Im Controller-Modus starten", "Empezar en modo mando", "Avvia in modalità controller", "Começar em modo comando");
        m("Keyboard layout", "Tastaturlayout", "Distribución del teclado", "Layout della tastiera", "Disposição do teclado");
        m("Automatic", "Automatisch", "Automático", "Automatico", "Automático");
        m("Like your phone keyboard: ", "Wie die Tastatur deines Handys: ", "Como el teclado de tu móvil: ", "Come la tastiera del telefono: ", "Como o teclado do telemóvel: ");
        m("What a key shows is what reaches the game, whatever your Windows keyboard language.",
                "Was auf der Taste steht, kommt im Spiel an – egal welche Sprache die Windows-Tastatur hat.",
                "Lo que muestra la tecla es lo que llega al juego, sea cual sea el idioma del teclado de Windows.",
                "Ciò che mostra il tasto arriva nel gioco, qualunque sia la lingua della tastiera di Windows.",
                "O que a tecla mostra é o que chega ao jogo, seja qual for a língua do teclado do Windows.");
        m("Sizes", "Größen", "Tamaños", "Dimensioni", "Tamanhos");
        m("Movement stick", "Bewegungsstick", "Joystick de movimiento", "Joystick di movimento", "Joystick de movimento");
        m("Camera stick", "Kamerastick", "Joystick de cámara", "Joystick della telecamera", "Joystick da câmara");
        m("Buttons", "Tasten", "Botones", "Pulsanti", "Botões");
        m("Keyboard", "Tastatur", "Teclado", "Tastiera", "Teclado");
        m("Opacity", "Deckkraft", "Opacidad", "Opacità", "Opacidade");
        m("Layout", "Anordnung", "Disposición", "Disposizione", "Disposição");
        m("Move buttons", "Tasten verschieben", "Mover botones", "Sposta i pulsanti", "Mover botões");
        m("Drag each button where you want it.", "Zieh jede Taste an ihren Platz.", "Arrastra cada botón a su sitio.",
                "Trascina ogni pulsante al suo posto.", "Arrasta cada botão para o seu lugar.");
        m("Button style", "Tastenstil", "Estilo de botones", "Stile dei pulsanti", "Estilo dos botões");
        m("Shape, colour and icon of each button.", "Form, Farbe und Symbol jeder Taste.", "Forma, color e icono de cada botón.",
                "Forma, colore e icona di ogni pulsante.", "Forma, cor e ícone de cada botão.");
        m("Reset positions", "Positionen zurücksetzen", "Restablecer posiciones", "Ripristina posizioni", "Repor posições");
        m("Put every button back in its original place?", "Alle Tasten an ihren ursprünglichen Platz zurücksetzen?",
                "¿Devolver todos los botones a su sitio original?", "Riportare tutti i pulsanti al loro posto originale?",
                "Repor todos os botões no lugar original?");
        m("Gesture guide", "Gestenhilfe", "Guía de gestos", "Guida ai gesti", "Guia de gestos");
        m("Look", "Bildstil", "Estilo", "Stile", "Estilo");
        m("Applied live by the phone. Each look uses a little more battery.",
                "Live vom Handy angewendet. Jeder Bildstil braucht etwas mehr Akku.",
                "Aplicado en directo por el móvil. Cada estilo gasta un poco más de batería.",
                "Applicato in diretta dal telefono. Ogni stile consuma un po' più di batteria.",
                "Aplicado em direto pelo telemóvel. Cada estilo gasta um pouco mais de bateria.");
        m("My look", "Mein Stil", "Mi estilo", "Il mio stile", "O meu estilo");
        m("Moving a slider switches to “Custom”.", "Ein Regler wechselt zu „Eigener“.", "Mover un control cambia a «Personalizado».",
                "Muovere un cursore passa a «Personalizzato».", "Mover um cursor passa para «Personalizado».");
        m("Start again from “Sharp”", "Neu ab „Scharf“", "Volver a empezar desde «Nítido»", "Ricomincia da «Nitido»", "Recomeçar a partir de «Nítido»");
        m("Display", "Anzeige", "Pantalla", "Schermo", "Ecrã");
        m("On-screen statistics", "Statistiken auf dem Bildschirm", "Estadísticas en pantalla", "Statistiche a schermo", "Estatísticas no ecrã");
        m("Frame rate, latency, bitrate.", "Bildrate, Latenz, Bitrate.", "Fotogramas, latencia, tasa de bits.", "Frame rate, latenza, bitrate.",
                "Fotogramas, latência, débito.");
        m("Current game", "Laufendes Spiel", "Partida actual", "Partita in corso", "Jogo atual");
        m("Small window now", "Jetzt kleines Fenster", "Ventana pequeña ahora", "Finestra piccola ora", "Janela pequena agora");
        m("The game keeps running on top of your other apps.", "Das Spiel läuft klein über deinen anderen Apps weiter.",
                "El juego sigue en pequeño sobre tus otras apps.", "Il gioco continua in piccolo sopra le altre app.",
                "O jogo continua em pequeno por cima das outras apps.");
        m("Open keyboard", "Tastatur öffnen", "Abrir teclado", "Apri tastiera", "Abrir teclado");
        m("When I leave the app", "Wenn ich die App verlasse", "Al salir de la app", "Quando esco dall'app", "Quando saio da app");
        m("Small window", "Kleines Fenster", "Ventana pequeña", "Finestra piccola", "Janela pequena");
        m("The game stays small instead of disconnecting.", "Das Spiel bleibt klein, statt die Verbindung zu trennen.",
                "El juego queda en pequeño en lugar de desconectarse.", "Il gioco resta piccolo invece di disconnettersi.",
                "O jogo fica pequeno em vez de desligar.");
        m("About", "Über", "Acerca de", "Informazioni", "Sobre");
        m("Disconnect", "Trennen", "Desconectar", "Disconnetti", "Desligar");
        m("Ends the stream.", "Beendet den Stream.", "Termina el stream.", "Termina lo stream.", "Termina o stream.");
        m("Leave the game and disconnect from the PC?", "Spiel verlassen und vom PC trennen?", "¿Salir de la partida y desconectarte del PC?",
                "Uscire dalla partita e disconnettersi dal PC?", "Sair do jogo e desligar do PC?");
        m("Grimoire", "Grimoire", "Grimorio", "Grimorio", "Grimório");
        m("GAME SETTINGS", "SPIELEINSTELLUNGEN", "AJUSTES DE LA PARTIDA", "IMPOSTAZIONI DELLA PARTITA", "DEFINIÇÕES DO JOGO");
        m("The PC picture as is. No cost.", "Das PC-Bild unverändert. Keine Kosten.", "La imagen del PC tal cual. Sin coste.",
                "L'immagine del PC così com'è. Nessun costo.", "A imagem do PC tal como está. Sem custo.");
        m("More detail, slightly richer colours.", "Mehr Details, etwas kräftigere Farben.", "Más detalle, colores algo más vivos.",
                "Più dettagli, colori un po' più vivi.", "Mais detalhe, cores um pouco mais vivas.");
        m("Full colours, bright picture.", "Volle Farben, helles Bild.", "Colores plenos, imagen luminosa.", "Colori pieni, immagine luminosa.",
                "Cores cheias, imagem luminosa.");
        m("Warm and contrasted, darker edges.", "Warm und kontrastreich, dunklere Ränder.", "Cálido y contrastado, bordes oscurecidos.",
                "Caldo e contrastato, bordi scuriti.", "Quente e contrastado, bordas escurecidas.");
        m("Lifted shadows and crisp edges: see everything.", "Aufgehellte Schatten und scharfe Kanten: du siehst alles.",
                "Sombras aclaradas y bordes nítidos: lo ves todo.", "Ombre schiarite e contorni netti: vedi tutto.",
                "Sombras clareadas e contornos nítidos: vês tudo.");
        m("Sharper only, original colours.", "Nur schärfer, Originalfarben.", "Solo más nítido, colores originales.",
                "Solo più nitido, colori originali.", "Só mais nítido, cores originais.");
        m("Soft and warm, like a film.", "Weich und warm, wie im Kino.", "Suave y cálido, como una película.", "Morbido e caldo, come un film.",
                "Suave e quente, como um filme.");
        m("Very saturated and punchy.", "Sehr satt und knackig.", "Muy saturado y potente.", "Molto saturo e incisivo.", "Muito saturado e vibrante.");
        m("Scanlines and mask of an old CRT.", "Zeilen und Maske eines alten Röhrenbildschirms.", "Líneas y máscara de una vieja pantalla CRT.",
                "Linee e maschera di un vecchio schermo CRT.", "Linhas e máscara de um velho ecrã CRT.");
        m("Flat colours and ink outlines.", "Flächige Farben und Tuschekonturen.", "Colores planos y contornos de tinta.",
                "Colori piatti e contorni a inchiostro.", "Cores lisas e contornos a tinta.");
        m("Your sliders, below.", "Deine Regler, weiter unten.", "Tus controles, más abajo.", "I tuoi cursori, qui sotto.", "Os teus cursores, mais abaixo.");
        m("Cancel", "Abbrechen", "Cancelar", "Annulla", "Cancelar");
        m("Yes", "Ja", "Sí", "Sì", "Sim");
        m("Controls", "Steuerung", "Controles", "Comandi", "Controlos");
        m("Picture", "Bild", "Imagen", "Immagine", "Imagem");
        m("Session", "Sitzung", "Sesión", "Sessione", "Sessão");
        m("Brightness", "Helligkeit", "Brillo", "Luminosità", "Brilho");
        m("Contrast", "Kontrast", "Contraste", "Contrasto", "Contraste");
        m("Saturation", "Sättigung", "Saturación", "Saturazione", "Saturação");
        m("Vibrance", "Dynamik", "Intensidad", "Vividezza", "Vibração");
        m("Shadows", "Schatten", "Sombras", "Ombre", "Sombras");
        m("Warmth", "Wärme", "Calidez", "Calore", "Calor");
        m("Sharpness", "Schärfe", "Nitidez", "Nitidezza", "Nitidez");
        m("Vignette", "Vignette", "Viñeta", "Vignettatura", "Vinheta");
        m("Debanding", "Entbänderung", "Anti-bandas", "Anti-bande", "Anti-bandas");
        m("Retro lines", "Retro-Zeilen", "Líneas retro", "Linee rétro", "Linhas retro");
        m("Ink outlines", "Tuschekonturen", "Contornos de tinta", "Contorni a inchiostro", "Contornos a tinta");
        m("Language", "Sprache", "Idioma", "Lingua", "Língua");
        m("Like the phone", "Wie das Handy", "Como el móvil", "Come il telefono", "Como o telemóvel");
        m("The whole app switches at the next launch; this panel right away.",
                "Die ganze App wechselt beim nächsten Start, dieses Fenster sofort.",
                "Toda la app cambia en el próximo inicio; este panel, al momento.",
                "Tutta l'app cambia al prossimo avvio; questo pannello subito.",
                "Toda a app muda no próximo arranque; este painel, já.");
        // Noms des ambiances
        m("None", "Keiner", "Ninguno", "Nessuno", "Nenhum");
        m("Sharp", "Scharf", "Nítido", "Nitido", "Nítido");
        m("Vivid", "Leuchtend", "Vivo", "Vivace", "Vivo");
        m("Cinema", "Kino", "Cine", "Cinema", "Cinema");
        m("Competitive", "Kompetitiv", "Competitivo", "Competitivo", "Competitivo");
        m("Pure sharp", "Nur Schärfe", "Solo nitidez", "Solo nitidezza", "Só nitidez");
        m("Filmic", "Filmisch", "Fílmico", "Filmico", "Fílmico");
        m("Arcade", "Arcade", "Arcade", "Arcade", "Arcade");
        m("Retro CRT", "Retro-Röhre", "CRT retro", "CRT rétro", "CRT retro");
        m("Cartoon", "Zeichentrick", "Dibujo animado", "Cartone animato", "Desenho animado");
        m("Custom", "Eigener", "Personalizado", "Personalizzato", "Personalizado");
    }
}
