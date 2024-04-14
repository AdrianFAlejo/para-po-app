import 'dart:convert';
import 'dart:math';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:para_po/screens/bus_list/bus_list.dart';
import 'package:image/image.dart' as img; // Import image package for resizing
import '../../utilities/constants/constants.dart' as constants;
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../home_page.dart';

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
    _loadSavedData();
  }

  // Load saved data from SharedPreferences
  Future<void> _loadSavedData() async {

    SharedPreferences info = await SharedPreferences.getInstance();
    double? savedLat = double.tryParse(info.getString('prevLat') ?? '');
    double? savedLng = double.tryParse(info.getString('prevLng') ?? '');
    bool? hasSavedNotif = info.getBool('hasSavedNotif') ?? false;
    bool? isSavedNearby = info.getBool('isSavedNearby') ?? false;
    String? savedBusNumber = info.getString('busNumber');

    if(savedBusNumber == widget.busNumber){
      setState(() {
        tappedLat = savedLat ?? 0.0;
        tappedLng = savedLng ?? 0.0;
        hasNotif = hasSavedNotif;
        isNearby = isSavedNearby;
      });
      if(tappedLat != 0.0 && tappedLng != 0.0){
        _addPickUpPoint(LatLng(tappedLat, tappedLng));
        fetchRouteInfo(PointLatLng(widget.busLat, widget.busLng), PointLatLng(tappedLat, tappedLng));
      }
    }else{
      info.setBool('hasSavedNotif', false);
      info.setBool('isSavedNearby', false);
    }
  }

  // Save data to SharedPreferences
  Future<void> saveData(Map<String, String> data) async {
    SharedPreferences store = await SharedPreferences.getInstance();
    data.forEach((key, value) {
      store.setString(key, value);
    });
  }

  //reset hasSavedNotif to trigger add notif
  Future<void> returnHome() async {
    AwesomeNotifications().cancelAll();
    SharedPreferences info = await SharedPreferences.getInstance();
    info.setBool('hasSavedNotif', false);
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

  double lat = 15.036130714199096;
  double lng = 120.67860982275572;
  bool _functionsExecuted = false;
  bool hasNotif = false;
  bool isNearby = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Directions Service', style: TextStyle(color: Colors.white),),
                actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.directions_bus, color: Colors.white,),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BusList()))
          ),
        ],
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: IconButton(
            icon: const Icon(Icons.home, color: Colors.white),
            onPressed:
              () {
              showDialog(
                context: context, 
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.white,
                  title: const Text('Home'),
                  content: const Text("You'll lose track of your chosen bus if you navigate back to the homepage. Do you want to continue?"),
                  actions: [
                    TextButton(
                      child: const Text('No'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    TextButton(
                      child: const Text('Yes'),
                      onPressed: () => {
                        returnHome(),
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()))
                      }
                    )
                  ],
                ));
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
              for (var change in snapshot.data!.docChanges) {
                Map<String, dynamic> data = change.doc.data() as Map<String, dynamic>;
                
                if (change.type == DocumentChangeType.modified) {
                  _addBusMarker(LatLng(data[constants.LATITUDE], data[constants.LONGITUDE]), MarkerId(widget.busNumber));
                  // _updatingPolyline(LatLng(data[constants.LATITUDE], data[constants.LONGITUDE]), data[constants.IS_ON_GOING]);
                  _getAddressFromLatLng(data[constants.LATITUDE], data[constants.LONGITUDE]);
                  isMarkerOnMap(const MarkerId("PickUpPoint")) ? fetchRouteInfo(PointLatLng(data[constants.LATITUDE], data[constants.LONGITUDE]), PointLatLng(tappedLat, tappedLng)) : null;
                } 

                if (!_functionsExecuted) {
                  // Set the flag to true to indicate that the functions have been executed
                  _functionsExecuted = true;
                  // Execute the functions you want to run only once
                  _addBusMarker(LatLng(data[constants.LATITUDE], data[constants.LONGITUDE]), MarkerId(widget.busNumber));
                  // _updatingPolyline(LatLng(data[constants.LATITUDE], data[constants.LONGITUDE]), data[constants.IS_ON_GOING]);
                  _getAddressFromLatLng(data[constants.LATITUDE], data[constants.LONGITUDE]);
                }
              }
              return Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: isMarkerOnMap(const MarkerId("PickUpPoint")) ?
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 0, 0),
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
                    child: Stack(
                      children: [
                        Row(
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
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              deleteSavedLoc();
                            },
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
    _updatingPolyline(const LatLng(constants.SM_OLONGAPO_LATITUDE, constants.SM_OLONGAPO_LONGITUDE), false);
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


  bool _isPolylineExisting(PolylineId polylineId) {
    for (Polyline polyline in _polylines) {
      if (polyline.polylineId == polylineId) {
        return true;
      }
    }
    return false;
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

    // Remove old polyline from set
    if(_isPolylineExisting(PolylineId("BusPolyline"))){ 
      setState(() {
        _polylines.removeWhere((polyline) => polyline.polylineId == "BusPolyline");
      });
    }

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
      avoidTolls: true,
      optimizeWaypoints: true,
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

  int calculateTotalMinutes(String minutesAway) {
    // Split the string into individual parts
    List<String> parts = minutesAway.split(' ');

    int totalMinutes = 0;

    for (int i = 0; i < parts.length; i += 2) {
      int value = int.parse(parts[i]);
      String unit = parts[i + 1];

      // Convert hours to minutes
      if (unit.startsWith('h')) {
        totalMinutes += value * 60;
      }
      // Add directly for minutes
      else if (unit.startsWith('m')) {
        totalMinutes += value;
      }
    }

    return totalMinutes;
  }

  // Fetching how many minutes and kilometers away
  Future<void> fetchRouteInfo(PointLatLng origin, PointLatLng destination) async {
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=${constants.GOOLE_API_KEY}';
    
    final response = await http.get(Uri.parse(url));
    SharedPreferences store = await SharedPreferences.getInstance();

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final routes = data['routes'] as List<dynamic>;
      if (routes.isNotEmpty) {
        final legs = routes[0]['legs'] as List<dynamic>;
        print(legs);
        if (legs.isNotEmpty) {
          final distance = legs[0]['distance']['text'];
          final duration = legs[0]['duration']['text'];
          print('Distance: $distance, Duration: $duration');
          setState(() {
            minutesAway = duration;
            kmAway = distance;
          });

          int minutes = calculateTotalMinutes(minutesAway);

          if(minutes < 3 && !isNearby){
              await AwesomeNotifications().createNotification(
                content: NotificationContent(
                id: Random().nextInt(100),
                channelKey: 'scheduled',
                title: 'Almost there!',
                body: 'Your bus is nearby and will arrive at the pin you chose in any minute.',
            ));
            await AwesomeNotifications().cancelAllSchedules();
            store.setBool('isSavedNearby', true);
            setState(() {
              isNearby = true;
            });
          }
          
          //schedule an alarm 5 minutes before the bus arrival
          if(!hasNotif && minutes >= 6){
            DateTime notif = DateTime.now();

            await AwesomeNotifications().createNotification(
              content: NotificationContent(
                id: Random().nextInt(100),
                channelKey: 'scheduled',
                title: 'Get Ready',
                body: 'Your bus will arrive at the pin you chose in about 5 minutes.',
            ),
              schedule: NotificationCalendar.fromDate(date: notif.toLocal().add(Duration(minutes: minutes - 5)), preciseAlarm: true, allowWhileIdle: true)
            );

            setState(() {
              hasNotif = true;
            });
            
            store.setBool('hasSavedNotif', true);
          }
        }

      }
    } else {
      throw Exception('Failed to load route info');
    }
  }

  Future<void> _getAddressFromLatLng(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude); // Provide your latitude and longitude here
      if (placemarks != null && placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        print('placemark $placemark');
        String address = '${placemark.locality ?? ''}, ${placemark.subAdministrativeArea ?? ''}, ${placemark.country ?? ''}';
        setState(() {
          busAddress = address;
        });
      }
    } catch (e) {
      print(e);
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

  void _onTap(LatLng tapLatLng) async {
    bool isOnPolyline = _isLocationOnPolyline(tapLatLng, _polylines.first.points);
    print('my tapped location : ${tapLatLng}');
    if (isOnPolyline){
      await fetchRouteInfo(PointLatLng(widget.busLat, widget.busLng), PointLatLng(tapLatLng.latitude, tapLatLng.longitude));
      await saveData({
        'prevLat': tapLatLng.latitude.toString(),
        'prevLng': tapLatLng.longitude.toString(),
        'busNumber': widget.busNumber,
      });
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
        hasNotif = false;
      });
    }
  }

  void deleteSavedLoc() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.clear();
    AwesomeNotifications().cancelAll();
    setState(() {
      _markers.removeWhere((marker) => marker.markerId == const MarkerId("PickUpPoint"));
      tappedLat = 0.0;
      tappedLng = 0.0;
      hasNotif = false;
    }); 
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
    double calculateDistance(lat1, lon1, lat2, lon2){
      var p = 0.017453292519943295;
      var a = 0.5 - cos((lat2 - lat1) * p)/2 + 
            cos(lat1 * p) * cos(lat2 * p) * 
            (1 - cos((lon2 - lon1) * p))/2;
      return 12742 * asin(sqrt(a));
    }


  // Function to estimate time in minutes based on average speed (e.g., 30 km/h)
  int estimateTime(double distanceInKm, double averageSpeedKmph) {
    if (averageSpeedKmph <= 0) return 0;
    return (distanceInKm / averageSpeedKmph * 60).round();
  }
}