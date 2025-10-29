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
  MagnetometerEvent? magnetData;
  late StreamSubscription<AccelerometerEvent> _accelerometerSubscription;
  late StreamSubscription<MagnetometerEvent> _magnetometerSubscription;

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
          // print('Accelerometer event: $event');
          setState(() {
            accelerationData = event;
          });
        });
    _magnetometerSubscription =
        magnetometerEventStream(
          samplingPeriod: SensorInterval.gameInterval,
        ).listen((MagnetometerEvent event) {
          // print('Magnetometer event: $event');
          setState(() {
            magnetData = event;
            bearing = calculateBearing();
          });
        });
  }

  double calculateBearing() {
    if (accelerationData == null || magnetData == null) {
      print('Sensor data not available yet');
      return 0.0;
    }
    return aproxBearing();
    // TODO: Math needs work
    // final ax = accelerationData!.x;
    // final ay = accelerationData!.y;
    // final az = accelerationData!.z;
    // final mx = magnetData!.x;
    // final my = magnetData!.y;
    // final mz = magnetData!.z;

    // // Normalize accelerometer (gravity) vector
    // final normA = math.sqrt(ax * ax + ay * ay + az * az);
    // if (normA == 0) return aproxBearing();
    // final nx = ax / normA;
    // final ny = ay / normA;
    // final nz = az / normA;

    // // Normalize magnetometer vector
    // final normM = math.sqrt(mx * mx + my * my + mz * mz);
    // if (normM == 0) return aproxBearing();
    // final mxn = mx / normM;
    // final myn = my / normM;
    // final mzn = mz / normM;

    // // Compute east = M x gravity
    // final ex = myn * nz - mzn * ny;
    // final ey = mzn * nx - mxn * nz;
    // final ez = mxn * ny - myn * nx;
    // final normE = math.sqrt(ex * ex + ey * ey + ez * ez);
    // if (normE == 0) return aproxBearing();
    // final exn = ex / normE;
    // final eyn = ey / normE;
    // final ezn = ez / normE;

    // // Compute north = gravity x east
    // final nxv = ny * ezn - nz * eyn;
    // final nyv = nz * exn - nx * ezn;
    // final nzv = nx * eyn - ny * exn;

    // // Heading: atan2(east dot magnetic, north dot magnetic)
    // final double heading = math.atan2(
    //   exn * mxn + eyn * myn + ezn * mzn,
    //   nxv * mxn + nyv * myn + nzv * mzn,
    // );

    // // Normalize to 0..2pi
    // return (heading + 2 * math.pi) % (2 * math.pi);
  }

  double aproxBearing() {
    return math.atan2(magnetData!.y, magnetData!.x);
  }

  @override
  Widget build(BuildContext context) {
    // double bearing = calculateBearing();
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
    // recommended: radius inside the dial's padding
    final double r = math.min(size.width, size.height) / 2 - 20;

    // If `bearing = atan2(event.y, event.x)` (0 = +X, CCW positive):
    final double angle = math.pi / 2 - bearing;

    // convert to screen offsets (canvas y goes down, so invert sin)
    final double dx = math.cos(angle) * r;
    final double dy = -math.sin(angle) * r;

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
