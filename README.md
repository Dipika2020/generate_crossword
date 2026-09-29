# \# Crossword Generator

# 

# A Flutter-based crossword puzzle generator built while following Google's Flutter Word Puzzle Codelab.

# 

# \## Current Progress

# 

# \### Module 4 – Crossword Data Model \& Grid

# 

# Implemented:

# 

# \- Crossword data model using `built\_value` and `built\_collection`

# \- Immutable `Location`, `CrosswordWord`, `CrosswordCharacter`, and `Crossword` models

# \- Crossword grid generation from placed words

# \- Random word selection using a `BuiltSet` extension

# \- Word-list loading and validation from `assets/words.txt`

# \- Crossword size selection:

# &#x20; - 20 × 11

# &#x20; - 40 × 22

# &#x20; - 80 × 44

# &#x20; - 160 × 88

# &#x20; - 500 × 500

# \- Riverpod providers for crossword size and generation

# \- Streaming crossword generation with intermediate grid updates

# \- Scrollable crossword grid using `two\_dimensional\_scrollables`

# \- Responsive cell rendering using Riverpod `select`

# \- Generated crossword displayed directly in the Flutter UI

# 

# \## Project Structure

# 

# ```text

# lib/

# ├── main.dart

# ├── model.dart

# ├── providers.dart

# ├── utils.dart

# └── widgets/

# &#x20;   ├── crossword\_generator\_app.dart

# &#x20;   └── crossword\_widget.dart

# 

# assets/

# └── words.txt

