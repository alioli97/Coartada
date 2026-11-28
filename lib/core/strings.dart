import '../game/deducer.dart';
import '../game/model.dart';

/// Hand-rolled translations (es, ca, en). Screens never hardcode user text.
class Strings {
  const Strings(this.lang);
  final String lang;

  static const languages = {'es': 'Español', 'ca': 'Català', 'en': 'English'};

  String _tr(String es, String ca, String en) => switch (lang) {
    'ca' => ca,
    'en' => en,
    _ => es,
  };

  // Home
  String get tagline => _tr(
    'Coloca a cada sospechoso en su sitio y descubre quién estaba a solas con la víctima.',
    'Col·loca cada sospitós al seu lloc i descobreix qui era a soles amb la víctima.',
    'Put every suspect in their place and find out who was alone with the victim.',
  );
  String get dailyCase => _tr('Caso del día', 'Cas del dia', 'Daily case');
  String get solvedToday => _tr('Resuelto hoy', 'Resolt avui', 'Solved today');
  String get play => _tr('Jugar', 'Jugar', 'Play');
  String get newCase => _tr('Nuevo caso', 'Cas nou', 'New case');
  String get continueCase =>
      _tr('Continuar caso', 'Continuar el cas', 'Continue case');
  String placedOf(int placed, int total) => _tr(
    '$placed de $total colocados',
    '$placed de $total col·locats',
    '$placed of $total placed',
  );
  String get howToPlay => _tr('Cómo jugar', 'Com es juga', 'How to play');
  String get stats => _tr('Estadísticas', 'Estadístiques', 'Statistics');
  String get archive =>
      _tr('Casos anteriores', 'Casos anteriors', 'Past cases');
  String get archiveIntro => _tr(
    'Los casos del día de los últimos 30 días. Cuentan en tus estadísticas, pero no en la racha.',
    'Els casos del dia dels últims 30 dies. Compten a les estadístiques, però no a la ratxa.',
    'Daily cases from the last 30 days. They count in your statistics, not in your streak.',
  );
  String get stateSolved => _tr('Resuelto', 'Resolt', 'Solved');
  String get stateInProgress => _tr('En curso', 'En curs', 'In progress');
  String get stateNotPlayed => _tr('Sin jugar', 'Sense jugar', 'Not played');
  String get today => _tr('Hoy', 'Avui', 'Today');
  String get yesterday => _tr('Ayer', 'Ahir', 'Yesterday');

  static const _weekdays = {
    'es': [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ],
    'ca': [
      'dilluns',
      'dimarts',
      'dimecres',
      'dijous',
      'divendres',
      'dissabte',
      'diumenge',
    ],
    'en': [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ],
  };
  static const _months = {
    'es': [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ],
    'ca': [
      'gener',
      'febrer',
      'març',
      'abril',
      'maig',
      'juny',
      'juliol',
      'agost',
      'setembre',
      'octubre',
      'novembre',
      'desembre',
    ],
    'en': [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ],
  };

  String _month(DateTime d) => (_months[lang] ?? _months['es']!)[d.month - 1];

  /// "de noviembre" / "de novembre" / "d'abril" (Catalan elides before a vowel).
  String _ofMonth(DateTime d) {
    final m = _month(d);
    if (lang == 'ca' && 'aeiou'.contains(m[0])) return "d'$m";
    return 'de $m';
  }

  /// "jueves, 26 de noviembre" / "dijous, 26 de novembre" / "Thursday, 26 November".
  String longDate(DateTime d) {
    final wd = (_weekdays[lang] ?? _weekdays['es']!)[d.weekday - 1];
    return lang == 'en'
        ? '$wd, ${d.day} ${_month(d)}'
        : '$wd, ${d.day} ${_ofMonth(d)}';
  }

  /// "26 nov." / "26 nov." / "26 Nov".
  String shortDate(DateTime d) {
    final m = _month(d).substring(0, 3);
    return lang == 'en' ? '${d.day} $m' : '${d.day} $m.';
  }

