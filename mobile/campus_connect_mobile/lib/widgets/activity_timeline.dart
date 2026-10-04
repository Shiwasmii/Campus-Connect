import 'package:flutter/material.dart';

/// Línea vertical simple junto a cada actualización pública.
class ActivityTimeline extends StatelessWidget {
  final List<Widget> items;

  const ActivityTimeline({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final colorLinea = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 28,
                  child: Column(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.only(top: 18),
                        decoration: BoxDecoration(
                          color: colorLinea,
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (i < items.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: colorLinea.withValues(alpha: 0.35),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: i == items.length - 1 ? 0 : 12,
                    ),
                    child: items[i],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
