import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class UserLocation extends StatefulWidget {
  const UserLocation({super.key});

  @override
  State<UserLocation> createState() => _UserLocationState();
}

class _UserLocationState extends State<UserLocation> {
  String _locationMessage = 'Press the button to get location';
  bool _isLoading = false;
  StreamSubscription<Position>? _positionStream;

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<bool> _handlePermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationMessage = 'Location services are disabled.';
      });
      return false;
    }

    // Check the status of permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Request permission if permission is denied
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _locationMessage = 'Location permissions are denied.';
        });
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _locationMessage =
            'Location permissions are permanently denied, cannot request.';
      });
      return false;
    }

    return true;
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _locationMessage = 'Getting location...';
    });

    final hasPermission = await _handlePermission();
    if (!hasPermission) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Get current location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _locationMessage =
            'Latitude: ${position.latitude.toStringAsFixed(6)}\nLongitude: ${position.longitude.toStringAsFixed(6)}';
        _isLoading = false;
      });

      debugPrint(
        'Latitude: ${position.latitude}, Longitude: ${position.longitude}',
      );
    } catch (e) {
      setState(() {
        _locationMessage = 'Error getting location: $e';
        _isLoading = false;
      });
    }
  }

  void _startLocationUpdates() async {
    final hasPermission = await _handlePermission();
    if (!hasPermission) return;

    setState(() {
      _locationMessage = 'Listening for location updates...';
    });

    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10, // Updates only when moving 10 meters
          ),
        ).listen(
          (Position position) {
            setState(() {
              _locationMessage =
                  'Latitude: ${position.latitude.toStringAsFixed(6)}\nLongitude: ${position.longitude.toStringAsFixed(6)}\n\n(Live updates enabled)';
            });
            debugPrint('${position.latitude}, ${position.longitude}');
          },
          onError: (e) {
            setState(() {
              _locationMessage = 'Error: $e';
            });
          },
        );
  }

  void _stopLocationUpdates() {
    _positionStream?.cancel();
    _positionStream = null;
    setState(() {
      _locationMessage = 'Location updates stopped.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Track Me'), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Location display card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 48,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      if (_isLoading)
                        const CircularProgressIndicator()
                      else
                        Text(
                          _locationMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Get current location button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _getCurrentLocation,
                icon: const Icon(Icons.my_location),
                label: const Text('Get Current Location'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Start/Stop live updates button
              ElevatedButton.icon(
                onPressed: () {
                  if (_positionStream == null) {
                    _startLocationUpdates();
                  } else {
                    _stopLocationUpdates();
                  }
                },
                icon: Icon(
                  _positionStream == null ? Icons.play_arrow : Icons.stop,
                ),
                label: Text(
                  _positionStream == null
                      ? 'Start Live Updates'
                      : 'Stop Live Updates',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  backgroundColor: _positionStream == null
                      ? Colors.green
                      : Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