  String get currentStreak =>
      _tr('Racha actual', 'Ratxa actual', 'Current streak');
  String get bestStreak => _tr('Mejor racha', 'Millor ratxa', 'Best streak');
  String days(int n) => n == 1
      ? _tr('1 día', '1 dia', '1 day')
      : _tr('$n días', '$n dies', '$n days');
  String streakLine(int n) => _tr('Racha: ', 'Ratxa: ', 'Streak: ') + days(n);
  String get todayDone =>
      _tr('Caso de hoy resuelto', 'Cas d\'avui resolt', 'Today\'s case solved');
  String get todayPending => _tr(
    'Caso de hoy pendiente',
    'Cas d\'avui pendent',
    'Today\'s case still to solve',
  );
  String get classic => _tr('Clásico', 'Clàssic', 'Classic');
  String get noTouchShort => _tr('Sin roces', 'Sense tocar-se', 'No-touch');
  String get totalSolved =>
      _tr('Casos resueltos', 'Casos resolts', 'Cases solved');
  String get withoutHints => _tr('Sin ayudas', 'Sense ajudes', 'Without hints');
  String get solvedLabel => _tr('Resueltos', 'Resolts', 'Solved');
  String get bestLabel => _tr('Mejor', 'Millor', 'Best');
  String get averageLabel => _tr('Media', 'Mitjana', 'Average');
  String get hintsPerCase => _tr('Ayudas/caso', 'Ajudes/cas', 'Hints/case');
  String get noneYet => _tr(
    'Aún no has resuelto ningún caso en este modo.',
    'Encara no has resolt cap cas en aquest mode.',
    'No cases solved in this mode yet.',
  );

  /// One decimal, with the language's decimal separator.
  String decimal(double x) {
    final t = x.toStringAsFixed(1);
    return lang == 'en' ? t : t.replaceAll('.', ',');
  }

  String get settings => _tr('Ajustes', 'Configuració', 'Settings');
  String levelName(Level l) => switch (l) {
    Level.apprentice => _tr('Aprendiz', 'Aprenent', 'Apprentice'),
    Level.detective => _tr('Detective', 'Detectiu', 'Detective'),
    Level.inspector => _tr('Inspector', 'Inspector', 'Inspector'),
    Level.commissioner => _tr('Comisario', 'Comissari', 'Superintendent'),
    Level.legend => _tr('Leyenda', 'Llegenda', 'Legend'),
  };
  String solvedCount(int n) => n == 1
      ? _tr('1 resuelto', '1 resolt', '1 solved')
      : _tr('$n resueltos', '$n resolts', '$n solved');
  String best(String time) => _tr('Mejor $time', 'Millor $time', 'Best $time');
  String get noTouchTitle =>
      _tr('Variante Sin roces', 'Variant Sense tocar-se', 'No-touch variant');
  String get noTouchBody => _tr(
    'Además, nadie está en una casilla contigua a otra persona, ni en diagonal.',
    'A més, ningú és en una casella contigua a una altra persona, ni en diagonal.',
    'Also, nobody stands next to anyone else, not even diagonally.',
  );

  // Settings
  String get language => _tr('Idioma', 'Idioma', 'Language');
  String get appearance => _tr('Apariencia', 'Aparença', 'Appearance');
  String get themeSystem => _tr('Sistema', 'Sistema', 'System');
  String get themeLight => _tr('Claro', 'Clar', 'Light');
  String get themeDark => _tr('Oscuro', 'Fosc', 'Dark');
  String get gameSettings => _tr('Juego', 'Joc', 'Game');
  String get haptics => _tr('Vibración', 'Vibració', 'Vibration');
  String get hapticsBody => _tr(
    'Al comprobar, acusar y pedir ayuda.',
    'En comprovar, acusar i demanar ajuda.',
    'When checking, accusing and using a hint.',
  );
  String get visualHelp => _tr('Ayuda visual', 'Ajuda visual', 'Visual help');
  String get visualHelpBody => _tr(
    'Sombrea filas y columnas ocupadas y marca en rojo a quien choca. Desactívala para más reto.',
    'Ombreja files i columnes ocupades i marca en vermell qui xoca. Desactiva-la per a més repte.',
    'Shades taken rows and columns and rings clashing people in red. Turn it off for more challenge.',
  );

