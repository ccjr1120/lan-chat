// LanChat 吉祥物：几何化蓝猫，纯 Canvas 绘制、确定性输出。
//
// 几何与参数需与 lib/ui/widgets/mascot_painter.dart ↔ assets/web/index.html
// 中 mascot 脚本块（/* mascot:begin */ … /* mascot:end */）保持逐行一致，
// 源自 lanchat-mascot/cat.js。函数名与 cat.js 相同，便于对照 diff。
// 局部绘制空间为以原点为中心的 100×100 方框。
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// 吉祥物调色板（对应 cat.js 的 PALETTES.light / PALETTES.dark）。
@immutable
class MascotPalette {
  const MascotPalette({
    required this.body,
    required this.shade,
    required this.belly,
    required this.bg,
    required this.card,
    required this.line,
    required this.track,
    required this.eye,
    required this.nose,
  });

  final Color body;
  final Color shade;
  final Color belly;
  final Color bg;
  final Color card;
  final Color line;
  final Color track;
  final Color eye;
  final Color nose;
}

/// 动画帧定义（对应 cat.js 的 FRAMES）。
@immutable
class MascotFrames {
  const MascotFrames({
    required this.count,
    required this.ms,
    required this.loop,
    this.keys,
  });

  final int count;
  final int ms;
  final int loop;
  final List<double>? keys;

  Duration get loopDuration => Duration(milliseconds: loop);
}

enum MascotPose { face, sit, walk, sleep }

/// A 眨眼抖耳、B 猫爪拨球、C 尾巴进度、D 睡觉打呼。
enum MascotAnim { blink, paw, tail, sleep }

/// 共享规格：色值、帧表与 BLINK/EAR 表，与网页端 LanMascot 完全一致。
abstract final class MascotSpec {
  static const light = MascotPalette(
    body: Color(0xFF4F6FF0),
    shade: Color(0xFF3F5EDC),
    belly: Color(0xFFEEF2FF),
    bg: Color(0xFFF7F8FA),
    card: Color(0xFFFFFFFF),
    line: Color(0xFF2B3544),
    track: Color(0xFFEEF0F3),
    eye: Color(0xFFF4C66A),
    nose: Color(0xFFFF8FA3),
  );

  static const dark = MascotPalette(
    body: Color(0xFF8BA4FF),
    shade: Color(0xFF6F8BEF),
    belly: Color(0xFFEEF2FF),
    bg: Color(0xFF1A1F29),
    card: Color(0xFF222834),
    line: Color(0xFFE6EAF2),
    track: Color(0xFF2E3645),
    eye: Color(0xFFF4C66A),
    nose: Color(0xFFFF8FA3),
  );

  static const ink = Color(0xFF2B3544);

  static const Map<MascotAnim, MascotFrames> frames = {
    MascotAnim.blink: MascotFrames(count: 8, ms: 200, loop: 1600),
    MascotAnim.paw: MascotFrames(count: 8, ms: 150, loop: 1200),
    MascotAnim.tail: MascotFrames(
      count: 5,
      ms: 750,
      loop: 3000,
      keys: [0, 0.25, 0.5, 0.75, 1],
    ),
    MascotAnim.sleep: MascotFrames(count: 6, ms: 400, loop: 2400),
  };

  static const List<double> blinkTable = [0, 0, 1, 1, 0.4, 0, 0, 0];
  static const List<double> earTable = [0, 0, 0, 0, 0, -12, 4, 0];

  /// 减少动态效果时 A/B/D 使用的静态帧 k。
  static double staticK(MascotAnim anim) => switch (anim) {
    MascotAnim.blink => 0,
    MascotAnim.paw => 0.25,
    MascotAnim.tail => 0,
    MascotAnim.sleep => 0,
  };

  /// 动画时间 t（毫秒）对应的 k：blink 取离散帧，paw/sleep 连续取值。
  static double kAt(MascotAnim anim, double tMs) {
    final f = frames[anim]!;
    if (anim == MascotAnim.blink) {
      return ((tMs / f.ms).floor() % f.count) / f.count;
    }
    return (tMs % f.loop) / f.loop;
  }

