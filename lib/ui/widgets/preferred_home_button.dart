import 'package:flutter/material.dart';

class PreferredHomeButton extends StatelessWidget {
  final VoidCallback onOpenFocus;
  final VoidCallback onOpenOverview;
  final Color? color;

  const PreferredHomeButton({
    super.key,
    required this.onOpenFocus,
    required this.onOpenOverview,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.wb_twilight_outlined),
      color: color,
      tooltip: 'Focus Home',
      onPressed: onOpenFocus,
    );
  }
}
