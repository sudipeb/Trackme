import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class UserLocation extends StatelessWidget {
  const UserLocation({super.key});

  @override
  Widget build(BuildContext context) {
    Future<void> _getCurrentLocation() async {
      bool serviceEnabled;
      LocationPermission permission;
      // Check if location services are enabled
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // If the service is not enabled, throws an error
        return Future.error('Location services are disabled.');
      }
      // Check the status of permissions
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // Request permission if permission is denied
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // If the request is still rejected, throw an error
          return Future.error('Location permissions are denied');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        // If permissions are permanently denied, throw an error
        return Future.error(
          'Location permissions are permanently denied, cannot request.',
        );
      }
      // Get current location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      print('Latitude: ${position.latitude}, Longitude: ${position.longitude}');
    }

    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => _getCurrentLocation(),
          child: Text("The desired Location:"),
        ),
      ),
    );
  }
}
