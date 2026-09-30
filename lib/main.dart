// In-Class Activity 06 
// Student:Tejaswini Kolliboni

import 'dart:math' show Random, max, pi;

import 'package:flutter/material.dart';

void main() => runApp(const SmileyApp());

class SmileyApp extends StatelessWidget {
  const SmileyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smiley Painter Lab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const DrawingPlayground(),
    );
  }
}

/// The three named designs (Level 3).
enum FaceType { classic, sleepy, surprised }

/// Bonus: one snapshot of everything the user can change.
/// The undo stack is a List<FaceConfig>.
class FaceConfig {
  FaceConfig({
    this.mood = 0.8,
    this.eyeRadius = 12,
    this.faceType = FaceType.classic,
    this.customColor,
    this.blush = false,
    this.hat = false,
    this.glasses = false,
    this.mustache = false,
  });

  double mood;
  double eyeRadius;
  FaceType faceType;
  Color? customColor; // set by long-press; cleared when the mood slider moves
  bool blush;
  bool hat;
  bool glasses;
  bool mustache;

  FaceConfig copy() => FaceConfig(
        mood: mood,
        eyeRadius: eyeRadius,
        faceType: faceType,
        customColor: customColor,
        blush: blush,
        hat: hat,
        glasses: glasses,
        mustache: mustache,
      );
}

class DrawingPlayground extends StatefulWidget {
  const DrawingPlayground({super.key});

  @override
  State<DrawingPlayground> createState() => _DrawingPlaygroundState();
}

class _DrawingPlaygroundState extends State<DrawingPlayground> {
  FaceConfig cfg = FaceConfig();
  final List<FaceConfig> _undo = [];
  final Random _rng = Random();

  static const List<Color> _palette = [
    Color(0xFF4FC3F7),
    Color(0xFFFFD54F),
    Color(0xFFFF8A65),
    Color(0xFFBA68C8),
    Color(0xFF81C784),
  ];

  // Level 2: face color reacts to mood bands.
  Color get _bandColor {
    if (cfg.mood < 0.35) return Colors.lightBlue.shade300; // sad: cool blue
    if (cfg.mood <= 0.7) return Colors.yellow.shade200; // neutral: soft yellow
    return Colors.yellow.shade600; // happy: bright yellow
  }

  Color get _faceColor => cfg.customColor ?? _bandColor;

