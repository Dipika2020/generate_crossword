import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import 'crossword_widget.dart';        ///new import 


class CrosswordGeneratorApp extends StatelessWidget {
  const CrosswordGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return _EagerInitialization(
      child: Scaffold(
        appBar: AppBar(
          titleTextStyle: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
        ),
        title: Text('Crossword Generator'),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final size = ref.watch(sizeProvider);

              return PopupMenuButton<CrosswordSize>(
                initialValue: size,
                onSelected: (newSize) {
                  ref.read(sizeProvider.notifier).setSize(newSize);
                },
                itemBuilder: (context) {
                  return CrosswordSize.values
                    .map(
                      (size) => PopupMenuItem<CrosswordSize>(
                        value: size,
                        child: Text(size.label),
                    ),
                )
                .toList();
          },
        );
      },
    ),
  ],
),
        body: SafeArea(
          child: CrosswordWidget(),
        ),
      ),
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