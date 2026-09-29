# Crossword Generator

A Flutter application for generating and displaying crossword puzzles. This project is being developed incrementally while following Google's Flutter Word Puzzle Codelab, with a focus on Flutter architecture, Riverpod state management, immutable data models, and crossword-generation algorithms.

## Tech Stack

* Flutter / Dart
* Riverpod
* built_value / built_collection
* build_runner
* two_dimensional_scrollables

## Current Implementation

### 1. Word List

* Loads words from `assets/words.txt`
* Converts words to lowercase
* Removes whitespace
* Filters words shorter than 3 characters
* Accepts only `a-z` characters
* Exposes the word list through `wordListProvider`

### 2. Crossword Data Model

Implemented immutable models using `built_value`:

* `Location` — represents an `(x, y)` grid position
* `CrosswordWord` — represents a word, position, and direction
* `CrosswordCharacter` — represents a character and its associated words
* `Crossword` — represents the complete crossword grid

Generated serialization code is maintained using `build_runner`.

### 3. Crossword Generation

Implemented Riverpod providers for:

* Crossword size selection
* Random word selection
* Random word direction
* Random word placement
* Progressive crossword generation using a stream

Supported grid sizes:

| Size    | Dimensions |
| ------- | ---------: |
| Small   |    20 × 11 |
| Medium  |    40 × 22 |
| Large   |    80 × 44 |
| XLarge  |   160 × 88 |
| XXLarge |  500 × 500 |

### 4. Crossword UI

Implemented `CrosswordWidget` using `TableView` from `two_dimensional_scrollables`.

The UI currently supports:

* Two-dimensional scrolling
* Dynamic grid sizing
* Rendering generated characters
* Crossword size selection from the app bar

## Current Architecture

```text
words.txt
    ↓
wordListProvider
    ↓
crosswordProvider
    ↓
Crossword data model
    ↓
CrosswordWidget
    ↓
TableView grid
```

## Development Workflow

```bash
flutter pub get
dart run build_runner build
flutter analyze
flutter run -d chrome
```

The project uses feature branches and incremental Git checkpoints. Each major implementation step is analyzed, tested, committed, and pushed.

## Current Status

🚧 **In Development**

The application currently generates and displays randomly placed words in a configurable crossword-style grid.

### Next Steps

* Add valid crossword placement constraints
* Validate word intersections
* Prevent invalid overlaps
* Keep words within grid boundaries
* Implement crossword-generation and backtracking logic
* Add tests
* Polish the UI for portfolio use

## Reference

Based on Google's [Flutter Word Puzzle Codelab](https://codelabs.developers.google.com/codelabs/flutter-word-puzzle).
