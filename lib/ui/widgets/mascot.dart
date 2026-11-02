import 'package:flutter/material.dart';

import '../../l10n/ui_strings.dart';
import 'mascot_painter.dart';
import 'motion.dart';

export 'mascot_painter.dart' show MascotAnim;

/// 蓝猫品牌标志：静态猫脸 + 圆角底板。小于 64px 时默认使用 mini 细节。
class MascotLogo extends StatelessWidget {
  const MascotLogo({super.key, this.size = 28, this.mini});

  final double size;
  final bool? mini;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: context.l10n.appName,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: size,
          child: CustomPaint(
            painter: MascotPainter(
              params: MascotParams.face,
              brightness: Theme.of(context).brightness,
              mini: mini ?? size < 64,
            ),
          ),
        ),
      ),
    );
  }
}

/// 循环等待动画：A 眨眼抖耳（blink）、B 猫爪拨球（paw）、D 睡觉打呼（sleep）。
///
/// 不可见路由由 TickerMode 自动停止；系统开启减少动态效果
/// （disableAnimations）时停止循环，显示 [MascotSpec.staticK] 静态帧。
class MascotLoader extends StatefulWidget {
  const MascotLoader({
    super.key,
    required this.anim,
    this.size = 96,
    this.mini = false,
    this.semanticLabel,
  }) : assert(anim != MascotAnim.tail, 'Use MascotProgress for tail');

  final MascotAnim anim;
  final double size;
  final bool mini;
  final String? semanticLabel;

  @override
  State<MascotLoader> createState() => _MascotLoaderState();
}

class _MascotLoaderState extends State<MascotLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: MascotSpec.frames[widget.anim]!.loopDuration,
  );
  bool _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.disableAnimationsOf(context);
    if (_reduced) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(MascotLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.anim != widget.anim) {
      _controller.duration = MascotSpec.frames[widget.anim]!.loopDuration;
      if (!_reduced) _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final loop = MascotSpec.frames[widget.anim]!.loop;
    final art = RepaintBoundary(
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final k = _reduced
                ? MascotSpec.staticK(widget.anim)
                : MascotSpec.kAt(widget.anim, _controller.value * loop);
            return CustomPaint(
              painter: MascotPainter(
                params: MascotParams.anim(widget.anim, k),
                brightness: brightness,
                mini: widget.mini,
              ),
            );
          },
        ),
      ),
    );
    final label = widget.semanticLabel;
    if (label == null) return ExcludeSemantics(child: art);
    return Semantics(
      label: label,
      child: ExcludeSemantics(child: art),
    );
  }
}

/// C 尾巴进度：按真实进度（0..1）绘制行走的猫与进度轨道，不自动循环。
///
/// 旁边已有百分比文字，因此本组件不重复朗读。
class MascotProgress extends StatelessWidget {
  const MascotProgress({
    super.key,
    required this.progress,
    this.size = 64,
    this.mini,
  });

  final double progress;
  final double size;
  final bool? mini;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final target = progress.isFinite ? progress.clamp(0.0, 1.0) : 0.0;
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox.square(
          dimension: size,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: target),
            duration: AppMotion.durationOf(context),
            curve: AppMotion.curve,
            builder: (context, value, _) => CustomPaint(
              painter: MascotPainter(
                params: MascotParams.anim(MascotAnim.tail, value),
                brightness: brightness,
                mini: mini ?? size < 32,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
