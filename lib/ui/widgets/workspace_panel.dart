import 'package:flutter/material.dart';

import '../theme.dart';

class WorkspaceBackground extends StatelessWidget {
  const WorkspaceBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return SizedBox.expand(
      child: DecoratedBox(
        decoration: BoxDecoration(color: colors.background),
        child: child,
      ),
    );
  }
}