  static MascotPalette paletteOf(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}

/// 一帧的绘制参数（对应 cat.js drawCat 的 opts）。
@immutable
class MascotParams {
  const MascotParams({
    this.pose = MascotPose.face,
    this.blink = 0,
    this.earTwitch = 0,
    this.pawAngle = 0,
    this.ballPhase,
    this.tailAngle = 0,
    this.progress = 0,
    this.breath = 0,
    this.zPhase = 0,
    this.plate = false,
  });

  final MascotPose pose;
  final double blink;
  final double earTwitch;
  final double pawAngle;
  final double? ballPhase;
  final double tailAngle;
  final double progress;
  final double breath;
  final double zPhase;
  final bool plate;

  static const face = MascotParams(plate: true);

  /// 对应 cat.js 的 animParams(name, k)。
  static MascotParams anim(MascotAnim name, double k) {
    final kk = ((k % 1) + 1) % 1;
    switch (name) {
      case MascotAnim.blink:
        final i = (kk * 8 + 1e-6).floor() % 8;
        return MascotParams(
          pose: MascotPose.sit,
          blink: MascotSpec.blinkTable[i],
          earTwitch: MascotSpec.earTable[i],
        );
      case MascotAnim.paw:
        return MascotParams(
          pose: MascotPose.sit,
          pawAngle: 22 * math.sin(_tau * kk),
          ballPhase: kk,
        );
      case MascotAnim.tail:
        final p = _clamp(k, 0, 1);
        return MascotParams(
          pose: MascotPose.walk,
          progress: p,
          tailAngle: 18 * math.sin(p * 4 * math.pi + math.pi / 2),
        );
      case MascotAnim.sleep:
        return MascotParams(
          pose: MascotPose.sleep,
          breath: math.sin(_tau * kk),
          zPhase: kk,
        );
    }
  }

  @override
  bool operator ==(Object other) =>
      other is MascotParams &&
      other.pose == pose &&
      other.blink == blink &&
      other.earTwitch == earTwitch &&
      other.pawAngle == pawAngle &&
      other.ballPhase == ballPhase &&
      other.tailAngle == tailAngle &&
      other.progress == progress &&
      other.breath == breath &&
      other.zPhase == zPhase &&
      other.plate == plate;

  @override
  int get hashCode => Object.hash(
    pose,
    blink,
    earTwitch,
    pawAngle,
    ballPhase,
    tailAngle,
    progress,
    breath,
    zPhase,
    plate,
  );
}

const double _d2r = math.pi / 180;
const double _tau = math.pi * 2;

double _clamp(double v, double lo, double hi) => v < lo
    ? lo
    : v > hi
    ? hi
    : v;

/// 以 size.shortestSide 作为 cat.js 的 size，绘制于画布中心。
class MascotPainter extends CustomPainter {
  MascotPainter({
    required this.params,
    required this.brightness,
    this.mini = false,
  }) : palette = MascotSpec.paletteOf(brightness);

  final MascotParams params;
  final Brightness brightness;
  final MascotPalette palette;
  final bool mini;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    final s = size.shortestSide / 100;
    canvas.scale(s, s);
    _MascotCanvas(canvas, palette, brightness == Brightness.dark)
        .drawCat(params, mini);
    canvas.restore();
  }

  @override
  bool shouldRepaint(MascotPainter oldDelegate) =>
      oldDelegate.params != params ||
      oldDelegate.brightness != brightness ||
      oldDelegate.mini != mini;
}
/// cat.js 绘制函数的逐行移植；`_path` 对应 ctx 当前路径，`_alpha` 对应 globalAlpha。
class _MascotCanvas {
  _MascotCanvas(this.ctx, this.P, this.dark);

  final Canvas ctx;
  // ignore: non_constant_identifier_names
  final MascotPalette P;
  final bool dark;
  Path _path = Path();
  double _alpha = 1;

  // --- 路径与填充原语 -------------------------------------------------------

  void _begin() => _path = Path();