  void _say(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  // Save the current configuration BEFORE changing it.
  void _save() {
    _undo.add(cfg.copy());
    if (_undo.length > 50) _undo.removeAt(0);
  }

  void _apply(void Function() change) {
    _save();
    setState(change);
  }

  void _undoLast() {
    if (_undo.isEmpty) {
      _say('Nothing to undo');
      return;
    }
    setState(() => cfg = _undo.removeLast());
    _say('Reverted last change');
  }

  // Reset: back to the original face. Saved first, so Undo can bring it back.
  void _reset() {
    _apply(() => cfg = FaceConfig());
    _say('Reset to the original face');
  }

  void _toggle(String name, bool current, void Function(bool) set) {
    _apply(() => set(!current));
    _say('$name ${!current ? 'on' : 'off'}');
  }

  // Level 4: tap cycles faces.
  void _cycleFace() {
    _apply(() {
      cfg.faceType =
          FaceType.values[(cfg.faceType.index + 1) % FaceType.values.length];
    });
    _say('Face changed to ${cfg.faceType.name}');
  }

  // Level 4: long-press randomizes mood + face color.
  void _randomize() {
    _apply(() {
      cfg.mood = _rng.nextDouble();
      cfg.customColor = _palette[_rng.nextInt(_palette.length)];
    });
    _say('Randomized: mood ${cfg.mood.toStringAsFixed(2)} and a new face color');
  }

  Widget _toggleButton(
      String label, IconData icon, bool on, VoidCallback? onTap) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: label,
          onPressed: onTap,
          icon: Icon(icon),
          style: IconButton.styleFrom(
            backgroundColor: on ? scheme.primaryContainer : null,
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CustomPainter Smiley Lab')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Center(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _cycleFace,
                  onLongPress: _randomize,
                  child: CustomPaint(
                    size: const Size(300, 300),
                    painter: SmileyPainter(
                      mood: cfg.mood,
                      faceColor: _faceColor,
                      eyeRadius: cfg.eyeRadius,
                      faceType: cfg.faceType,
                      blush: cfg.blush,
                      hat: cfg.hat,
                      glasses: cfg.glasses,
                      mustache: cfg.mustache,
                    ),
                  ),
                ),
              ),
            ),
            Flexible(
              flex: 3,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Level 3: switch faces at runtime.
                    SegmentedButton<FaceType>(
                      segments: const [
                        ButtonSegment(
                            value: FaceType.classic, label: Text('Classic')),
                        ButtonSegment(
                            value: FaceType.sleepy, label: Text('Sleepy')),
                        ButtonSegment(
                            value: FaceType.surprised,
                            label: Text('Surprised')),
                      ],
                      selected: {cfg.faceType},
                      onSelectionChanged: (s) =>
                          _apply(() => cfg.faceType = s.first),
                    ),
                    const SizedBox(height: 12),
                    Text('Mood: ${cfg.mood.toStringAsFixed(2)}'),
                    Slider(
                      value: cfg.mood,
                      onChangeStart: (_) => _save(),
                      onChanged: (double v) => setState(() {
                        cfg.mood = v;
                        cfg.customColor = null; // back to mood-band colors
                      }),
                    ),
                    Text('Eye radius: ${cfg.eyeRadius.toStringAsFixed(0)}'),
                    Slider(
                      value: cfg.eyeRadius,
                      min: 6,
                      max: 24,
                      onChangeStart: (_) => _save(),
                      onChanged: (double v) =>
                          setState(() => cfg.eyeRadius = v),
                    ),
                    // Bonus: accessories, blush, and undo.
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      children: [
                        _toggleButton('Blush', Icons.blur_on, cfg.blush,
                            () => _toggle('Blush', cfg.blush, (v) => cfg.blush = v)),
                        _toggleButton('Hat', Icons.checkroom, cfg.hat,
                            () => _toggle('Hat', cfg.hat, (v) => cfg.hat = v)),
                        _toggleButton(
                            'Glasses',
                            Icons.remove_red_eye_outlined,
                            cfg.glasses,
                            () => _toggle(
                                'Glasses', cfg.glasses, (v) => cfg.glasses = v)),
                        _toggleButton(
                            'Mustache',
                            Icons.face_retouching_natural,
                            cfg.mustache,
                            () => _toggle('Mustache', cfg.mustache,
                                (v) => cfg.mustache = v)),
                        _toggleButton(
                          'Undo (${_undo.length})',
                          Icons.undo,
                          false,
                          _undo.isEmpty ? null : _undoLast,
                        ),
                        _toggleButton(
                            'Reset', Icons.restart_alt, false, _reset),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('Tap the face to cycle, long-press to randomize'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SmileyPainter extends CustomPainter {
  SmileyPainter({
    required this.mood,
    required this.faceColor,
    required this.eyeRadius,
    required this.faceType,
    required this.blush,
    required this.hat,
    required this.glasses,
    required this.mustache,
  });

  final double mood;
  final Color faceColor;
  final double eyeRadius;
  final FaceType faceType;
  final bool blush;
  final bool hat;
  final bool glasses;
  final bool mustache;

  @override
  void paint(Canvas canvas, Size size) {
    // Everything is derived from size, so the face scales in any orientation.
    // The face sits a little low and a bit smaller so the hat has room above it.
    final c = Offset(size.width / 2, size.height * 0.56);
    final r = size.shortestSide * 0.34;

    final ink = Paint()..color = Colors.black87;
    final stroke = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    // Paint order (later calls draw on top):
    // face, border, eyes, mouth, blush, then accessories.

    // 1) Face fill, then 2) border.
    canvas.drawCircle(c, r, Paint()..color = faceColor);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = Colors.black87
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    final eyeR = faceType == FaceType.surprised ? eyeRadius * 1.4 : eyeRadius;
    final eyeY = c.dy - r * 0.22;
    final eyeDx = r * 0.38;
    final leftEye = Offset(c.dx - eyeDx, eyeY);
    final rightEye = Offset(c.dx + eyeDx, eyeY);

    // 3) Eyes and 4) mouth.
    switch (faceType) {
      case FaceType.classic:
        canvas.drawCircle(leftEye, eyeR, ink);
        canvas.drawCircle(rightEye, eyeR, ink);
        _classicMouth(canvas, c, r, stroke, ink);
        break;

      case FaceType.sleepy:
        // Closed eyes: the bottom half of a small oval (a "U" shape).
        for (final eye in [leftEye, rightEye]) {
          final rect = Rect.fromCenter(
            center: eye,
            width: eyeR * 2.4,
            height: eyeR * 1.4,
          );
          canvas.drawArc(rect, 0.1 * pi, 0.8 * pi, false, stroke);
        }
        final mouth = Rect.fromCenter(
          center: Offset(c.dx, c.dy + r * 0.3),
          width: r * 0.45,
          height: r * 0.25,
        );
        canvas.drawArc(mouth, 0.1 * pi, 0.8 * pi, false, stroke);
        break;

      case FaceType.surprised:
        canvas.drawCircle(leftEye, eyeR, ink);
        canvas.drawCircle(rightEye, eyeR, ink);
        final mouth = Rect.fromCenter(
          center: Offset(c.dx, c.dy + r * 0.45),
          width: r * 0.4,
          height: r * 0.55,
        );
        canvas.drawOval(mouth, ink);
        break;
    }

    // 5) Blush (drawOval on both cheeks).
    if (blush) {
      final blushPaint = Paint()
        ..color = Colors.pinkAccent.withValues(alpha: 0.45);
      for (final side in [-1.0, 1.0]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(c.dx + side * r * 0.62, c.dy + r * 0.18),
            width: r * 0.34,
            height: r * 0.2,
          ),
          blushPaint,
        );
      }
    }

    // 6) Accessories last so they sit on top.
    if (mustache) {
      final my = c.dy + r * 0.1;
      final path = Path()
        ..moveTo(c.dx, my)
        ..quadraticBezierTo(
            c.dx - r * 0.25, my - r * 0.18, c.dx - r * 0.5, my + r * 0.05)
        ..quadraticBezierTo(c.dx - r * 0.25, my + r * 0.02, c.dx, my + r * 0.1)
        ..quadraticBezierTo(
            c.dx + r * 0.25, my + r * 0.02, c.dx + r * 0.5, my + r * 0.05)
        ..quadraticBezierTo(
            c.dx + r * 0.25, my - r * 0.18, c.dx, my)
        ..close();
      canvas.drawPath(path, Paint()..color = Colors.brown.shade800);
    }

    if (glasses) {
      final glassR = max(eyeR * 1.5, r * 0.26);
      final glassStroke = Paint()
        ..color = Colors.black87
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      final lens = Paint()..color = Colors.lightBlue.withValues(alpha: 0.2);
      canvas.drawCircle(leftEye, glassR, lens);
      canvas.drawCircle(rightEye, glassR, lens);
      canvas.drawCircle(leftEye, glassR, glassStroke);
      canvas.drawCircle(rightEye, glassR, glassStroke);
      canvas.drawLine(Offset(leftEye.dx + glassR, eyeY),
          Offset(rightEye.dx - glassR, eyeY), glassStroke);
    }

    if (hat) {
      final brimCenter = Offset(c.dx, c.dy - r * 0.92);
      final crown = Rect.fromLTRB(
        c.dx - r * 0.5,
        brimCenter.dy - r * 0.55,
        c.dx + r * 0.5,
        brimCenter.dy,
      );
      canvas.drawRect(crown, Paint()..color = Colors.grey.shade900);
      canvas.drawRect(
        Rect.fromLTRB(crown.left, brimCenter.dy - r * 0.14, crown.right,
            brimCenter.dy),
        Paint()..color = Colors.red.shade400,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: brimCenter, width: r * 1.7, height: r * 0.16),
          Radius.circular(r * 0.08),
        ),
        Paint()..color = Colors.grey.shade900,
      );
    }
  }

  void _classicMouth(
      Canvas canvas, Offset c, double r, Paint stroke, Paint ink) {
    if (mood < 0.35) {
      // Frown: top half of an oval, placed lower on the face.
      final rect = Rect.fromCenter(
        center: Offset(c.dx, c.dy + r * 0.55),
        width: r * 0.9,
        height: r * 0.5,
      );
      canvas.drawArc(rect, 1.15 * pi, 0.7 * pi, false, stroke);
    } else {
      // Simple arch smile (same style as the sleepy mouth), just wider.
      // The curve gets deeper as mood rises, so the slider still reacts.
      final rect = Rect.fromCenter(
        center: Offset(c.dx, c.dy + r * 0.25),
        width: r * 0.7,
        height: r * (0.2 + mood * 0.3),
      );
      canvas.drawArc(rect, 0.1 * pi, 0.8 * pi, false, stroke);
    }
  }

  // Compare EVERY input that can change what paint() draws.
  @override
  bool shouldRepaint(covariant SmileyPainter old) {
    return old.mood != mood ||
        old.faceColor != faceColor ||
        old.eyeRadius != eyeRadius ||
        old.faceType != faceType ||
        old.blush != blush ||
        old.hat != hat ||
        old.glasses != glasses ||
        old.mustache != mustache;
  }
}