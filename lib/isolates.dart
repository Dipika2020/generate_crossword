import 'package:built_collection/built_collection.dart';
import 'package:characters/characters.dart';
import 'package:flutter/foundation.dart';

import 'model.dart';
import 'utils.dart';

Stream<WorkQueue> exploreCrosswordSolutions({
  required Crossword crossword,
  required BuiltSet<String> wordList,
}) async* {
  final start = DateTime.now();

  var workQueue = WorkQueue.from(
    crossword: crossword,
    candidateWords: wordList,
    startLocation: Location.at(0, 0),
  );

  while (!workQueue.isCompleted) {
    final location = workQueue.locationsToTry.keys.toBuiltSet().randomElement();

    try {
      final crossword = await compute(((WorkQueue, Location) workMessage) {
        final (workQueue, location) = workMessage;

        final direction = workQueue.locationsToTry[location]!;
        final target = workQueue.crossword.characters[location];

        if (target == null) {
          return workQueue.crossword.addWord(
            direction: direction,
            location: location,
            word: workQueue.candidateWords.randomElement(),
          );
        }

        var words = workQueue.candidateWords.toBuiltList().rebuild(
          (b) => b
            ..where((word) => word.characters.contains(target.character))
            ..shuffle(),
        );

        var tryCount = 0;

        for (final word in words) {
          tryCount++;

          for (final (index, character) in word.characters.indexed) {
            if (character != target.character) {
              continue;
            }

            final candidate = workQueue.crossword.addWord(
              location: switch (direction) {
                Direction.across => location.leftOffset(index),
                Direction.down => location.upOffset(index),
              },
              word: word,
              direction: direction,
            );

            if (candidate != null) {
              return candidate;
            }
          }

          if (tryCount > 1000) {
            break;
          }
        }

        return null;
      }, (workQueue, location));

      if (crossword != null) {
        workQueue = workQueue.updateFrom(crossword);
      } else {
        workQueue = workQueue.remove(location);
      }

      yield workQueue;
    } catch (e) {
      debugPrint('Error running isolate: $e');
    }
  }

  debugPrint(
    '${crossword.width} x ${crossword.height} Crossword generated in '
    '${DateTime.now().difference(start).formatted}',
  );
}
