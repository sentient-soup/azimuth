import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class IndicatorLayout extends StatelessWidget {
  const IndicatorLayout({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth =
            constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : 300.0;
        final double maxHeight =
            constraints.maxHeight.isFinite && constraints.maxHeight > 0
            ? constraints.maxHeight
            : 300.0;
        final double size = math.min(maxWidth, maxHeight);
        return SizedBox(
          width: size,
          height: size,
          child: Indicator(size: size),
        );
      },
    );
  }
}

class Indicator extends StatefulWidget {
  const Indicator({super.key, required this.size});
  final double size;

  @override
  State<Indicator> createState() => _IndicatorState();
}

class _IndicatorState extends State<Indicator> {
  double bearing = 0.0;
  AccelerometerEvent? accelerationData;
  late StreamSubscription<AccelerometerEvent> _accelerometerSubscription;
  late StreamSubscription<MagnetometerEvent> _magnetometerSubscription;
  final List<List<double>> _magnetBuffer = [];
  static const int _magnetBufferSize = 10;

  @override
  void initState() {
    super.initState();
    _startSensors();
  }

  @override
  void dispose() {
    _accelerometerSubscription.cancel();
    _magnetometerSubscription.cancel();
    super.dispose();
  }

  void _startSensors() {
    _accelerometerSubscription =
        accelerometerEventStream(
          samplingPeriod: SensorInterval.gameInterval,
        ).listen((AccelerometerEvent event) {
          accelerationData = event;
        });
    _magnetometerSubscription =
        magnetometerEventStream(
          samplingPeriod: SensorInterval.gameInterval,
        ).listen((MagnetometerEvent event) {
          _addMagnetSample(event);
          setState(() {
            bearing = calculateBearing();
          });
        });
  }

  double calculateBearing() {
    if (accelerationData == null) {
      return 0.0;
    }
    final avg = _getSmoothedMagnetSample();
    final double x = avg[0];
    final double y = avg[1];
    final double a = math.atan2(x, y);
    return a - math.pi / 2;
  }

  void _addMagnetSample(MagnetometerEvent e) {
    _magnetBuffer.add([e.x, e.y, e.z]);
    if (_magnetBuffer.length > _magnetBufferSize) _magnetBuffer.removeAt(0);
  }

  List<double> _getSmoothedMagnetSample() {
    if (_magnetBuffer.isEmpty) {
      return [0.0, 0.0, 0.0];
    }
    double sx = 0, sy = 0, sz = 0;
    for (int i = 0; i < _magnetBuffer.length; i++) {
      sx += _magnetBuffer[i][0];
      sy += _magnetBuffer[i][1];
      sz += _magnetBuffer[i][2];
    }
    return [
      sx / _magnetBuffer.length,
      sy / _magnetBuffer.length,
      sz / _magnetBuffer.length,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomPaint(
          size: Size(widget.size, widget.size),
          painter: IndicatorPainter(
            bubbleX: 0.0,
            bubbleY: 0.0,
            bearing: bearing,
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          child: Text(
            'Bearing: ${bearing.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ],
    );
  }
}

class IndicatorPainter extends CustomPainter {
  const IndicatorPainter({
    required this.bubbleX,
    required this.bubbleY,
    required this.bearing,
  });
  final double bubbleX;
  final double bubbleY;
  final double bearing;

  @override
  void paint(Canvas canvas, Size size) {
    paintCompassTicks(canvas, size);
    paintBubble(canvas, size);
    paintBearing(canvas, size);
  }

  void paintBearing(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.red.shade400
      ..style = PaintingStyle.fill;
    final double r = math.min(size.width, size.height) / 2 - 20;
    final double dx = math.cos(bearing) * r;
    final double dy = math.sin(bearing) * r;
    final center = Offset(size.width / 2 + dx, size.height / 2 + dy);
    canvas.drawCircle(center, 8.0, paint);
  }

  void paintBubble(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.green.shade600
      ..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = 20.0;
    canvas.drawCircle(center, radius, paint);
  }

  void paintCompassTicks(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2; // inside the border

    final Paint majorPaint = Paint()
      ..color = Colors.grey.shade500
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final Paint minorPaint = Paint()
      ..color = Colors.grey.shade800
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    // Draw ticks every 5 degrees, with longer ticks every 30 and longest every 90
    for (int deg = 0; deg < 360; deg += 5) {
      final double angle = (deg - 90) * (math.pi / 180);
      final bool isMajor = deg % 30 == 0;
      final bool isCardinal = deg % 90 == 0;
      final double tickLen = isCardinal
          ? 14
          : isMajor
          ? 10
          : 6;

      final inner = Offset(
        center.dx + (radius - tickLen) * math.cos(angle),
        center.dy + (radius - tickLen) * math.sin(angle),
      );
      final outer = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      canvas.drawLine(
        inner,
        outer,
        isMajor || isCardinal ? majorPaint : minorPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant IndicatorPainter oldDelegate) {
    return oldDelegate.bubbleX != bubbleX ||
        oldDelegate.bubbleY != bubbleY ||
        oldDelegate.bearing != bearing;
  }
}
