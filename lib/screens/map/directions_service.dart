// ignore_for_file: unused_import

import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart';
import 'package:geocoding/geocoding.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;
import 'package:flutter/services.dart';
// import 'package:para_po/screens/map/widet_to_map_icon.dart'; // Import flutter/services.dart

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  _MapPageState createState() => _MapPageState();
} 



class _MapPageState extends State<MapPage> {

     @override
   void initState() {
      super.initState();
      // setCustomMapPin();
   }
  BitmapDescriptor pinLocationIcon = BitmapDescriptor.defaultMarker;
  //  void setCustomMapPin() async {
  //     pinLocationIcon = await BitmapDescriptor.fromAssetImage(
  //     ImageConfiguration(devicePixelRatio: 2.5),
  //     'assets/bus-icon.png');
  //  }
  late GoogleMapController _controller;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  PolylinePoints polylinePoints = PolylinePoints();
  String googleAPiKey = "AIzaSyBt04ZkRZ8kgz6c0eb3nhUCCCAjbUnqNHQ";
  // Sample data for bus information
  String busName = 'Sample Bus';
  String busNumber = '123';
  String busLocation = 'Sample Location';
  int minutesAway = 10;
  double kmAway = 20.0;

  //   Future<BitmapDescriptor> createCustomMarkerBitmap() async {
  //   // Load bus icon image asset
  //   ByteData imageData = await rootBundle.load('assets/images/bus-con.png');
  //   List<int> byteData = imageData.buffer.asUint8List();  // Convert ByteData to List<int>

  //   // Resize image
  //   // Resize image
  //   List<int> resizedImageData = await FlutterImageCompress.compressWithList(
  //     byteData,
  //     minHeight: height,
  //     minWidth: width,
  //     quality: 100, // You can adjust the quality if needed
  //   );

  //   // Convert resized image data to Uint8List
  //   Uint8List resizedImageDataUint8 = Uint8List.fromList(resizedImageData);

  //   return BitmapDescriptor.fromBytes(resizedImageDataUint8);
  // } 

  //   Future<BitmapDescriptor> createCustomMarkerBitmap(String imagePath, int width, int height) async {
  //   ByteData imageData = await rootBundle.load(imagePath);
  //   List<int> byteData = imageData.buffer.asUint8List(); // Convert ByteData to List<int>

  //   // Resize image
  //   List<int> resizedImageData = await FlutterImageCompress.compressWithList(
  //     byteData,
  //     minHeight: height,
  //     minWidth: width,
  //     quality: 100, // You can adjust the quality if needed
  //   );

  //   // Convert resized image data to Uint8List
  //   Uint8List resizedImageDataUint8 = Uint8List.fromList(resizedImageData);

