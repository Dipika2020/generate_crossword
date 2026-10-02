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
          actions: [
            Consumer(
              builder: (context, ref, _) {
                final showDisplayInfo = ref.watch(showDisplayInfoProvider);

                return PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'displayInfo') {
                      ref.read(showDisplayInfoProvider.notifier).toggle();
                    } else {
                      final newSize = CrosswordSize.values.firstWhere(
                        (size) => size.name == value,
                      );

                      ref.read(sizeProvider.notifier).setSize(newSize);
                    }
                  },
                  itemBuilder: (context) {
                    return [
                      ...CrosswordSize.values.map(
                        (size) => PopupMenuItem<String>(
                          value: size.name,
                          child: Text(size.label),
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem<String>(
                        value: 'displayInfo',
                        child: Row(
                          children: [
                            Icon(
                              showDisplayInfo
                                  ? Icons.check_box_outlined
                                  : Icons.check_box_outline_blank_outlined,
                            ),
                            const SizedBox(width: 8),
                            const Text('Display Info'),
                          ],
                        ),
                      ),
                    ];
                  },
                  icon: const Icon(Icons.more_vert),
                );
              },
            ),
          ],
          titleTextStyle: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          title: Text('Crossword Generator'),
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

class _EagerInitialization extends ConsumerWidget {
  const _EagerInitialization({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(wordListProvider);
    return child;
  }
}
