import 'dart:math' as math;

import 'package:flutter/material.dart';

enum TakkaMood { idle, happy, thinking, sleepy, alert }

class TakkaMascot extends StatefulWidget {
  const TakkaMascot({super.key, this.mood = TakkaMood.idle, this.size = 160});

  final TakkaMood mood;
  final double size;

  @override
  State<TakkaMascot> createState() => _TakkaMascotState();
}

class _TakkaMascotState extends State<TakkaMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3200))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(
          painter: TakkaPainter(t: _ctrl.value, mood: widget.mood),
        ),
      ),
    );
  }
}

class TakkaPainter extends CustomPainter {
  TakkaPainter({required this.t, required this.mood});

  final double t; // 0..1 loop
  final TakkaMood mood;

  // ── Palette extracted from the app icon ──
  static const faceTop = Color(0xFF17354A);
  static const faceBottom = Color(0xFF0D2130);
  static const bezelDark = Color(0xFF2B3A48);
  static const bezelLight = Color(0xFF5E7386);
  static const steel = Color(0xFF9FB9CD);
  static const steelDim = Color(0xFF54687A);
  static const green = Color(0xFF4E9A51);
  static const amber = Color(0xFFC98A2E);
  static const orange = Color(0xFFB4552D);

  @override
  bool shouldRepaint(covariant TakkaPainter old) =>
      old.t != t || old.mood != mood;

  Offset _pt(Offset c, double r, double deg) {
    final a = deg * math.pi / 180;
    return c + Offset(math.cos(a) * r, math.sin(a) * r);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final S = size.width;
    final bob = math.sin(t * 2 * math.pi) * S * 0.01;
    final c = Offset(S / 2, S / 2 + bob);
    final R = S * 0.40;

    _shadow(canvas, c, R);
    _bezel(canvas, c, R, S);
    _face(canvas, c, R);
    _rim(canvas, c, R, S);
    _arms(canvas, c, R, S);
    _eyes(canvas, c, R, S);
    _mouth(canvas, c, R, S);
    _bellyDial(canvas, c, R, S);
    if (mood == TakkaMood.happy) _checks(canvas, c, R, S);
    if (mood == TakkaMood.sleepy) _zzz(canvas, c, R, S);
  }

  void _shadow(Canvas canvas, Offset c, double R) {
    canvas.save();
    canvas.translate(c.dx, c.dy + R * 1.18);
    canvas.scale(1, 0.22);
    canvas.drawCircle(
        Offset.zero, R * 0.9, Paint()..color = Colors.black.withOpacity(0.35));
    canvas.restore();
  }

  void _bezel(Canvas canvas, Offset c, double R, double S) {
    canvas.drawCircle(c, R, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = S * 0.05
      ..color = bezelDark);
    canvas.drawCircle(c, R + S * 0.024, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = S * 0.008
      ..color = bezelLight.withOpacity(0.7));
  }

  void _face(Canvas canvas, Offset c, double R) {
    canvas.drawCircle(
        c,
        R * 0.96,
        Paint()
          ..shader = const RadialGradient(colors: [faceTop, faceBottom])
              .createShader(Rect.fromCircle(center: c, radius: R * 0.96)));
  }

  void _rim(Canvas canvas, Offset c, double R, double S) {
    // 12 dim hour ticks
    final tick = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = S * 0.012
      ..strokeCap = StrokeCap.round
      ..color = steelDim.withOpacity(0.5);
    for (var i = 0; i < 12; i++) {
      final a = i * 30.0;
      canvas.drawLine(_pt(c, R * 0.80, a), _pt(c, R * 0.88, a), tick);
    }

    // Colored timeline arcs — his "hairband"; reacts to mood
    Color seg(Color base) => switch (mood) {
          TakkaMood.happy => green,
          TakkaMood.alert => orange,
          TakkaMood.sleepy => base.withOpacity(0.35),
          _ => base,
        };
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = S * 0.035
      ..strokeCap = StrokeCap.round;
    void arc(double from, double to, Color col) {
      arcPaint.color = col;
      canvas.drawArc(Rect.fromCircle(center: c, radius: R * 0.86),
          from * math.pi / 180, (to - from) * math.pi / 180, false, arcPaint);
    }

    arc(-100, -70, seg(green));
    arc(-65, -40, seg(amber));
    arc(-35, -10, seg(amber));
    arc(-5, 20, seg(orange));
    arc(60, 90, seg(green));
  }

  void _arms(Canvas canvas, Offset c, double R, double S) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = S * 0.045
      ..strokeCap = StrokeCap.round
      ..color = bezelLight;
    Offset sh(double deg) => _pt(c, R * 0.95, deg);
    Offset hd(double deg) => _pt(c, R * 1.16, deg);