  // About
  String get about =>
      _tr('Acerca de Coartada', 'Sobre Coartada', 'About Coartada');
  String version(String v) => _tr('Versión $v', 'Versió $v', 'Version $v');
  String get aboutBody => _tr(
    'Un juego original de deducción. Cada caso lo genera la app y tiene una sola solución, a la que se llega razonando, sin adivinar.',
    'Un joc original de deducció. Cada cas el genera l\'app i té una sola solució, a la qual s\'arriba raonant, sense endevinar.',
    'An original deduction game. Every case is generated by the app and has exactly one solution, reached by reasoning, never by guessing.',
  );
  String get aboutPrivacy => _tr(
    'Sin cuentas, sin anuncios y sin seguimiento: tu progreso se queda en este dispositivo.',
    'Sense comptes, sense anuncis i sense seguiment: el teu progrés es queda en aquest dispositiu.',
    'No accounts, no ads and no tracking: your progress stays on this device.',
  );
  String get privacyPolicy =>
      _tr('Política de privacidad', 'Política de privacitat', 'Privacy policy');
  String get support =>
      _tr('Ayuda y contacto', 'Ajuda i contacte', 'Help and contact');
  String get writeToUs => _tr('Escríbenos', 'Escriu-nos', 'Email us');
  String get licenses => _tr('Licencias', 'Llicències', 'Licenses');
  String get licensesBody => _tr(
    'Tipografías y paquetes de código abierto',
    'Tipografies i paquets de codi obert',
    'Fonts and open-source packages',
  );
  String get opensInBrowser => _tr(
    'Se abre en el navegador',
    'S\'obre al navegador',
    'Opens in your browser',
  );
  String get linkFailed => _tr(
    'No se ha podido abrir. La dirección es:',
    'No s\'ha pogut obrir. L\'adreça és:',
    'Couldn\'t open it. The address is:',
  );

  // How to play
  String get rulesTitle => _tr('Las reglas', 'Les regles', 'The rules');
  String get rule1 => _tr(
    'En cada fila y en cada columna hay exactamente una persona.',
    'A cada fila i a cada columna hi ha exactament una persona.',
    'Every row and every column holds exactly one person.',
  );
  String get rule2 => _tr(
    'Nadie puede estar sobre una mesa, una planta o una estantería. Sí sobre sillas y alfombras.',
    'Ningú no pot ser sobre una taula, una planta o una prestatgeria. Sí sobre cadires i catifes.',
    'Nobody can stand on a table, a plant or a bookshelf. Chairs and rugs are fine.',
  );
  String get rule3 => _tr(
    'Todas las pistas son ciertas. Con ellas solo hay una forma de colocar a todos.',
    'Totes les pistes són certes. Amb elles només hi ha una manera de col·locar tothom.',
    'Every clue is true. Together they allow only one way to place everyone.',
  );
  String get rule4 => _tr(
    'El culpable es la única persona que estaba en la misma habitación que la víctima.',
    'El culpable és l\'única persona que era a la mateixa habitació que la víctima.',
    'The culprit is the only person who was in the same room as the victim.',
  );
  String get controlsTitle => _tr('Controles', 'Controls', 'Controls');
  String get control1 => _tr(
    'Toca un sospechoso de la lista y después una casilla para colocarlo.',
    'Toca un sospitós de la llista i després una casella per col·locar-lo.',
    'Tap a suspect in the list, then a square to place them.',
  );
  String get control2 => _tr(
    'Toca una casilla vacía sin nadie seleccionado, o usa el modo Tachar, para descartarla con una X.',
    'Toca una casella buida sense ningú seleccionat, o fes servir el mode Ratllar, per descartar-la amb una X.',
    'Tap an empty square with nobody selected, or use Cross out mode, to rule it out with an X.',
  );
  String get controlNotes => _tr(
    'Con el modo Notas, elige un sospechoso y toca casillas para apuntar su inicial donde podría estar. Vuelve a tocar para borrarla.',
    'Amb el mode Notes, tria un sospitós i toca caselles per apuntar-hi la inicial on podria ser. Torna a tocar per esborrar-la.',
    'In Notes mode, pick a suspect and tap squares to pencil in their initial where they might be. Tap again to erase it.',
  );
  String get control3 => _tr(
    'Toca una pista para tacharla cuando ya la hayas usado.',
    'Toca una pista per ratllar-la quan ja l\'hagis fet servir.',
    'Tap a clue to strike it through once you have used it.',
  );
  String get control4 => _tr(
    'Cuando estén todos colocados, pulsa Comprobar y señala al culpable.',
    'Quan tothom sigui col·locat, prem Comprovar i assenyala el culpable.',
    'When everyone is placed, tap Check and point out the culprit.',
  );
  String get mapTitle => _tr('El plano', 'El plànol', 'The map');
  String get mapBody => _tr(
    'El norte está arriba. Las líneas gruesas separan las habitaciones. Las filas se numeran de arriba abajo y las columnas con letras de izquierda a derecha.',
    'El nord és a dalt. Les línies gruixudes separen les habitacions. Les files es numeren de dalt a baix i les columnes amb lletres d\'esquerra a dreta.',
    'North is up. Thick lines separate the rooms. Rows are numbered top to bottom, columns lettered left to right.',
  );