  void roundRectPath(double x, double y, double w, double h, double r) {
    final rr = math.max(0.0, math.min(r, math.min(w / 2, h / 2)));
    _begin();
    _path.addRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(rr)),
    );
  }

  void ellipsePath(double cx, double cy, double rx, double ry) {
    _begin();
    _path.addOval(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: math.max(rx, 0.01) * 2,
        height: math.max(ry, 0.01) * 2,
      ),
    );
  }

  void circlePath(double cx, double cy, double r) {
    _begin();
    _path.addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
  }

  Color _c(Color color) =>
      _alpha >= 1 ? color : color.withValues(alpha: color.a * _alpha);

  void fill(Color color) {
    ctx.drawPath(
      _path,
      Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.fill
        ..color = _c(color),
    );
  }

  void stroke(Color color, double width) {
    ctx.drawPath(
      _path,
      Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = width
        ..color = _c(color),
    );
  }

  void triPath(
    double ax,
    double ay,
    double bx,
    double by,
    double cx,
    double cy,
  ) {
    _begin();
    _path
      ..moveTo(ax, ay)
      ..lineTo(bx, by)
      ..lineTo(cx, cy)
      ..close();
  }

  // --- 几何 ---------------------------------------------------------------

  // Ear triangle anchored inside the head circle; twist rotates it about its base.
  void drawEar(double side, double hr, double twist) {
    final bx1 = side * hr * 0.95, by1 = -hr * 0.2;
    final tx = side * hr * 0.8, ty = -hr * 1.25;
    final bx2 = side * hr * 0.2, by2 = -hr * 0.9;
    final px = (bx1 + bx2) / 2, py = (by1 + by2) / 2;
    ctx.save();
    ctx.translate(px, py);
    ctx.rotate(twist * _d2r);
    ctx.translate(-px, -py);
    triPath(bx1, by1, tx, ty, bx2, by2);
    fill(P.body);
    stroke(P.body, hr * 0.12);
    final gx = (bx1 + tx + bx2) / 3, gy = (by1 + ty + by2) / 3;
    const s = 0.52;
    final lift = hr * 0.08;
    double ix(double vx) => gx + (vx - gx) * s;
    double iy(double vy) => gy + (vy - gy) * s - lift;
    triPath(ix(bx1), iy(by1), ix(tx), iy(ty), ix(bx2), iy(by2));
    fill(P.belly);
    ctx.restore();
  }

  void closedEye(double x, double y, double rx, double ry, double width) {
    _begin();
    _path
      ..moveTo(x - rx, y)
      ..quadraticBezierTo(x, y + ry * 0.75, x + rx, y);
    stroke(MascotSpec.ink, width);
  }

  // Head centred at the current origin. sleep: closed eyes.
  void drawHead(MascotParams o, double hr, bool mini, bool sleep) {
    drawEar(-1, hr, o.earTwitch);
    drawEar(1, hr, 0);
    circlePath(0, 0, hr);
    fill(P.body);

    final ex = hr * 0.38, ey = -hr * 0.02;
    final erx = hr * (mini ? 0.2 : 0.15), ery = hr * (mini ? 0.25 : 0.2);
    final open = sleep ? 0.0 : 1 - _clamp(o.blink, 0, 1);
    for (final side in const [-1.0, 1.0]) {
      final x = side * ex;
      if (open < 0.12) {
        closedEye(x, ey, erx * 1.05, ery, hr * (mini ? 0.1 : 0.06));
        continue;
      }
      ellipsePath(x, ey, erx, ery * open);
      fill(P.eye);
      ellipsePath(x, ey, erx * (mini ? 0.45 : 0.3), ery * open * 0.8);
      fill(MascotSpec.ink);
      if (!mini) {
        circlePath(x - erx * 0.35, ey - ery * open * 0.42, erx * 0.22);
        fill(const Color(0xFFFFFFFF));
      }
    }

    final nw = hr * (mini ? 0.13 : 0.09);
    final ny = hr * 0.22;
    triPath(-nw, ny, nw, ny, 0, ny + nw * 1.2);
    fill(P.nose);
    stroke(P.nose, hr * 0.04);

    if (mini) return;
    final my = ny + nw * 1.2;
    _begin();
    _path
      ..moveTo(-hr * 0.15, my + hr * 0.04)
      ..quadraticBezierTo(-hr * 0.07, my + hr * 0.12, 0, my)
      ..quadraticBezierTo(hr * 0.07, my + hr * 0.12, hr * 0.15, my + hr * 0.04);
    stroke(MascotSpec.ink, hr * 0.04);

    for (final side in const [-1.0, 1.0]) {
      for (var j = 0; j < 3; j++) {
        final dy = (j - 1) * hr * 0.11;
        _begin();
        _path
          ..moveTo(side * hr * 0.5, hr * 0.26 + dy)
          ..lineTo(side * hr * 1.18, hr * 0.19 + dy * 1.9);
        stroke(P.line, hr * 0.035);
      }
    }
  }

  // Tail as a thick quadratic stroke in tail-local space, rotated about its base.
  void drawTail(
    double bx,
    double by,
    double angle,
    double cx,
    double cy,
    double tx,
    double ty,
    double width,
  ) {
    ctx.save();
    ctx.translate(bx, by);
    ctx.rotate(angle * _d2r);
    _begin();
    _path
      ..moveTo(0, 0)
      ..quadraticBezierTo(cx, cy, tx, ty);
    stroke(P.body, width);
    ctx.restore();
  }

  void drawLimb(
    Color color,
    Color? padColor,
    double sx,
    double sy,
    double angle,
    double len,
    double w,
  ) {
    ctx.save();
    ctx.translate(sx, sy);
    ctx.rotate(angle * _d2r);
    roundRectPath(-w / 2, -w / 2, w, len + w / 2, w / 2);
    fill(color);
    if (padColor != null) {
      ellipsePath(0, len - w * 0.1, w * 0.36, w * 0.26);
      fill(padColor);
    }
    ctx.restore();
  }

  void drawBall(double phase, bool mini) {
    const r = 7.0;
    final dx = -9 * math.cos(_tau * phase);
    final bx = 30 + dx;
    double ground(double x) => 45 - 3 * ((x - 30) / 12) * ((x - 30) / 12);
    if (!mini) {
      _begin();
      for (var x = 16; x <= 44; x += 2) {
        if (x == 16) {
          _path.moveTo(x.toDouble(), ground(x.toDouble()));
        } else {
          _path.lineTo(x.toDouble(), ground(x.toDouble()));
        }
      }
      stroke(P.track, 1.6);
    }
    final by = ground(bx) - r;
    circlePath(bx, by, r);
    fill(P.eye);
    ctx.save();
    ctx.translate(bx, by);
    ctx.rotate(dx / r);
    _alpha = 0.45;
    _begin();
    _path
      ..moveTo(-r * 0.8, 0)
      ..lineTo(r * 0.8, 0);
    stroke(MascotSpec.ink, mini ? 2.2 : 1.4);
    _alpha = 1;
    ctx.restore();
    if (!mini) {
      circlePath(bx - r * 0.38, by - r * 0.4, r * 0.2);
      fill(const Color(0xFFFFFFFF));
    }
  }

  void drawSit(MascotParams o, bool mini) {
    final hasBall = o.ballPhase != null;
    ctx.save();
    ctx.translate(hasBall ? -10 : 0, 0);
    drawTail(-19, 38, -o.tailAngle, -19, -2, -17, -24, 7);
    ellipsePath(0, 22, 25, 23);
    fill(P.body);
    if (!mini) {
      ellipsePath(-16, 38, 9, 7);
      fill(P.shade);
      ellipsePath(16, 38, 9, 7);
      fill(P.shade);
    }
    ellipsePath(0, 27, 13, 16);
    fill(P.belly);
    final pad = mini ? null : P.belly;
    drawLimb(P.body, pad, -9, 20, 10, 23, 10);
    drawLimb(P.body, pad, 9, 20, -(10 + o.pawAngle), 23, 10);
    ctx.save();
    ctx.translate(0, -14);
    drawHead(o, 24, mini, false);
    ctx.restore();
    if (hasBall) drawBall(o.ballPhase!, mini);
    ctx.restore();
  }

  void drawWalk(MascotParams o, bool mini) {
    final p = _clamp(o.progress, 0, 1);
    const tx0 = -44.0, tw = 88.0, ty = 40.0, th = 5.0;
    roundRectPath(tx0, ty, tw, th, th / 2);
    fill(P.track);
    if (p > 0) {
      roundRectPath(tx0, ty, math.max(th, tw * p), th, th / 2);
      fill(P.body);
    }
    final s = math.cos(p * 6 * math.pi) * 22;
    ctx.save();
    ctx.translate(-24 + 44 * p, 0);
    drawLimb(P.shade, null, -9, 20, s, 16, 6);
    drawLimb(P.shade, null, 13, 20, -s, 16, 6);
    drawTail(-17, 12, o.tailAngle, -14, -6, -8, -22, 6);
    roundRectPath(-20, 7, 40, 19, 9.5);
    fill(P.body);
    if (!mini) {
      ellipsePath(3, 22, 11, 3.5);
      fill(P.belly);
    }
    drawLimb(P.body, null, -12, 20, -s, 16, 6.5);
    drawLimb(P.body, null, 10, 20, s, 16, 6.5);
    ctx.save();
    ctx.translate(20, 2);
    drawHead(o, 13, mini, false);
    ctx.restore();
    ctx.restore();
  }

  void zPath(double s) {
    _begin();
    _path
      ..moveTo(-s / 2, -s / 2)
      ..lineTo(s / 2, -s / 2)
      ..lineTo(-s / 2, s / 2)
      ..lineTo(s / 2, s / 2);
  }

  void drawSleep(MascotParams o, bool mini) {
    final b = _clamp(o.breath, -1, 1);
    ctx.save();
    ctx.translate(0, 40);
    ctx.scale(1 + 0.02 * b, 1 + 0.06 * b);
    ctx.translate(0, -40);
    ellipsePath(4, 23, 32, 17);
    fill(P.body);
    if (!mini) {
      ellipsePath(20, 28, 13, 9);
      fill(P.shade);
    }
    _begin();
    _path
      ..moveTo(33, 30)
      ..quadraticBezierTo(26, 46, -14, 41);
    stroke(P.body, 8);
    ctx.restore();

    ellipsePath(-9, 37.5, 6, 3.5);
    fill(P.belly);
    ellipsePath(1, 38.5, 6, 3.5);
    fill(P.belly);

    ctx.save();
    ctx.translate(-18, 15 - 1.4 * b);
    ctx.rotate(-12 * _d2r);
    drawHead(o, 17, mini, true);
    ctx.restore();

    final zp = o.zPhase;
    for (var j = 0; j < 3; j++) {
      final ph = (((zp + j / 3) % 1) + 1) % 1;
      ctx.save();
      _alpha = 1 - ph;
      ctx.translate(2 + 26 * ph, -10 - 30 * ph + 3 * math.sin(ph * _tau));
      zPath(5 + 6 * ph);
      stroke(P.line, mini ? 3 : 1.8);
      _alpha = 1;
      ctx.restore();
    }
  }

  void drawFace(MascotParams o, bool mini) {
    if (o.plate) {
      roundRectPath(-50, -50, 100, 100, 24);
      fill(dark ? P.track : P.belly);
    }
    final hr = o.plate ? (mini ? 33.0 : 30.0) : 36.0;
    ctx.save();
    ctx.translate(0, o.plate ? (mini ? 9 : 8) : 6);
    drawHead(o, hr, mini, false);
    ctx.restore();
  }

  void drawCat(MascotParams o, bool mini) {
    switch (o.pose) {
      case MascotPose.sit:
        drawSit(o, mini);
      case MascotPose.walk:
        drawWalk(o, mini);
      case MascotPose.sleep:
        drawSleep(o, mini);
      case MascotPose.face:
        drawFace(o, mini);
    }
  }
}