  //   return BitmapDescriptor.fromBytes(resizedImageDataUint8);
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PARA PO'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor:Colors.lightGreen,
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            onTap: _onTap,
            mapType: MapType.normal,
            myLocationEnabled: true,
            initialCameraPosition: const CameraPosition(
              target: LatLng(14.8361, 120.2827),
              zoom: 15,
            ),
            markers: _markers,
            polylines: _polylines,
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 7,
                    offset: Offset(0, 3), // changes position of shadow
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.directions_bus, color: Colors.blue, size: 36),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$busName',
                        style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Bus Number: $busNumber',
                        style: TextStyle(color: Colors.black),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Location: $busLocation',
                        style: TextStyle(color: Colors.black),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, color: Colors.grey, size: 16),
                          SizedBox(width: 4),
                          Text(
                            '$minutesAway mins away',
                            style: TextStyle(color: Colors.black),
                          ),
                          SizedBox(width: 16),
                          Icon(Icons.location_on, color: Colors.grey, size: 16),
                          SizedBox(width: 4),
                          Text(
                            '${kmAway.round()} km away',
                            style: TextStyle(color: Colors.black),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      _controller = controller;
    });
    // Add markers
    _addMarker(LatLng(14.8361, 120.2827)); // Point A
    _addMarker(LatLng(15.0521, 120.6989)); // Po  int B
    // Fetch and draw polyline
    _getPolyline();
  }

  void _addMarker(LatLng position) {
    Marker marker = Marker(
      markerId: MarkerId(position.toString()),
      position: position,
    );
    setState(() {
      _markers.add(marker);
    });
  }

  // Future<BitmapDescriptor> getCustomIcon() async {
  //   return SizedBox(
  //     height: 200,
  //     width: 200,
  //     child: Image.asset("temp image"),
  //   ).toBitmapDescriptor();
  // }

    void _addPickUpPoint(LatLng position) async {
    Marker marker = Marker(
      markerId: const MarkerId("PickUpPoint"),
      position: position,
      // icon: await getCustomIcon(),
    );
    setState(() {
      _markers.add(marker);
    });
  }

  // Function to calculate distance in kilometers between two LatLng points using Haversine formula
  double calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371.0; // Earth's radius in kilometers
    double lat1Radians = start.latitude * (pi / 180);
    double lat2Radians = end.latitude * (pi / 180);
    double deltaLat = (end.latitude - start.latitude) * (pi / 180);
    double deltaLon = (end.longitude - start.longitude) * (pi / 180);

    double a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1Radians) * cos(lat2Radians) * sin(deltaLon / 2) * sin(deltaLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  // Function to estimate time in minutes based on average speed (e.g., 50 km/h)
  int estimateTime(double distanceInKm, double averageSpeedKmph) {
    if (averageSpeedKmph <= 0) return 0;
    return (distanceInKm / averageSpeedKmph * 60).round();
  }


  void _addPolyLine(List<LatLng> polylineCoordinates) {
    PolylineId id = const PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.blue,
      points: polylineCoordinates,
      width: 10,
    );
    setState(() {
      _polylines.add(polyline);
    });
  }

  Future<void> _getPolyline() async {
    LatLng firstMarkerLatLng = _markers.first.position;
    LatLng lastMarkerLatLng = _markers.last.position;
    print("markers $_markers : $firstMarkerLatLng $lastMarkerLatLng");

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleAPiKey, // Google Map API Key
      PointLatLng(firstMarkerLatLng.latitude, firstMarkerLatLng.longitude),
      PointLatLng(lastMarkerLatLng.latitude, lastMarkerLatLng.longitude),
      travelMode: TravelMode.transit,
    );
    
    if (result.points.isNotEmpty) {
      List<LatLng> polylineCoordinates = [];
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
      _addPolyLine(polylineCoordinates);
    } else {
      print(result.errorMessage);
    }
  }

  bool isMarkerOnMap(MarkerId markerId) {
    for (Marker marker in _markers) {
      if (marker.markerId == markerId) {
        return true;
      }
    }
    return false;
  }

  void _onTap(LatLng tapLatLng) {
    bool isOnPolyline = _isLocationOnPolyline(tapLatLng, _polylines.first.points);
    if (isOnPolyline){
      if(isMarkerOnMap(const MarkerId("PickUpPoint"))){
          setState(() {
            // Remove the old marker from the set
            _markers.removeWhere((marker) => marker.markerId == const MarkerId("PickUpPoint"));
            _addPickUpPoint(tapLatLng);
          });
      } else {
        _addPickUpPoint(tapLatLng);
      }

    }
  }

  bool _isLocationOnPolyline(LatLng tapLatLng, List<LatLng> polylineCoordinates) {
    double tolerance = 0.005; // Tolerance value for checking proximity
    for (int i = 0; i < polylineCoordinates.length - 1; i++) {
      LatLng start = polylineCoordinates[i];
      LatLng end = polylineCoordinates[i + 1];
      double distance = _calculateDistance(start, end);
      double distanceFromStart = _calculateDistance(start, tapLatLng);
      double distanceFromEnd = _calculateDistance(end, tapLatLng);
      if (distanceFromStart + distanceFromEnd - distance <= tolerance) {
        return true;
      }
    }
    return false;
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    double lat1 = point1.latitude;
    double lon1 = point1.longitude;
    double lat2 = point2.latitude;
    double lon2 = point2.longitude;
    double theta = lon1 - lon2;
    double distance = (sin(_deg2rad(lat1)) * sin(_deg2rad(lat2))) +
        (cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * cos(_deg2rad(theta)));
    distance = acos(distance);
    distance = _rad2deg(distance);
    distance *= 60 * 1.1515; // Convert to miles
    return distance;
  }

  double _deg2rad(double deg) {
    return deg * (pi / 180.0);
  }

  double _rad2deg(double rad) {
    return rad * (180.0 / pi);
  }
}