  // Game
  String caseTitle(int seed) =>
      _tr('Caso nº $seed', 'Cas núm. $seed', 'Case #$seed');
  String briefing(String victim) => _tr(
    'Han encontrado el cuerpo de $victim. El culpable es la única persona que estaba en su misma habitación.',
    'Han trobat el cos de $victim. El culpable és l\'única persona que era a la seva mateixa habitació.',
    '$victim\'s body has been found. The culprit is the only person who was in the same room.',
  );
  String get victimLabel => _tr('Víctima', 'Víctima', 'Victim');
  String get suspects => _tr('Sospechosos', 'Sospitosos', 'Suspects');
  String get clues => _tr('Pistas', 'Pistes', 'Clues');
  String get rooms => _tr('Habitaciones', 'Habitacions', 'Rooms');
  String get wholeBoard => _tr('Ver todo', 'Veure-ho tot', 'Whole board');
  String get zoomIn => _tr('Acercar', 'Apropar', 'Zoom in');
  String get undo => _tr('Deshacer', 'Desfer', 'Undo');
  String get placed => _tr('colocado', 'col·locat', 'placed');
  String get crossOut => _tr('Tachar', 'Ratllar', 'Cross out');
  String get notes => _tr('Notas', 'Notes', 'Notes');
  String get pickForNotes => _tr(
    'Elige primero a quién quieres anotar.',
    'Tria primer qui vols anotar.',
    'Pick who to pencil in first.',
  );
  String notesLabel(List<String> names) =>
      _tr('notas: ', 'notes: ', 'notes: ') + names.join(', ');
  String get hint => _tr('Pista', 'Ajuda', 'Hint');
  String hintMistake(String name, String at) => _tr(
    '$name no puede estar en $at: no encaja con las pistas.',
    '$name no pot ser a $at: no encaixa amb les pistes.',
    '$name can\'t be on $at: it doesn\'t fit the clues.',
  );
  String hintReveal(String name, String at) =>
      _tr('$name estaba en $at.', '$name era a $at.', '$name was on $at.');
  String hintDeduction(String name, String at, Set<Reason> reasons) =>
      '${_deduction(name, at, reasons)} ${_tr('Pide otra ayuda si quieres que lo coloque.', 'Demana una altra ajuda si vols que el col·loqui.', 'Ask again if you want it placed for you.')}';

