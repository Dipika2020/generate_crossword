// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// BuiltList is used to collect and sort the possible words for
// the Across and Down directions.
import 'package:built_collection/built_collection.dart';

// Flutter UI widgets.
import 'package:flutter/material.dart';

// Riverpod is used to listen to and interact with the puzzle provider.
import 'package:flutter_riverpod/flutter_riverpod.dart';

// TableView allows us to display a large crossword grid that can
// scroll horizontally and vertically.
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

// Our crossword model classes such as Location, Direction,
// and CrosswordCharacter.
import '../model.dart';

// Our Riverpod providers, including puzzleProvider.
import '../providers.dart';

/// Displays the playable crossword puzzle.
///
/// Each cell in the crossword is displayed in a two-dimensional
/// scrollable table.
///
/// When the user taps a cell containing a crossword character, a menu
/// appears with the possible Across and Down words that can be selected.
class CrosswordPuzzleWidget extends ConsumerWidget {
  const CrosswordPuzzleWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the currently selected crossword size.
    //
    // The size determines how many rows and columns the TableView
    // should display.
    final size = ref.watch(sizeProvider);

    return TableView.builder(
      // Allow the user to drag diagonally while scrolling the grid.
      diagonalDragBehavior: DiagonalDragBehavior.free,

      // Build each individual crossword cell.
      cellBuilder: _buildCell,

      // Number of columns in the crossword.
      columnCount: size.width,

      // Defines the appearance/size of each column.
      columnBuilder: (index) => _buildSpan(context, index),

      // Number of rows in the crossword.
      rowCount: size.height,

      // Defines the appearance/size of each row.
      rowBuilder: (index) => _buildSpan(context, index),
    );
  }

  /// Builds one cell in the crossword grid.
  ///
  /// [vicinity] tells us the row and column of the cell being built.
  TableViewCell _buildCell(
    BuildContext context,
    TableVicinity vicinity,
  ) {
    // Convert the table's row/column coordinates into our
    // crossword Location model.
    final location = Location.at(
      vicinity.column,
      vicinity.row,
    );

    return TableViewCell(
      child: Consumer(
        builder: (context, ref, _) {
          // Get the crossword character at this location.
          //
          // This represents the character that exists in the
          // generated crossword solution.
          final character = ref.watch(
            puzzleProvider.select(
              (puzzle) => puzzle.crossword.characters[location],
            ),
          );

          // Get the character that is currently selected by the player.
          //
          // If the player has not selected a word containing this
          // character yet, this will be null.
          final selectedCharacter = ref.watch(
            puzzleProvider.select(
              (puzzle) =>
                  puzzle.crosswordFromSelectedWords.characters[location],
            ),
          );

          // Get all alternative words that can be selected for
          // different positions/directions in the puzzle.
          final alternateWords = ref.watch(
            puzzleProvider.select(
              (puzzle) => puzzle.alternateWords,
            ),
          );

          // A null character means this location is not part of
          // the crossword.
          if (character != null) {
            // Get the Across word associated with this character.
            final acrossWord = character.acrossWord;

            // Start with an empty list of Across word choices.
            var acrossWords = BuiltList<String>();

            if (acrossWord != null) {
              // Add the current Across word and all of its
              // possible alternatives.
              acrossWords = acrossWords.rebuild(
                (b) => b
                  ..add(acrossWord.word)
                  ..addAll(
                    alternateWords[acrossWord.location]?[acrossWord
                            .direction] ??
                        [],
                  )
                  ..sort(),
              );
            }

            // Get the Down word associated with this character.
            final downWord = character.downWord;

            // Start with an empty list of Down word choices.
            var downWords = BuiltList<String>();

            if (downWord != null) {
              // Add the current Down word and all of its
              // possible alternatives.
              downWords = downWords.rebuild(
                (b) => b
                  ..add(downWord.word)
                  ..addAll(
                    alternateWords[downWord.location]?[downWord
                            .direction] ??
                        [],
                  )
                  ..sort(),
              );
            }

            // MenuAnchor lets us display a popup menu when the
            // crossword cell is tapped.
            return MenuAnchor(
              builder: (context, controller, _) {
                return GestureDetector(
                  // Open the word-selection menu at the position
                  // where the user tapped.
                  onTapDown: (details) => controller.open(
                    position: details.localPosition,
                  ),

                  child: AnimatedContainer(
                    // Smoothly animate visual changes to the cell.
                    duration: Durations.extralong1,
                    curve: Curves.easeInOut,

                    color: Theme.of(context).colorScheme.onPrimary,

                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        // Smoothly animate changes to the displayed
                        // crossword character.
                        duration: Durations.extralong1,
                        curve: Curves.easeInOut,

                        style: TextStyle(
                          fontSize: 24,
                          color: Theme.of(context).colorScheme.primary,
                        ),

                        // Display the player's selected character.
                        //
                        // If nothing has been selected yet, display
                        // an empty string.
                        child: Text(
                          selectedCharacter?.character ?? '',
                        ),
                      ),
                    ),
                  ),
                );
              },

              // These are the items displayed in the popup menu.
              menuChildren: [
                // If the cell belongs to both an Across and Down word,
                // display an "Across" heading first.
                if (acrossWords.isNotEmpty && downWords.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text('Across'),
                  ),

                // Add all possible Across words to the menu.
                for (final word in acrossWords)
                  _WordSelectMenuItem(
                    location: acrossWord!.location,
                    word: word,
                    selectedCharacter: selectedCharacter,
                    direction: Direction.across,
                  ),

                // If both directions are available, separate them
                // with a "Down" heading.
                if (acrossWords.isNotEmpty && downWords.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text('Down'),
                  ),

                // Add all possible Down words to the menu.
                for (final word in downWords)
                  _WordSelectMenuItem(
                    location: downWord!.location,
                    word: word,
                    selectedCharacter: selectedCharacter,
                    direction: Direction.down,
                  ),
              ],
            );
          }

          // If there is no crossword character at this location,
          // display an empty/background cell.
          return ColoredBox(
            color: Theme.of(context).colorScheme.primaryContainer,
          );
        },
      ),
    );
  }

  /// Defines the size and border of each row/column in the crossword.
  ///
  /// Each crossword cell is 32 pixels wide/high.
  TableSpan _buildSpan(
    BuildContext context,
    int index,
  ) {
    return TableSpan(
      extent: FixedTableSpanExtent(32),

      // Draw borders around the cells.
      foregroundDecoration: TableSpanDecoration(
        border: TableSpanBorder(
          leading: BorderSide(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          trailing: BorderSide(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

/// A menu item representing one possible word that can be selected.
///
/// This widget is responsible for:
/// - Showing the word in the popup menu.
/// - Showing whether the word is currently selected.
/// - Disabling the word if it is not a valid selection.
/// - Telling the puzzle provider to select the word when tapped.
class _WordSelectMenuItem extends ConsumerWidget {
  const _WordSelectMenuItem({
    required this.location,
    required this.word,
    required this.selectedCharacter,
    required this.direction,
  });

  /// Starting location of the word.
  final Location location;

  /// The word that the user can select.
  final String word;

  /// The currently selected character at the tapped cell.
  ///
  /// This is used to determine whether the corresponding Across
  /// or Down word is already selected.
  final CrosswordCharacter? selectedCharacter;

  /// Whether this word goes Across or Down.
  final Direction direction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the Puzzle notifier so that we can update the selected word.
    final notifier = ref.read(puzzleProvider.notifier);

    return MenuItemButton(
      // Only allow the user to select the word when the puzzle model
      // says that the selection is valid.
      onPressed:
          ref.watch(
            puzzleProvider.select(
              (puzzle) => puzzle.canSelectWord(
                location: location,
                word: word,
                direction: direction,
              ),
            ),
          )
          // If the word is valid, select it through the provider.
          ? () => notifier.selectWord(
              location: location,
              word: word,
              direction: direction,
            )
          // Otherwise, disable the menu item.
          : null,

      // Display a checked radio button when this word is currently
      // selected; otherwise display an unchecked radio button.
      leadingIcon:
          switch (direction) {
            Direction.across =>
              selectedCharacter?.acrossWord?.word == word,
            Direction.down =>
              selectedCharacter?.downWord?.word == word,
          }
          ? Icon(Icons.radio_button_checked_outlined)
          : Icon(Icons.radio_button_unchecked_outlined),

      // Display the actual word in the menu.
      child: Text(word),
    );
  }
}