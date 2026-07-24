import 'package:flutter/material.dart';

import '../theme/tu_extensions.dart';

/// Empty-state placeholder.
class TuEmpty extends StatelessWidget {
  const TuEmpty({super.key, required this.message, required this.icon});

  factory TuEmpty.content({
    String message = 'No content',
    Widget? icon,
  }) {
    return TuEmpty(
      message: message,
      icon:
          icon ??
          Icon(Icons.inbox_outlined, size: 76.aw),
    );
  }

  factory TuEmpty.result({
    String message = 'No result',
    Widget? icon,
  }) {
    return TuEmpty(
      message: message,
      icon:
          icon ??
          Icon(Icons.search_off_outlined, size: 76.aw),
    );
  }

  final String message;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 8.aw,
        children: [
          icon,
          Text(
            message,
            style: context.styles.body[3] + context.colors.text.primary / 55,
          ),
        ],
      ),
    );
  }
}
