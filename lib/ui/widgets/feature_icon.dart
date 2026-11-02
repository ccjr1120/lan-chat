import 'package:flutter/material.dart';

import '../theme.dart';

/// 页面分区使用的品牌色图标，装饰图标不重复朗读。
class FeatureIcon extends StatelessWidget {
  const FeatureIcon({super.key, required this.icon, this.size = 40});
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.of(context).selfBubble,
        borderRadius: BorderRadius.circular(size * .3),
        border: Border.all(
          color: AppColors.of(context).primary.withValues(alpha: .08),
        ),
      ),
      child: Icon(icon, size: size * .5, color: AppColors.of(context).primary),
    ),
  );
}
