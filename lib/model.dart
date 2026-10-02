import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:characters/characters.dart';
import 'package:intl/intl.dart';

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
static Serializer<Crossword> get serializer => _$crosswordSerializer;

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

/// A work queue for a worker to process.
///
/// The work queue contains a crossword and a list of locations to try,
/// along with candidate words to add to the crossword.
abstract class WorkQueue implements Built<WorkQueue, WorkQueueBuilder> {
/// Serializes and deserializes the [WorkQueue] class.
static Serializer<WorkQueue> get serializer => _$workQueueSerializer;

/// The crossword the worker is working on.
Crossword get crossword;

/// The outstanding queue of locations to try.
BuiltMap<Location, Direction> get locationsToTry;

/// Known bad locations.
BuiltSet<Location> get badLocations;

/// The list of unused candidate words that can be added to this crossword.
BuiltSet<String> get candidateWords;

/// Returns true if the work queue is complete.
bool get isCompleted =>
locationsToTry.isEmpty || candidateWords.isEmpty;

/// Create a work queue from a crossword.
static WorkQueue from({
required Crossword crossword,
required Iterable<String> candidateWords,
required Location startLocation,
}) =>
WorkQueue(
(b) {
if (crossword.words.isEmpty) {
// Strip candidate words too long to fit in the crossword.
b.candidateWords.addAll(
candidateWords.where(
(word) =>
word.characters.length <= crossword.width,
),
);


        b.crossword.replace(crossword);

        b.locationsToTry.addAll({
          startLocation: Direction.across,
        });
      } else {
        // Assuming words have already been stripped to length.
        b.candidateWords.addAll(
          candidateWords.toBuiltSet().rebuild(
            (b) => b.removeAll(
              crossword.words.map((word) => word.word),
            ),
          ),
        );

        b.crossword.replace(crossword);

        crossword.characters
            .rebuild(
              (b) => b.removeWhere(
                (location, character) {
                  if (character.acrossWord != null &&
                      character.downWord != null) {
                    return true;
                  }

                  final left = crossword.characters[location.left];
                  if (left != null &&
                      left.downWord != null) {
                    return true;
                  }

                  final right =
                      crossword.characters[location.right];
                  if (right != null &&
                      right.downWord != null) {
                    return true;
                  }

                  final up = crossword.characters[location.up];
                  if (up != null &&
                      up.acrossWord != null) {
                    return true;
                  }

                  final down =
                      crossword.characters[location.down];
                  if (down != null &&
                      down.acrossWord != null) {
                    return true;
                  }

                  return false;
                },
              ),
            )
            .forEach(
              (location, character) {
                b.locationsToTry.addAll({
                  location: switch (
                    (character.acrossWord, character.downWord)
                  ) {
                    (null, null) => throw StateError(
                        'Character is not part of a word',
                      ),
                    (null, _) => Direction.across,
                    (_, null) => Direction.down,
                    (_, _) => throw StateError(
                        'Character is part of two words',
                      ),
                  },
                });
              },
            );
      }
    },
  );


/// Remove a location from the work queue.
WorkQueue remove(Location location) => rebuild(
(b) => b
..locationsToTry.remove(location)
..badLocations.add(location),
);

/// Update the work queue from a crossword derived from the current
/// crossword that this work queue is built from.
WorkQueue updateFrom(final Crossword crossword) =>
WorkQueue.from(
crossword: crossword,
candidateWords: candidateWords,
startLocation: locationsToTry.isNotEmpty
? locationsToTry.keys.first
: Location.at(0, 0),
).rebuild(
(b) => b
..badLocations.addAll(badLocations)
..locationsToTry.removeWhere(
(location, _) => badLocations.contains(location),
),
);

/// Factory constructor for [WorkQueue].
factory WorkQueue([
void Function(WorkQueueBuilder)? updates,
]) = _$WorkQueue;

WorkQueue._();
}


/// Display information for the current state of the crossword solve.
abstract class DisplayInfo
    implements Built<DisplayInfo, DisplayInfoBuilder> {
  static Serializer<DisplayInfo> get serializer => _$displayInfoSerializer;

  /// The number of words in the grid.
  String get wordsInGridCount;

  /// The number of candidate words.
  String get candidateWordsCount;

  /// The number of locations to explore.
  String get locationsToExploreCount;

  /// The number of known bad locations.
  String get knownBadLocationsCount;

  /// The percentage of the grid filled.
  factory DisplayInfo.from({required WorkQueue workQueue}) {
    final gridFilled =
        workQueue.crossword.characters.length /
        (workQueue.crossword.width * workQueue.crossword.height);

    final fmt = NumberFormat.decimalPattern();

    return DisplayInfo(
      (b) => b
        ..wordsInGridCount = fmt.format(workQueue.crossword.words.length)
        ..candidateWordsCount = fmt.format(workQueue.candidateWords.length)
        ..locationsToExploreCount =
            fmt.format(workQueue.locationsToTry.length)
        ..knownBadLocationsCount =
            fmt.format(workQueue.badLocations.length)
        ..gridFilledPercentage =
            '${(gridFilled * 100).toStringAsFixed(2)}%',
    );
  }

  /// The percentage of the grid filled.
  String get gridFilledPercentage;

  /// An empty [DisplayInfo] instance.
  static DisplayInfo get empty => DisplayInfo(
    (b) => b
      ..wordsInGridCount = '0'
      ..candidateWordsCount = '0'
      ..locationsToExploreCount = '0'
      ..knownBadLocationsCount = '0'
      ..gridFilledPercentage = '0%',
  );

  factory DisplayInfo([void Function(DisplayInfoBuilder)? updates]) =
      _$DisplayInfo;

  DisplayInfo._();
}


/// Construct serialization/deserialization code for the data model.
@SerializersFor([
  Location,
  Crossword,
  CrosswordWord,
  CrosswordCharacter,
  WorkQueue,
  DisplayInfo,
])
final Serializers serializers = _$serializers;