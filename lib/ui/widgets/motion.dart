import 'dart:async';

import 'package:flutter/material.dart';

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
