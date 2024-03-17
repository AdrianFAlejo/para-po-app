import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class Map extends StatefulWidget {
  const Map({super.key});

  @override
  State<Map> createState() => _MapState();
}

const kGoogleApiKey = "AIzaSyACyZcjQBMmrjdaX5yK0piILmwTI0d-SGc";
// GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: kGoogleApiKey);

class _MapState extends State<Map> {
  var location = Location();
  bool isLoading = true;
  LocationData currentLocation = LocationData.fromMap({
    "latitude": 0.0,
    "longitude": 0.0,
    "accuracy": 0.0,
  });

  @override
  void initState() {
    checkIfLocationOn();
    super.initState();
  }

  void checkIfLocationOn() async {
    var serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }
    checkPermission();
  }

  void checkPermission() async {
    var permissionGrandted = await location.hasPermission();
    if (permissionGrandted == PermissionStatus.denied) {
      permissionGrandted = await location.requestPermission();
      if (permissionGrandted == PermissionStatus.granted) {
        LocationData updatedLocation = await location.getLocation();
        setState(() {
          currentLocation = updatedLocation;
          isLoading = false;
        });
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: <Widget>[
                GestureDetector(
                    onPanUpdate: null,
                    onPanEnd: null,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                          target: LatLng(currentLocation.latitude!,
                              currentLocation.longitude!),
                          zoom: 35),
                      myLocationEnabled: true,
                      mapToolbarEnabled: true,
                      myLocationButtonEnabled: true,
                      trafficEnabled: true,
                    )),
              ],
            ),
    );
  }
}
