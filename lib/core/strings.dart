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
  String get settings => _tr('Ajustes', 'Configuració', 'Settings');
  String levelName(Level l) => switch (l) {
    Level.apprentice => _tr('Aprendiz', 'Aprenent', 'Apprentice'),
    Level.detective => _tr('Detective', 'Detectiu', 'Detective'),
    Level.inspector => _tr('Inspector', 'Inspector', 'Inspector'),
    Level.commissioner => _tr('Comisario', 'Comissari', 'Superintendent'),
  };
  String solvedCount(int n) => _tr('$n resueltos', '$n resolts', '$n solved');
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
  String get undo => _tr('Deshacer', 'Desfer', 'Undo');
  String get placed => _tr('colocado', 'col·locat', 'placed');
  String get crossOut => _tr('Tachar', 'Ratllar', 'Cross out');
  String get hint => _tr('Pista', 'Ajuda', 'Hint');
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

  String clue(Clue c, Puzzle p) {
    final s = p.name(c.subject);
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
    };
  }
}