    if (mood == TakkaMood.happy) {
      canvas.drawLine(sh(195), hd(240), paint); // arms up \o/
      canvas.drawLine(sh(345), hd(300), paint);
    } else if (mood == TakkaMood.alert) {
      canvas.drawLine(sh(170), hd(185), paint); // hands out "!"
      canvas.drawLine(sh(10), hd(-5), paint);
    } else if (mood == TakkaMood.thinking) {
      canvas.drawLine(sh(160), hd(135), paint);
      canvas.drawLine(sh(340), c + Offset(R * 0.18, R * 0.34), paint); // hand on chin
    } else {
      canvas.drawLine(sh(160), hd(135), paint); // relaxed down
      canvas.drawLine(sh(20), hd(45), paint);
    }
  }

  void _eyes(Canvas canvas, Offset c, double R, double S) {
    final blink = (t * 4) % 1 < 0.05 ? 0.15 : 1.0;
    final eyeY = c.dy - R * 0.28;
    const dx = 0.30;

    if (mood == TakkaMood.happy || mood == TakkaMood.sleepy) {
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = S * 0.02
        ..strokeCap = StrokeCap.round
        ..color = steel;
      for (final s in [-1.0, 1.0]) {
        final rect = Rect.fromCenter(
            center: Offset(c.dx + s * dx * R, eyeY),
            width: R * 0.26,
            height: R * 0.26);
        if (mood == TakkaMood.happy) {
          canvas.drawArc(rect, math.pi, math.pi, false, p); // ∩ 
        } else {
          canvas.drawArc(rect, 0, math.pi, false, p); // closed lids ∪ 
        }
      }
      return;
    }

    for (final s in [-1.0, 1.0]) {
      var cx = c.dx + s * dx * R;
      var cy = eyeY;
      if (mood == TakkaMood.thinking) {
        cx += R * 0.06;
        cy -= R * 0.06; // looking up-right
      }
      final w = R * (mood == TakkaMood.alert ? 0.17 : 0.13);
      final h = w * 1.5 * blink * (mood == TakkaMood.alert ? 1.25 : 1.0);
      final rect =
          Rect.fromCenter(center: Offset(cx, cy), width: w, height: h);
      canvas.drawOval(
          rect.inflate(S * 0.010), Paint()..color = steel.withOpacity(0.25));
      canvas.drawOval(rect, Paint()..color = steel);
    }
  }

  void _mouth(Canvas canvas, Offset c, double R, double S) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = steel
      ..strokeWidth = S * 0.018;
    final my = c.dy + R * 0.10;

    if (mood == TakkaMood.happy) {
      canvas.drawArc(
          Rect.fromCenter(
              center: Offset(c.dx, my), width: R * 0.5, height: R * 0.45),
          0,
          math.pi,
          false,
          p..strokeWidth = S * 0.022);
    } else if (mood == TakkaMood.sleepy) {
      canvas.drawCircle(Offset(c.dx, my + R * 0.05), R * 0.06, p);
    } else if (mood == TakkaMood.alert) {
      canvas.drawCircle(Offset(c.dx, my + R * 0.05), R * 0.09, p);
    } else if (mood == TakkaMood.thinking) {
      canvas.drawPath(
          Path()
            ..moveTo(c.dx - R * 0.15, my + R * 0.06)
            ..quadraticBezierTo(
                c.dx - R * 0.05, my - R * 0.02, c.dx + R * 0.02, my + R * 0.06)
            ..quadraticBezierTo(c.dx + R * 0.09, my + R * 0.12,
                c.dx + R * 0.16, my + R * 0.04),
          p);
    } else {
      canvas.drawArc(
          Rect.fromCenter(
              center: Offset(c.dx, my - R * 0.05),
              width: R * 0.34,
              height: R * 0.30),
          0.15 * math.pi,
          0.7 * math.pi,
          false,
          p);
    }
  }

  void _bellyDial(Canvas canvas, Offset c, double R, double S) {
    final bc = c + Offset(0, R * 0.52);
    canvas.drawCircle(bc, R * 0.20, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = S * 0.012
      ..color = steelDim);
    final hp = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = steel
      ..strokeWidth = S * 0.016;
    canvas.drawLine(bc, _pt(bc, R * 0.14, -120), hp); // 10 o'clock
    canvas.drawLine(bc, _pt(bc, R * 0.16, -60), hp); // 2 o'clock — the 10:10 signature
    canvas.drawCircle(bc, S * 0.012, Paint()..color = steel);
  }

  void _checks(Canvas canvas, Offset c, double R, double S) {
    final spots = [
      (Offset(0.75, -1.00), green),
      (Offset(1.05, -0.60), green),
      (Offset(0.80, -1.20), amber),
    ];
    for (var i = 0; i < spots.length; i++) {
      final o = c +
          Offset(spots[i].$1.dx * R, spots[i].$1.dy * R) +
          Offset(0, math.sin(t * 2 * math.pi + i) * S * 0.01);
      final s = S * 0.035;
      canvas.drawPath(
          Path()
            ..moveTo(o.dx - s, o.dy)
            ..lineTo(o.dx - s * 0.3, o.dy + s * 0.6)
            ..lineTo(o.dx + s, o.dy - s * 0.6),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.5
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = spots[i].$2);
    }
  }

  void _zzz(Canvas canvas, Offset c, double R, double S) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = steel.withOpacity(0.8)
      ..strokeWidth = S * 0.014;
    for (var i = 0; i < 2; i++) {
      final s = S * (0.03 + i * 0.012);
      final o = c +
          Offset(R * (0.75 + i * 0.28), -R * (0.95 + i * 0.28)) +
          Offset(0, math.sin(t * 2 * math.pi + i) * S * 0.008);
      canvas.drawPath(
          Path()
            ..moveTo(o.dx, o.dy)
            ..lineTo(o.dx + s, o.dy)
            ..lineTo(o.dx, o.dy + s)
            ..lineTo(o.dx + s, o.dy + s),
          p);
    }
  }
}
