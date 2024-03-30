import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter/services.dart';
import 'package:para_po/screens/bus_list/bus_list.dart';
import 'package:image/image.dart' as img; // Import image package for resizing
import 'package:para_po/screens/map/map.dart';
import '../../utilities/constants/constants.dart' as constants;
import 'package:http/http.dart' as http;

class MapPage extends StatefulWidget {
  final String busNumber;
  final double busLat;
  final double busLng;

  const MapPage({super.key, required this.busNumber,  required this.busLat, required this.busLng});

  @override
  MapPageState createState() => MapPageState();
} 
class MapPageState extends State<MapPage> {

   @override
   void initState() {
      super.initState();
   }
  BitmapDescriptor pinLocationIcon = BitmapDescriptor.defaultMarker;
  late GoogleMapController _controller;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  PolylinePoints polylinePoints = PolylinePoints();
  PolylinePoints busPolylinePoints = PolylinePoints();

  double tappedLat = 0.0;
  double tappedLng = 0.0;

  dynamic minutesAway;
  dynamic kmAway;
  dynamic busAddress = 'Loading address...';

  late Object busInfo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Directions Service', style: TextStyle(color: Colors.white),),
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
        leading: IconButton(
            icon: const Icon(Icons.home, color: Colors.white),
            onPressed: () {
              // Your custom function here
              // For example:
              Navigator.push(context, MaterialPageRoute(builder: (context) => const MapScreen())); // Navigate to home screen
            },
          ),
        backgroundColor:Colors.blueGrey,
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            onTap: _onTap,
            mapType: MapType.normal,
            myLocationEnabled: true,
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.busLat, widget.busLng),
              zoom: 15,
            ),
            markers: _markers,
            polylines: _polylines,
          ),
          StreamBuilder(
            stream: FirebaseFirestore.instance.collection('location').where(constants.BUS_NUMBER, isEqualTo: widget.busNumber).snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if(!snapshot.hasData){
                return const Center(child: CircularProgressIndicator());
              }
                snapshot.data!.docChanges.forEach((change) async {
                  if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
                  Map<String, dynamic> data = change.doc.data() as Map<String, dynamic>;
                    _addBusMarker(LatLng(widget.busLat, widget.busLng), MarkerId(widget.busNumber));
                    _updatingPolyline(LatLng(data[constants.LATITUDE], data[constants.LONGITUDE]), data[constants.IS_ON_GOING]);
                    getAddress(data[constants.LATITUDE], data[constants.LONGITUDE]);
                    isMarkerOnMap(const MarkerId("PickUpPoint")) ? fetchRouteInfo(PointLatLng(widget.busLat, widget.busLng), PointLatLng(tappedLat, tappedLng)) : null;
                  }
                });
              return Positioned(
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
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${snapshot.data!.docs.singleWhere((element) => element.get(constants.BUS_NUMBER) == widget.busNumber)[constants.BUS_PLATE_NUMBER]}',
                                style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Driver name: ${snapshot.data!.docs.singleWhere((element) => element.get(constants.BUS_NUMBER) == widget.busNumber)[constants.DRIVER_NAME]}',
                                style: const TextStyle(color: Colors.black),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Bus number: ${snapshot.data!.docs.singleWhere((element) => element.get(constants.BUS_NUMBER) == widget.busNumber)[constants.BUS_NUMBER]}',
                                style: const TextStyle(color: Colors.black),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                busAddress,
                                style: const TextStyle(color: Colors.black),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, color: Colors.grey, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$minutesAway away from your pin',
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, color: Colors.grey, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$kmAway away from your pin',
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                  : const SizedBox()
              );
            }
          )
        ],
      ),
    );
  }

  //Implementing markers and polylines in map screen
  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      _controller = controller;
    });
    // Add markers
    _addMarker( const LatLng(constants.SM_OLONGAPO_LATITUDE, constants.SM_OLONGAPO_LONGITUDE)); // Point A
    _addMarker( const LatLng(constants.SM_PAMPANGA_LATITUDE, constants.SM_PAMPANGA_LONGITUDE)); // Po  int B
  }

  //Adding markers to the map
  void _addBusMarker(LatLng position, MarkerId id) async {
    BitmapDescriptor customIcon = await getCustomBusMarkerIcon();
  print("adding marker ${isMarkerOnMap(id)}");
    if(isMarkerOnMap(id)){ 
        setState(() {
          // Remove the old marker from the set
          _markers.removeWhere((marker) => marker.markerId == id);
          Marker marker = Marker(
            markerId: id,
            position: position,
            icon : customIcon
          );
          setState(() {
            _markers.add(marker);
          });
        });
    } 
    else {
      Marker marker = Marker(
        markerId: id,
        position: position,
        icon : customIcon
      );
      setState(() {
        _markers.add(marker);
      });
    }
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

  //Putting the polylines of the map to location in screen
  void _addBusPolyLine(List<LatLng> polylineCoordinates) {
    PolylineId id = const PolylineId("BusPolyline");
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

  Future<void> _updatingPolyline(LatLng busPosition, bool isOngoing) async {
    LatLng destination = isOngoing ? const LatLng(constants.SM_OLONGAPO_LATITUDE, constants.SM_OLONGAPO_LONGITUDE) : const LatLng(constants.SM_PAMPANGA_LATITUDE, constants.SM_PAMPANGA_LONGITUDE); 
    print("markers position : $busPosition $destination");

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      constants.GOOLE_API_KEY, // Google Map API Key
      PointLatLng(busPosition.latitude, busPosition.longitude),
      PointLatLng(destination.latitude, destination.longitude),
      travelMode: TravelMode.transit,
    );
    
    if (result.points.isNotEmpty) {
      List<LatLng> polylineCoordinates = [];
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
      _addBusPolyLine(polylineCoordinates);
    } else {
      print(result.errorMessage);
    }
  }

  // Fetching how many minutes and kilometers away
  Future<void> fetchRouteInfo(PointLatLng origin, PointLatLng destination) async {
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=${constants.GOOLE_API_KEY}';
    
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final routes = data['routes'] as List<dynamic>;
      if (routes.isNotEmpty) {
        final legs = routes[0]['legs'] as List<dynamic>;
        if (legs.isNotEmpty) {
          final distance = legs[0]['distance']['text'];
          final duration = legs[0]['duration']['text'];
          print('Distance: $distance, Duration: $duration');
          setState(() {
            minutesAway = duration;
            kmAway = distance;
          });
        }

      }
    } else {
      throw Exception('Failed to load route info');
    }
  }

  // Getting the address of the bus  
  Future<void> getAddress(double latitude, double longitude) async {
    final url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=${constants.GOOLE_API_KEY}';

    print("address url : ${url}");
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data['status'] == 'OK') {
        final results = data['results'] as List<dynamic>;
        if (results.isNotEmpty) {
          print('address ${data['results'][3]['formatted_address']}' );
          setState(() {
              busAddress = data['results'][3]['formatted_address'];
          });
          // String formattedAddress = results[0]['formatted_address'];
          // return data['results'][3]['formatted_address'];
        }

      }
    } else {
          throw Exception('Failed to get address');
    }
    

  }

  //Creating custom icon for markers
  Future<BitmapDescriptor> getCustomBusMarkerIcon() async {
    // Read the bytes of the image asset
    ByteData byteData = await rootBundle.load('assets/images/marker-icon.png');
    Uint8List imageData = byteData.buffer.asUint8List();

    // Resize the image to the desired dimensions
    img.Image? image = img.decodeImage(imageData);
    img.Image resizedImage = img.copyResize(image!, width: 80, height: 120); // Adjust dimensions as needed
    Uint8List resizedImageData = Uint8List.fromList(img.encodePng(resizedImage));

    // Create BitmapDescriptor from the resized image bytes
    return BitmapDescriptor.fromBytes(resizedImageData);
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

  //onTap function for creating a pickup point
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
    print('my tapped location : ${tapLatLng}');
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
      setState(() {
        tappedLat = tapLatLng.latitude;
        tappedLng = tapLatLng.longitude;
      });
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

  // Function to estimate time in minutes based on average speed (e.g., 30 km/h)
  int estimateTime(double distanceInKm, double averageSpeedKmph) {
    if (averageSpeedKmph <= 0) return 0;
    return (distanceInKm / averageSpeedKmph * 60).round();
  }
}