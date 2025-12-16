import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class UserLocation extends StatefulWidget {
  const UserLocation({super.key});

  @override
  State<UserLocation> createState() => _UserLocationState();
}

class _UserLocationState extends State<UserLocation> {
  String _statusMessage = 'Initializing...';
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // _startLocationUpdates();
    _initLocationTracking();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _initLocationTracking() async {
    final hasPermission = await _handlePermission();
    if (!hasPermission) return;

    _startLocationUpdates();
  }

  Future<bool> _handlePermission({VoidCallback? inSuccess}) async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _statusMessage = 'Location services are disabled. Please enable GPS.';
        _hasError = true;
      });
      return false;
    }

    // Check the status of permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _statusMessage = 'Location permissions are denied.';
          _hasError = true;
        });
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _statusMessage =
            'Location permissions are permanently denied.\nPlease enable in Settings.';
        _hasError = true;
      });
      return false;
    }

    inSuccess?.call();
    return true;
  }

  void _startLocationUpdates() {
    _handlePermission(
      inSuccess: () async {
        _positionStream =
            Geolocator.getPositionStream(
              locationSettings: Platform.isAndroid
                  ? AndroidSettings(
                      intervalDuration: Duration(seconds: 10),
                      //not necessary for us
                      distanceFilter: 100,
                      foregroundNotificationConfig:
                          ForegroundNotificationConfig(
                            notificationTitle:
                                "Location Fetching in Background",
                            notificationText: "Location Fetching in background",
                            enableWakeLock: true,
                            enableWifiLock: true,
                            notificationIcon: AndroidResource(name: "Track me"),
                          ),
                    )
                  : AppleSettings(
                      distanceFilter: 10,
                      accuracy: LocationAccuracy.high,
                      activityType: ActivityType.fitness,
                      pauseLocationUpdatesAutomatically: true,
                      showBackgroundLocationIndicator: false,
                    ),
            ).listen((event) {
              _currentPosition = event;
              debugPrint(_currentPosition.toString());
            });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Me'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Status indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _hasError
                      ? Colors.red.shade100
                      : _currentPosition != null
                      ? Colors.green.shade100
                      : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _hasError
                          ? Icons.error
                          : _currentPosition != null
                          ? Icons.gps_fixed
                          : Icons.gps_not_fixed,
                      color: _hasError
                          ? Colors.red
                          : _currentPosition != null
                          ? Colors.green
                          : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _statusMessage,
                      style: TextStyle(
                        color: _hasError
                            ? Colors.red.shade700
                            : _currentPosition != null
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Location display card
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 64,
                        color: _currentPosition != null
                            ? Colors.blue
                            : Colors.grey,
                      ),
                      const SizedBox(height: 20),
                      if (_currentPosition == null && !_hasError)
                        const Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                              'Getting your location...',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        )
                      else if (_currentPosition != null)
                        Column(
                          children: [
                            _buildLocationRow(
                              'Latitude',
                              _currentPosition!.latitude.toStringAsFixed(6),
                            ),
                            const SizedBox(height: 12),
                            _buildLocationRow(
                              'Longitude',
                              _currentPosition!.longitude.toStringAsFixed(6),
                            ),
                            const SizedBox(height: 12),
                            _buildLocationRow(
                              'Accuracy',
                              '± ${_currentPosition!.accuracy.toStringAsFixed(1)} m',
                            ),
                            const SizedBox(height: 12),
                            _buildLocationRow(
                              'Speed',
                              '${(_currentPosition!.speed * 3.6).toStringAsFixed(1)} km/h',
                            ),
                            const SizedBox(height: 12),
                            _buildLocationRow(
                              'Altitude',
                              '${_currentPosition!.altitude.toStringAsFixed(1)} m',
                            ),
                            _buildLocationRow(
                              'TimeStamp',
                              '${_currentPosition!.timestamp}',
                            ),
                          ],
                        )
                      else
                        Text(
                          _statusMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.red.shade700,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Info text
              if (_currentPosition != null)
                const Text(
                  'Location updates when you move 10+ meters',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
