import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:azimuth/widgets/indicator.dart';
import 'package:azimuth/widgets/sensors.dart';

class SolarAngleScreen extends StatefulWidget {
  const SolarAngleScreen({super.key});

  @override
  State<SolarAngleScreen> createState() => _SolarAngleScreenState();
}

class _SolarAngleScreenState extends State<SolarAngleScreen> {
  double latitude = 0.0;
  double longitude = 0.0;
  bool isCalibrated = false;

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> getCurrentLocation() async {
    PermissionStatus locationStatus = await Permission.locationWhenInUse
        .request();
    PermissionStatus sensorStatus = await Permission.sensors.request();
    if (!locationStatus.isGranted || !sensorStatus.isGranted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location and sensor permissions are required to use this app.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      // openAppSettings();
      // exit(0); // Exit the app if permissions are not granted
    }
    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error obtaining location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solar Panel Optimizer'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.blue.shade200,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _calibrateDevice,
            tooltip: 'Calibrate Device',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(color: Colors.black),
        child: const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: IndicatorLayout(latitude: 0, longitude: 0),
                      ),
                      // Expanded(child: SensorDebug()),
                    ],
                  ),
                ),
                // Text(
                //   'Lat: ${latitude.toStringAsFixed(4)}\n'
                //   'Lon: ${longitude.toStringAsFixed(4)}\n'
                //   'Calibrated: ${isCalibrated ? "Yes" : "No"}',
                //   style: const TextStyle(color: Colors.white, fontSize: 16),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _calibrateDevice() {
    setState(() {
      isCalibrated = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Device calibrated successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
