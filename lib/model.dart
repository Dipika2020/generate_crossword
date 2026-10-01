import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:characters/characters.dart';

part 'model.g.dart';

/// A location in a crossword.
abstract class Location implements Built<Location, LocationBuilder> {
  /// Serializes and deserializes the [Location] class.
  static Serializer<Location> get serializer => _$locationSerializer;

  /// The horizontal part of the location. The location is 0 based.
  int get x;

  /// The vertical part of the location. The location is 0 based.
  int get y;

  /// Returns a new location that is one step to the left.
  Location get left => rebuild((b) => b.x = x - 1);

  /// Returns a new location that is one step to the right.
  Location get right => rebuild((b) => b.x = x + 1);

  /// Returns a new location that is one step up.
  Location get up => rebuild((b) => b.y = y - 1);

  /// Returns a new location that is one step down.
  Location get down => rebuild((b) => b.y = y + 1);

  /// Returns a new location that is [offset] steps to the left.
  Location leftOffset(int offset) =>
      rebuild((b) => b.x = x - offset);

  /// Returns a new location that is [offset] steps to the right.
  Location rightOffset(int offset) =>
      rebuild((b) => b.x = x + offset);

  /// Returns a new location that is [offset] steps up.
  Location upOffset(int offset) =>
      rebuild((b) => b.y = y - offset);

  /// Returns a new location that is [offset] steps down.
  Location downOffset(int offset) =>
      rebuild((b) => b.y = y + offset);

  /// Pretty print a location as a (x,y) coordinate.
  String prettyPrint() => '($x,$y)';

  /// Constructor for [Location].
  factory Location([
    void Function(LocationBuilder)? updates,
  ]) = _$Location;

  Location._();

  /// Returns a location at the given coordinates.
  factory Location.at(int x, int y) {
    return Location(
      (b) => b
        ..x = x
        ..y = y,
    );
  }
}

/// The direction of a word in a crossword.
enum Direction {
  across,
  down;

  @override
  String toString() => name;
}

/// A word in a crossword.
abstract class CrosswordWord
    implements Built<CrosswordWord, CrosswordWordBuilder> {
  /// Serializes and deserializes the [CrosswordWord] class.
  static Serializer<CrosswordWord> get serializer =>
      _$crosswordWordSerializer;

  /// The word itself.
  String get word;

  /// The location of this word in the crossword.
  Location get location;

  /// The direction of this word in the crossword.
  Direction get direction;

  /// Compare two CrosswordWord objects by coordinates.
  static int locationComparator(
    CrosswordWord a,
    CrosswordWord b,
  ) {
    final compareRows = a.location.y.compareTo(b.location.y);
    final compareColumns = a.location.x.compareTo(b.location.x);

    return switch (compareColumns) {
      0 => compareRows,
      _ => compareColumns,
    };
  }

  /// Constructor for [CrosswordWord].
  factory CrosswordWord.word({
    required String word,
    required Location location,
    required Direction direction,
  }) {
    return CrosswordWord(
      (b) => b
        ..word = word
        ..direction = direction
        ..location.replace(location),
    );
  }

  /// Constructor for [CrosswordWord].
  factory CrosswordWord([
    void Function(CrosswordWordBuilder)? updates,
  ]) = _$CrosswordWord;

  CrosswordWord._();
}

/// A character in a crossword.
///
/// A character can be part of an across word, a down word,
/// or both, but never neither.
abstract class CrosswordCharacter
    implements
        Built<CrosswordCharacter, CrosswordCharacterBuilder> {
  /// Serializes and deserializes the [CrosswordCharacter] class.
  static Serializer<CrosswordCharacter> get serializer =>
      _$crosswordCharacterSerializer;

  /// The character at this location.
  String get character;

  /// The across word that contains this character.
  CrosswordWord? get acrossWord;

  /// The down word that contains this character.
  CrosswordWord? get downWord;

  /// Constructor for [CrosswordCharacter].
  factory CrosswordCharacter.character({
    required String character,
    CrosswordWord? acrossWord,
    CrosswordWord? downWord,
  }) {
    return CrosswordCharacter(
      (b) {
        b.character = character;

        if (acrossWord != null) {
          b.acrossWord.replace(acrossWord);
        }

        if (downWord != null) {
          b.downWord.replace(downWord);
        }
      },
    );
  }

  /// Constructor for [CrosswordCharacter].
  factory CrosswordCharacter([
    void Function(CrosswordCharacterBuilder)? updates,
  ]) = _$CrosswordCharacter;

  CrosswordCharacter._();
}

/// A crossword puzzle.
///
/// The puzzle constraint follows the English crossword puzzle tradition.
abstract class Crossword implements Built<Crossword, CrosswordBuilder> {
  /// Serializes and deserializes the [Crossword] class.
  static Serializer<Crossword> get serializer =>
      _$crosswordSerializer;

  /// Width across the crossword puzzle.
  int get width;

  /// Height down the crossword puzzle.
  int get height;

  /// The words in the crossword.
  BuiltList<CrosswordWord> get words;

  /// The characters by location.
  BuiltMap<Location, CrosswordCharacter> get characters;

