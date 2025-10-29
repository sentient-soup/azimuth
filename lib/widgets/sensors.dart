import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SensorDebug extends StatefulWidget {
  const SensorDebug({super.key});

  @override
  State<SensorDebug> createState() => _IndicatorState();
}

class _IndicatorState extends State<SensorDebug> {
  AccelerometerEvent? accelerometer;
  MagnetometerEvent? magnet;

  late StreamSubscription<MagnetometerEvent> _magnetometerSubscription;

  @override
  void initState() {
    super.initState();
    _startSensors();
  }

  @override
  void dispose() {
    _magnetometerSubscription.cancel();
    super.dispose();
  }

  void _startSensors() async {
    _magnetometerSubscription =
        magnetometerEventStream(
          samplingPeriod: SensorInterval.gameInterval,
        ).listen((MagnetometerEvent event) {
          setState(() {
            magnet = event;
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      'X: ${magnet?.x.toStringAsFixed(2)}\n'
      'Y: ${magnet?.y.toStringAsFixed(2)}',
      style: const TextStyle(color: Colors.white, fontSize: 16),
    );
  }
}
