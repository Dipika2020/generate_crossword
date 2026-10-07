// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import 'crossword_generator_widget.dart';
import 'crossword_puzzle_widget.dart';
import 'puzzle_completed_widget.dart';

// The main application widget for the Crossword Puzzle game.
//
// This widget decides which screen should be displayed based on the
// current state of crossword generation and puzzle completion.
class CrosswordPuzzleApp extends StatelessWidget {
  const CrosswordPuzzleApp({super.key});

  @override
  Widget build(BuildContext context) {
    // _EagerInitialization makes sure the word list starts loading
    // as soon as the application starts.
    return _EagerInitialization(
      child: Scaffold(
        appBar: AppBar(
          // Settings menu for choosing the crossword size.
          actions: [_CrosswordPuzzleAppMenu()],

          // Styling for the application title.
          titleTextStyle: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),

          title: Text('Crossword Puzzle'),
        ),

        body: SafeArea(
          child: Consumer(
            builder: (context, ref, _) {
              // Watch the crossword generation process.
              //
              // While the crossword is being generated, the app will
              // display the CrosswordGeneratorWidget.
              final workQueueAsync = ref.watch(workQueueProvider);

              // Watch whether the player has solved the current puzzle.
              final puzzleSolved = ref.watch(
                puzzleProvider.select(
                  (puzzle) => puzzle.solved,
                ),
              );

              // workQueueProvider is a StreamProvider, so we need to
              // handle its loading, error, and data states.
              return workQueueAsync.when(
                data: (workQueue) {
                  // If the puzzle has been solved, show the completion
                  // screen.
                  if (puzzleSolved) {
                    return PuzzleCompletedWidget();
                  }

                  // Once crossword generation is complete and the
                  // crossword contains characters, show the actual
                  // playable puzzle.
                  if (workQueue.isCompleted &&
                      workQueue.crossword.characters.isNotEmpty) {
                    return CrosswordPuzzleWidget();
                  }

                  // Otherwise, the crossword is still being generated.
                  return CrosswordGeneratorWidget();
                },

                // Display a progress indicator while the work queue
                // provider is loading.
                loading: () => Center(
                  child: CircularProgressIndicator(),
                ),

                // Display the error if crossword generation fails.
                error: (error, stackTrace) => Center(
                  child: Text('$error'),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Starts loading the word list as soon as the application is initialized.
///
/// This widget doesn't display anything itself. It simply watches
/// wordListProvider so that the word list begins loading immediately.
class _EagerInitialization extends ConsumerWidget {
  const _EagerInitialization({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Start loading the word list immediately.
    //
    // Without this eager watch, loading would only begin when another
    // widget first requests the provider.
    ref.watch(wordListProvider);

    return child;
  }
}

// Settings menu for selecting the crossword size.
//
// The menu contains all values from CrosswordSize:
// - Small
// - Medium
// - Large
// - XLarge
// - XXLarge
class _CrosswordPuzzleAppMenu extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MenuAnchor(
      // Menu items displayed when the settings button is opened.
      menuChildren: [
        // Create one menu item for every available crossword size.
        for (final entry in CrosswordSize.values)
          MenuItemButton(
            // Change the crossword size when the user selects this item.
            onPressed: () =>
                ref.read(sizeProvider.notifier).setSize(entry),

            // Show a checked radio button for the currently selected size.
            leadingIcon:
                entry == ref.watch(sizeProvider)
                    ? Icon(Icons.radio_button_checked_outlined)
                    : Icon(Icons.radio_button_unchecked_outlined),

            // Display the size, for example "40 x 22".
            child: Text(entry.label),
          ),
      ],

      // The settings button that opens the menu.
      builder: (context, controller, child) => IconButton(
        onPressed: () => controller.open(),
        icon: Icon(Icons.settings),
      ),
    );
  }
}