  /// Tutorial version: the same reasoning, then what to tap.
  String tutorialStep(String name, String at, Set<Reason> reasons) =>
      '${_deduction(name, at, reasons)} ${_tr('He seleccionado a $name: toca $at.', 'He seleccionat $name: toca $at.', 'I\'ve selected $name: tap $at.')}';

  String _deduction(String name, String at, Set<Reason> reasons) {
    final why = [
      for (final r in Reason.values)
        if (reasons.contains(r)) _reason(r),
    ];
    final because = why.isEmpty
        ? _tr('las reglas', 'les regles', 'the rules')
        : why.length == 1
        ? why.single
        : '${why.sublist(0, why.length - 1).join(', ')} '
              '${_tr('y', 'i', 'and')} ${why.last}';
    return _tr(
      '$name solo puede estar en $at. Se deduce de $because.',
      '$name només pot ser a $at. Es dedueix de $because.',
      '$name can only be on $at. It follows from $because.',
    );
  }

  // Tutorial
  String tutorialIntro1(String victim) => _tr(
    'Tu primer caso: han encontrado el cuerpo de $victim. Este es el plano: cada color es una habitación y las líneas gruesas son paredes. Debajo están los sospechosos y las pistas.',
    'El teu primer cas: han trobat el cos de $victim. Aquest és el plànol: cada color és una habitació i les línies gruixudes són parets. A sota hi ha els sospitosos i les pistes.',
    'Your first case: $victim\'s body has been found. This is the map: each color is a room and thick lines are walls. Below are the suspects and the clues.',
  );
  String get tutorialIntro2 => _tr(
    'La regla de oro: en cada fila y en cada columna hay exactamente una persona, y nadie está sobre mesas, plantas o estanterías. Las casillas resaltadas te guían.',
    'La regla d\'or: a cada fila i a cada columna hi ha exactament una persona, i ningú no és sobre taules, plantes o prestatgeries. Les caselles destacades et guien.',
    'The golden rule: every row and column holds exactly one person, and nobody stands on tables, plants or bookshelves. Highlighted squares guide you.',
  );
  String get tutorialCheck => _tr(
    '¡Todos en su sitio! Pulsa Comprobar.',
    'Tothom al seu lloc! Prem Comprovar.',
    'Everyone is in place! Tap Check.',
  );
  String get tutorialAccuse => _tr(
    'Ahora, el culpable: es la única persona que estaba en la misma habitación que la víctima.',
    'Ara, el culpable: és l\'única persona que era a la mateixa habitació que la víctima.',
    'Now the culprit: the only person in the same room as the victim.',
  );
  String get tutorialDoneTitle => _tr(
    '¡Ya sabes investigar!',
    'Ja saps investigar!',
    'You\'re a detective now!',
  );
  String get tutorialDoneBody => _tr(
    'Has resuelto tu primer caso. Los de verdad se resuelven igual, con más pistas.',
    'Has resolt el teu primer cas. Els de veritat es resolen igual, amb més pistes.',
    'You solved your first case. Real ones work the same way, with more clues.',
  );
  String get tutorialStart => _tr('Empezar', 'Començar', 'Let\'s go');
  String get tutorialSkip => _tr('Saltar', 'Saltar', 'Skip');
  String get next => _tr('Siguiente', 'Següent', 'Next');
  String get back => _tr('Atrás', 'Enrere', 'Back');
  String get tutorialCardTitle =>
      _tr('¿Primera vez?', 'Primera vegada?', 'First time?');
  String get tutorialCardBody => _tr(
    'Juega el caso guiado: aprenderás las reglas en dos minutos.',
    'Juga el cas guiat: aprendràs les regles en dos minuts.',
    'Play the guided case: learn the rules in two minutes.',
  );
  String get tutorialPlay => _tr('Caso guiado', 'Cas guiat', 'Guided case');
  String get notNow => _tr('Ahora no', 'Ara no', 'Not now');

  String _reason(Reason r) => switch (r) {
    Reason.clues => _tr(
      'las pistas resaltadas',
      'les pistes destacades',
      'the highlighted clues',
    ),
    Reason.occupied => _tr(
      'las filas y columnas ocupadas',
      'les files i columnes ocupades',
      'the taken rows and columns',
    ),
    Reason.rowColumnNeeds => _tr(
      'que cada fila y columna necesita a alguien',
      'que cada fila i columna necessita algú',
      'every row and column needing someone',
    ),
    Reason.victimRule => _tr(
      'la regla de la víctima',
      'la regla de la víctima',
      'the victim rule',
    ),
  };
  String get check => _tr('Comprobar', 'Comprovar', 'Check');
  String get restart =>
      _tr('Empezar de nuevo', 'Tornar a començar', 'Start over');
  String get incomplete => _tr(
    'Aún falta gente por colocar.',
    'Encara falta gent per col·locar.',
    'Some people are still missing.',
  );
  String get wrong => _tr(
    'Algo no cuadra: revisa las pistas.',
    'Alguna cosa no quadra: revisa les pistes.',
    'Something doesn\'t add up: check the clues.',
  );
  String get blocked => _tr(
    'Ahí no puede estar nadie.',
    'Allà no hi pot ser ningú.',
    'Nobody can stand there.',
  );
  String get conflict => _tr(
    'Dos personas comparten fila o columna.',
    'Dues persones comparteixen fila o columna.',
    'Two people share a row or column.',
  );
  String get accuseTitle => _tr('¿Quién fue?', 'Qui ha estat?', 'Who did it?');
  String get accuseBody => _tr(
    'Todos están en su sitio. Señala a quien estaba con la víctima.',
    'Tothom és al seu lloc. Assenyala qui era amb la víctima.',
    'Everyone is in place. Point out who was with the victim.',
  );
  String get wrongAccusation => _tr(
    'No fue esa persona. Mira quién comparte habitación con la víctima.',
    'No ha estat aquesta persona. Mira qui comparteix habitació amb la víctima.',
    'Not them. Look at who shares a room with the victim.',
  );
  String get solvedTitle =>
      _tr('¡Caso cerrado!', 'Cas tancat!', 'Case closed!');
  String solvedBody(String culprit, String victim, String room) => _tr(
    '$culprit estaba a solas con $victim $room.',
    '$culprit era a soles amb $victim $room.',
    '$culprit was alone with $victim $room.',
  );
  String get time => _tr('Tiempo', 'Temps', 'Time');
  String get hintsUsed => _tr('Pistas usadas', 'Ajudes', 'Hints used');
  String get anotherCase => _tr('Otro caso', 'Un altre cas', 'Another case');
  String get share => _tr('Compartir', 'Compartir', 'Share');
  String hintCount(int n) => n == 1
      ? _tr('1 ayuda', '1 ajuda', '1 hint')
      : _tr('$n ayudas', '$n ajudes', '$n hints');
  String get shareInvite => _tr(
    '¿Sabrías decir quién fue?',
    'Sabries dir qui ha estat?',
    'Can you tell who did it?',
  );
  String get backHome => _tr('Inicio', 'Inici', 'Home');
  String get selectHint => _tr(
    'Elige un sospechoso y toca una casilla.',
    'Tria un sospitós i toca una casella.',
    'Pick a suspect, then tap a square.',
  );
  String row(int r) => _tr('Fila ${r + 1}', 'Fila ${r + 1}', 'Row ${r + 1}');
  String column(int c) => _tr(
    'Columna ${colLetter(c)}',
    'Columna ${colLetter(c)}',
    'Column ${colLetter(c)}',
  );
  String get empty => _tr('vacía', 'buida', 'empty');
  String get crossed => _tr('descartada', 'descartada', 'ruled out');

  static String colLetter(int c) => String.fromCharCode(65 + c);

  String roomName(RoomKind r) => switch (r) {
    RoomKind.kitchen => _tr('Cocina', 'Cuina', 'Kitchen'),
    RoomKind.library => _tr('Biblioteca', 'Biblioteca', 'Library'),
    RoomKind.study => _tr('Despacho', 'Estudi', 'Study'),
    RoomKind.lounge => _tr('Salón', 'Saló', 'Lounge'),
    RoomKind.bedroom => _tr('Dormitorio', 'Dormitori', 'Bedroom'),
    RoomKind.bathroom => _tr('Baño', 'Bany', 'Bathroom'),
    RoomKind.garden => _tr('Jardín', 'Jardí', 'Garden'),
    RoomKind.cellar => _tr('Bodega', 'Celler', 'Cellar'),
    RoomKind.dining => _tr('Comedor', 'Menjador', 'Dining room'),
  };

  /// "in the kitchen", with the right preposition and article.
  String inRoom(RoomKind r) => switch (r) {
    RoomKind.kitchen => _tr('en la cocina', 'a la cuina', 'in the kitchen'),
    RoomKind.library => _tr(
      'en la biblioteca',
      'a la biblioteca',
      'in the library',
    ),
    RoomKind.study => _tr('en el despacho', 'a l\'estudi', 'in the study'),
    RoomKind.lounge => _tr('en el salón', 'al saló', 'in the lounge'),
    RoomKind.bedroom => _tr(
      'en el dormitorio',
      'al dormitori',
      'in the bedroom',
    ),
    RoomKind.bathroom => _tr('en el baño', 'al bany', 'in the bathroom'),
    RoomKind.garden => _tr('en el jardín', 'al jardí', 'in the garden'),
    RoomKind.cellar => _tr('en la bodega', 'al celler', 'in the cellar'),
    RoomKind.dining => _tr(
      'en el comedor',
      'al menjador',
      'in the dining room',
    ),
  };

  String furnitureName(Furniture f) => switch (f) {
    Furniture.none => '',
    Furniture.chair => _tr('Silla', 'Cadira', 'Chair'),
    Furniture.rug => _tr('Alfombra', 'Catifa', 'Rug'),
    Furniture.table => _tr('Mesa', 'Taula', 'Table'),
    Furniture.plant => _tr('Planta', 'Planta', 'Plant'),
    Furniture.shelf => _tr('Estantería', 'Prestatgeria', 'Bookshelf'),
  };

  String _a(Furniture f) => switch (f) {
    Furniture.chair => _tr('una silla', 'una cadira', 'a chair'),
    Furniture.rug => _tr('una alfombra', 'una catifa', 'a rug'),
    Furniture.table => _tr('una mesa', 'una taula', 'a table'),
    Furniture.plant => _tr('una planta', 'una planta', 'a plant'),
    Furniture.shelf => _tr('una estantería', 'una prestatgeria', 'a bookshelf'),
    Furniture.none => '',
  };

  static String _upper(String t) => t[0].toUpperCase() + t.substring(1);

  String clue(Clue c, Puzzle p) {
    final s = c.isGlobal ? '' : p.name(c.subject);
    final rooms = p.board.rooms;
    return switch (c) {
      InRoom(:final room) => _tr(
        '$s estaba ${inRoom(rooms[room])}.',
        '$s era ${inRoom(rooms[room])}.',
        '$s was ${inRoom(rooms[room])}.',
      ),
      NotInRoom(:final room) => _tr(
        '$s no estaba ${inRoom(rooms[room])}.',
        '$s no era ${inRoom(rooms[room])}.',
        '$s was not ${inRoom(rooms[room])}.',
      ),
      OnFurniture(furniture: Furniture.rug) => _tr(
        '$s estaba sobre una alfombra.',
        '$s era sobre una catifa.',
        '$s was standing on a rug.',
      ),
      OnFurniture() => _tr(
        '$s estaba en una silla.',
        '$s era en una cadira.',
        '$s was on a chair.',
      ),
      NextTo(:final furniture) => _tr(
        '$s estaba junto a ${_a(furniture)}.',
        '$s era al costat d\'${_a(furniture)}.',
        '$s was next to ${_a(furniture)}.',
      ),
      InRow(:final row) => _tr(
        '$s estaba en la fila ${row + 1}.',
        '$s era a la fila ${row + 1}.',
        '$s was in row ${row + 1}.',
      ),
      InColumn(:final column) => _tr(
        '$s estaba en la columna ${colLetter(column)}.',
        '$s era a la columna ${colLetter(column)}.',
        '$s was in column ${colLetter(column)}.',
      ),
      NorthOf(:final otherPerson) => _tr(
        '$s estaba más al norte que ${p.name(otherPerson)}.',
        '$s era més al nord que ${p.name(otherPerson)}.',
        '$s was further north than ${p.name(otherPerson)}.',
      ),
      WestOf(:final otherPerson) => _tr(
        '$s estaba más al oeste que ${p.name(otherPerson)}.',
        '$s era més a l\'oest que ${p.name(otherPerson)}.',
        '$s was further west than ${p.name(otherPerson)}.',
      ),
      SameRoom(:final otherPerson) => _tr(
        '$s y ${p.name(otherPerson)} estaban en la misma habitación.',
        '$s i ${p.name(otherPerson)} eren a la mateixa habitació.',
        '$s and ${p.name(otherPerson)} were in the same room.',
      ),
      InCorner() => _tr(
        '$s estaba en una esquina de la casa.',
        '$s era en un racó de la casa.',
        '$s was in a corner of the house.',
      ),
      ByOuterWall() => _tr(
        '$s estaba junto a una pared exterior.',
        '$s era al costat d\'una paret exterior.',
        '$s was against an outer wall.',
      ),
      NobodyInRoom(:final room) => _upper(
        _tr(
          'nadie estaba ${inRoom(rooms[room])}.',
          'ningú no era ${inRoom(rooms[room])}.',
          'nobody was ${inRoom(rooms[room])}.',
        ),
      ),
      DifferentRoom(:final otherPerson) => _tr(
        '$s y ${p.name(otherPerson)} estaban en habitaciones distintas.',
        '$s i ${p.name(otherPerson)} eren a habitacions diferents.',
        '$s and ${p.name(otherPerson)} were in different rooms.',
      ),
      SameDiagonal(:final otherPerson) => _tr(
        '$s y ${p.name(otherPerson)} estaban en la misma diagonal.',
        '$s i ${p.name(otherPerson)} eren a la mateixa diagonal.',
        '$s and ${p.name(otherPerson)} were on the same diagonal.',
      ),
    };
  }
}
