import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter/services.dart';
import 'package:para_po/screens/bus_list/bus_list.dart';
import 'package:image/image.dart' as img; // Import image package for resizing

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  MapPageState createState() => MapPageState();
} 
class MapPageState extends State<MapPage> {

     @override
   void initState() {
      super.initState();
      // setCustomMapPin();
   }
  BitmapDescriptor pinLocationIcon = BitmapDescriptor.defaultMarker;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PARA PO', style: TextStyle(color: Colors.white),),
                actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.directions_bus, color: Colors.white,),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const BusList()));
            },
          ),
        ],
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor:Colors.blueGrey,
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
            child: isMarkerOnMap(const MarkerId("PickUpPoint")) ?
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.directions_bus, color: Colors.blue, size: 36),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        busName,
                        style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bus Number: $busNumber',
                        style: const TextStyle(color: Colors.black),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Location: $busLocation',
                        style: const TextStyle(color: Colors.black),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.grey, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '$minutesAway mins away',
                            style: const TextStyle(color: Colors.black),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.location_on, color: Colors.grey, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${kmAway.round()} km away',
                            style: const TextStyle(color: Colors.black),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            )
            : Container()
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
    _addMarker( const LatLng(14.8361, 120.2827)); // Point A
    _addMarker( const LatLng(15.0521, 120.6989)); // Po  int B
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

  Future<BitmapDescriptor> getCustomBusIcon() async {
    // Read the bytes of the image asset
    ByteData byteData = await rootBundle.load('assets/images/pinned-loc.png');
    Uint8List imageData = byteData.buffer.asUint8List();

    // Resize the image to the desired dimensions
    img.Image? image = img.decodeImage(imageData);
    img.Image resizedImage = img.copyResize(image!, width: 150, height: 150); // Adjust dimensions as needed
    Uint8List resizedImageData = Uint8List.fromList(img.encodePng(resizedImage));

    // Create BitmapDescriptor from the resized image bytes
    return BitmapDescriptor.fromBytes(resizedImageData);
  }

  void _addPickUpPoint(LatLng position) async {
    Marker marker = Marker(
      markerId: const MarkerId("PickUpPoint"),
      position: position,
      icon : await getCustomBusIcon()
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
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
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