  /// Checks whether this crossword is valid.
  bool get valid {
    // Check for duplicate words.
    final wordSet = words
        .map((word) => word.word)
        .toBuiltSet();

    if (wordSet.length != words.length) {
      return false;
    }

    for (final MapEntry(
          key: location,
          value: character,
        )
        in characters.entries) {
      // Every character must belong to an across or down word.
      if (character.acrossWord == null &&
          character.downWord == null) {
        return false;
      }

      // Every character must be inside the crossword.
      if (location.x < 0 ||
          location.y < 0 ||
          location.x >= width ||
          location.y >= height) {
        return false;
      }

      // Characters above and below must belong
      // to the same down word.
      if (characters[location.up] case final up?) {
        if (character.downWord == null) {
          return false;
        }

        if (up.downWord != character.downWord) {
          return false;
        }
      }

      if (characters[location.down] case final down?) {
        if (character.downWord == null) {
          return false;
        }

        if (down.downWord != character.downWord) {
          return false;
        }
      }

      // Characters to the left and right must belong
      // to the same across word.
      final left = characters[location.left];

      if (left != null) {
        if (character.acrossWord == null) {
          return false;
        }

        if (left.acrossWord != character.acrossWord) {
          return false;
        }
      }

      final right = characters[location.right];

      if (right != null) {
        if (character.acrossWord == null) {
          return false;
        }

        if (right.acrossWord != character.acrossWord) {
          return false;
        }
      }
    }

    return true;
  }

  /// Add a word to the crossword at the given location and direction.
  Crossword? addWord({
    required Location location,
    required String word,
    required Direction direction,
  }) {
    // Do not allow duplicate words.
    if (words
        .map((crosswordWord) => crosswordWord.word)
        .contains(word)) {
      return null;
    }

    final wordCharacters = word.characters;
    bool overlap = false;

    // Check each character of the proposed word.
    for (final (index, character) in wordCharacters.indexed) {
      final characterLocation = switch (direction) {
        Direction.across => location.rightOffset(index),
        Direction.down => location.downOffset(index),
      };

      final target = characters[characterLocation];

      if (target != null) {
        overlap = true;

        // Characters must match at an intersection.
        if (target.character != character) {
          return null;
        }

        // Do not allow two across words or two down words
        // to occupy the same location.
        if (direction == Direction.across &&
                target.acrossWord != null ||
            direction == Direction.down &&
                target.downWord != null) {
          return null;
        }
      }
    }

    // Once the crossword contains words, new words must overlap
    // with an existing word.
    if (words.isNotEmpty && !overlap) {
      return null;
    }

    final candidate = rebuild(
      (b) => b
        ..words.add(
          CrosswordWord.word(
            word: word,
            direction: direction,
            location: location,
          ),
        ),
    );

    // Only return the candidate if it satisfies all constraints.
    if (candidate.valid) {
      return candidate;
    }

    return null;
  }

  /// Fill the characters map after the crossword is built.
  @BuiltValueHook(finalizeBuilder: true)
  static void _fillCharacters(CrosswordBuilder b) {
    b.characters.clear();

    for (final word in b.words.build()) {
      for (final (idx, character) in word.word.characters.indexed) {
        switch (word.direction) {
          case Direction.across:
            b.characters.updateValue(
              word.location.rightOffset(idx),
              (b) => b.rebuild(
                (bInner) => bInner.acrossWord.replace(word),
              ),
              ifAbsent: () => CrosswordCharacter.character(
                acrossWord: word,
                character: character,
              ),
            );

          case Direction.down:
            b.characters.updateValue(
              word.location.downOffset(idx),
              (b) => b.rebuild(
                (bInner) => bInner.downWord.replace(word),
              ),
              ifAbsent: () => CrosswordCharacter.character(
                downWord: word,
                character: character,
              ),
            );
        }
      }
    }
  }

  /// Pretty print a crossword.
  String prettyPrintCrossword() {
    final buffer = StringBuffer();

    final grid = List.generate(
      height,
      (_) => List.generate(
        width,
        (_) => '░',
      ),
    );

    for (final MapEntry(
          key: Location(:x, :y),
          value: character,
        )
        in characters.entries) {
      grid[y][x] = character.character;
    }

    for (final row in grid) {
      buffer.writeln(row.join());
    }

    buffer.writeln();
    buffer.writeln('Across:');

    for (final word
        in words
            .where(
              (word) =>
                  word.direction == Direction.across,
            )
            .toList()
          ..sort(CrosswordWord.locationComparator)) {
      buffer.writeln(
        '${word.location.prettyPrint()}: ${word.word}',
      );
    }

    buffer.writeln();
    buffer.writeln('Down:');

    for (final word
        in words
            .where(
              (word) =>
                  word.direction == Direction.down,
            )
            .toList()
          ..sort(CrosswordWord.locationComparator)) {
      buffer.writeln(
        '${word.location.prettyPrint()}: ${word.word}',
      );
    }

    return buffer.toString();
  }

  /// Constructor for [Crossword].
  factory Crossword.crossword({
    required int width,
    required int height,
    Iterable<CrosswordWord>? words,
  }) {
    return Crossword(
      (b) {
        b
          ..width = width
          ..height = height;

        if (words != null) {
          b.words.addAll(words);
        }
      },
    );
  }

  /// Constructor for [Crossword].
  ///
  /// Use [Crossword.crossword] instead.
  factory Crossword([
    void Function(CrosswordBuilder)? updates,
  ]) = _$Crossword;

  Crossword._();
}

/// Construct serialization/deserialization code for the data model.
@SerializersFor([
  Location,
  Crossword,
  CrosswordWord,
  CrosswordCharacter,
])
final Serializers serializers = _$serializers;