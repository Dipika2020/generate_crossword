import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import 'crossword_info_widget.dart';
import 'crossword_widget.dart';

class CrosswordGeneratorApp extends StatelessWidget {
  const CrosswordGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return _EagerInitialization(
      child: Scaffold(
        appBar: AppBar(
          actions: [_CrosswordGeneratorMenu()],
          titleTextStyle: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          title: const Text('Crossword Generator'),
        ),
        body: SafeArea(
          child: Consumer(
            builder: (context, ref, child) {
              return Stack(
                children: [
                  Positioned.fill(child: CrosswordWidget()),
                  if (ref.watch(showDisplayInfoProvider)) CrosswordInfoWidget(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CrosswordGeneratorMenu extends ConsumerWidget {
  const _CrosswordGeneratorMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MenuAnchor(
      menuChildren: [
        for (final entry in CrosswordSize.values)
          MenuItemButton(
            leadingIcon: entry == ref.watch(sizeProvider)
                ? const Icon(Icons.radio_button_checked_outlined)
                : const Icon(Icons.radio_button_unchecked_outlined),
            onPressed: () {
              ref.read(sizeProvider.notifier).setSize(entry);
            },
            child: Text(entry.label),
          ),

        MenuItemButton(
          leadingIcon: ref.watch(showDisplayInfoProvider)
              ? const Icon(Icons.check_box_outlined)
              : const Icon(Icons.check_box_outline_blank_outlined),
          onPressed: () {
            ref.read(showDisplayInfoProvider.notifier).toggle();
          },
          child: const Text('Display Info'),
        ),

        for (final count in BackgroundWorkers.values)
          MenuItemButton(
            leadingIcon: count == ref.watch(workerCountProvider)
                ? const Icon(Icons.radio_button_checked_outlined)
                : const Icon(Icons.radio_button_unchecked_outlined),
            onPressed: () {
              ref.read(workerCountProvider.notifier).setCount(count);
            },
            child: Text(count.label),
          ),
      ],
      builder: (context, controller, child) {
        return IconButton(
          onPressed: () {
            controller.open();
          },
          icon: const Icon(Icons.settings),
        );
      },
    );
  }
}

class _EagerInitialization extends ConsumerWidget {
  const _EagerInitialization({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(wordListProvider);
    return child;
  }
}
