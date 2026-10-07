// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import '../model.dart';
import '../providers.dart';

/// Displays the crossword while it is being generated.
///
/// This is the generation/progress view shown before the playable
/// CrosswordPuzzleWidget is ready.
///
/// The crossword cells are represented by dots rather than letters so
/// that the generated solution is not revealed to the player.
class CrosswordGeneratorWidget extends ConsumerWidget {
  const CrosswordGeneratorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the currently selected crossword size.
    //
    // This determines the number of rows and columns in the grid.
    final size = ref.watch(sizeProvider);

    return TableView.builder(
      // Allow the user to scroll diagonally through the crossword.
      diagonalDragBehavior: DiagonalDragBehavior.free,

      // Build each individual crossword cell.
      cellBuilder: _buildCell,

      // Number of columns in the crossword.
      columnCount: size.width,

      // Configure the size and borders of each column.
      columnBuilder: (index) => _buildSpan(context, index),

      // Number of rows in the crossword.
      rowCount: size.height,

      // Configure the size and borders of each row.
      rowBuilder: (index) => _buildSpan(context, index),
    );
  }

  /// Builds one cell in the crossword generation grid.
  ///
  /// The cell can be in one of several states:
  ///
  /// - It may contain part of the crossword.
  /// - It may currently be under exploration by the generator.
  /// - It may be an empty cell.
  TableViewCell _buildCell(
    BuildContext context,
    TableVicinity vicinity,
  ) {
    // Convert the TableView row/column into our crossword Location model.
    final location = Location.at(
      vicinity.column,
      vicinity.row,
    );

    return TableViewCell(
      child: Consumer(
        builder: (context, ref, _) {
          // Find out whether this location currently contains a
          // crossword character.
          //
          // workQueueProvider is a StreamProvider, so we need to
          // handle its data, error, and loading states.
          final character = ref.watch(
            workQueueProvider.select(
              (workQueueAsync) => workQueueAsync.when(
                data: (workQueue) =>
                    workQueue.crossword.characters[location],
                error: (error, stackTrace) => null,
                loading: () => null,
              ),
            ),
          );

          // Determine whether this location is currently being
          // considered by the crossword generator.
          //
          // locationsToTry contains the cells that the generator is
          // currently exploring.
          final explorationCell = ref.watch(
            workQueueProvider.select(
              (workQueueAsync) => workQueueAsync.when(
                data: (workQueue) =>
                    workQueue.locationsToTry.keys.contains(location),
                error: (error, stackTrace) => false,
                loading: () => false,
              ),
            ),
          );

          // If a crossword character exists at this location,
          // display it as a filled crossword cell.
          if (character != null) {
            return AnimatedContainer(
              // Animate changes as the crossword generator works.
              duration: Durations.extralong1,
              curve: Curves.easeInOut,

              // Highlight cells currently being explored.
              color: explorationCell
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onPrimary,

              child: Center(
                child: AnimatedDefaultTextStyle(
                  // Animate changes to the cell's text style.
                  duration: Durations.extralong1,
                  curve: Curves.easeInOut,

                  style: TextStyle(
                    fontSize: 24,

                    // Change the text color depending on whether
                    // the cell is currently being explored.
                    color: explorationCell
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.primary,
                  ),

                  // IMPORTANT:
                  // We intentionally display a bullet instead of the
                  // actual crossword character.
                  //
                  // This prevents the generated solution from being
                  // revealed while the crossword is being created.
                  //
                  // Unicode U+2022 = •
                  child: Text('•'),
                ),
              ),
            );
          }

          // Locations that are not currently part of the crossword
          // are displayed using the primary container color.
          return ColoredBox(
            color: Theme.of(context).colorScheme.primaryContainer,
          );
        },
      ),
    );
  }

  /// Defines the size and borders of each row and column.
  ///
  /// Each crossword cell is 32 pixels wide/high.
  TableSpan _buildSpan(
    BuildContext context,
    int index,
  ) {
    return TableSpan(
      extent: FixedTableSpanExtent(32),

      // Draw borders between the crossword cells.
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