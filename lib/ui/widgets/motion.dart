import 'dart:async';

import 'package:flutter/material.dart';

import '../theme.dart';

/// 全局统一微动效参数：200ms easeOutCubic。
abstract final class AppMotion {
  static const Duration duration = Duration(milliseconds: 200);
  static const Curve curve = Curves.easeOutCubic;

  /// 隐式动画使用的时长；系统关闭动画（disableAnimations）时为零。
  static Duration durationOf(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}

/// 入场动画：淡入并上移 8px，只播放一次。
///
/// `enabled` 为 false 或系统关闭动画（disableAnimations）时直接显示，
/// 用于消息气泡等只需要「首次出现」动效的场景。`enabled` 只在首次构建时读取，
/// 之后变化不影响子树结构，避免重建子组件状态。
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.enabled = true,
    this.delay = Duration.zero,
  });

  final Widget child;
  final bool enabled;
  final Duration delay;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.duration,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.curve,
  );
  late final bool _enabled = widget.enabled;
  Timer? _delayTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_enabled || MediaQuery.disableAnimationsOf(context)) {
      _delayTimer?.cancel();
      _controller.value = 1;
      return;
    }
    if (_controller.status != AnimationStatus.dismissed) return;
    // 延迟期间依赖变化（主题、MediaQuery）不重复创建计时器。
    if (_delayTimer?.isActive ?? false) return;
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _delayTimer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_enabled) return widget.child;
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) => Opacity(
        opacity: _curve.value,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - _curve.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// 桌面 hover 微提升：指针悬停时上移 1px 并加深阴影，触屏平台自然不触发。
class HoverLift extends StatefulWidget {
  const HoverLift({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
  });

  final Widget child;
  final BorderRadius borderRadius;

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  var _hovering = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovering = true),
    onExit: (_) => setState(() => _hovering = false),
    child: AnimatedContainer(
      duration: AppMotion.durationOf(context),
      curve: AppMotion.curve,
      transform: Matrix4.translationValues(0, _hovering ? -1 : 0, 0),
      transformAlignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        boxShadow: _hovering
            ? [
                BoxShadow(
                  color: AppColors.of(context).primary.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: widget.child,
    ),
  );
}

/// 主操作按钮：使用 AppColors.primaryGradient，禁用态退化为中性色。
///
/// 视觉规格对齐 filledButtonTheme（圆角 12、最小高度 50、15/600 文案），
/// 不改主题 API。
class GradientFilledButton extends StatelessWidget {
  const GradientFilledButton({
    super.key,
    required this.onPressed,
    required this.label,
  }) : icon = null;

  const GradientFilledButton.icon({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback? onPressed;
  final Widget? icon;
  final Widget label;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final enabled = onPressed != null;
    final dark = Theme.of(context).brightness == Brightness.dark;
    // 与 ColorScheme.onPrimary 的取值保持一致。
    final fg = enabled
        ? (dark ? colors.background : Colors.white)
        : colors.textSecondary;
    const radius = BorderRadius.all(Radius.circular(12));
    // InkWell 本身不声明按钮语义，补齐与 FilledButton 一致的 button/enabled。
    return Semantics(
      button: true,
      enabled: enabled,
      child: Material(
        type: MaterialType.transparency,
        child: Ink(
          decoration: BoxDecoration(
            gradient: enabled ? colors.primaryGradient : null,
            color: enabled ? null : colors.divider,
            borderRadius: radius,
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: radius,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 44, minHeight: 50),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: IconTheme.merge(
                  data: IconThemeData(color: fg, size: 20),
                  child: DefaultTextStyle.merge(
                    style: TextStyle(
                      color: fg,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[icon!, const SizedBox(width: 8)],
                        Flexible(child: label),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
