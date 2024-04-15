import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:para_po/utilities/constants/constants.dart' as constants;
import 'package:shared_preferences/shared_preferences.dart';

class Map extends StatefulWidget {
  const Map({super.key});

  @override
  State<Map> createState() => _MapState();
}

class _MapState extends State<Map> {
  String? driverName;
  String? busNum;
  String? busPlateNum;

  Location locationController = Location();
  LatLng? currentLocation;
  
  String pointA = "SM City Olongapo";
  String pointB = "SM City Pampanga";

  LatLng pointALocation =  const LatLng(14.8361, 120.2827);
  LatLng pointBLocation = const LatLng(15.0521, 120.6989);

  bool isOnGoing = true;

  final Completer<GoogleMapController> mapController =
      Completer<GoogleMapController>();

  List<LatLng> polylineCoordinates = [];

  @override
  void initState() {
    getLocationUpdates();
    getPolyPoints();
    getBusDetails();
    super.initState();
  }

  Future<void> getLocationUpdates() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await locationController.serviceEnabled();
    if (serviceEnabled) {
      serviceEnabled = await locationController.requestService();
    } else {
      return;
    }

    permissionGranted = await locationController.hasPermission();
    {
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await locationController.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          return;
        }
      }
    }

    locationController.onLocationChanged.listen((LocationData locationData) {
      if (locationData.latitude != null && locationData.longitude != null) {
        setState(() {
          currentLocation =
              LatLng(locationData.latitude!, locationData.longitude!);
          cameraToPosition(currentLocation!);
        });
      }
    });
  }

  Future<void> cameraToPosition(LatLng position) async {
    final GoogleMapController controller = await mapController.future;
    CameraPosition newCameraPosition =
        CameraPosition(target: position, zoom: 10);
    await controller
        .animateCamera(CameraUpdate.newCameraPosition(newCameraPosition));
    //pass new data to firebase
    try {      
      await FirebaseFirestore.instance.collection('location').doc(busNum).set({
        "lat": position.latitude,
        "long": position.longitude,
        "driverName": driverName,
        "busNum": busNum,
        "busPlateNum": busPlateNum,
        "isOnGoing": isOnGoing
      });
    } catch (e) {
      print(e);
    }
  }

  void getPolyPoints() async {
    PolylinePoints polylinePoints = PolylinePoints();

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      constants.GOOLE_API_KEY,
      PointLatLng(pointALocation.latitude, pointALocation.longitude),
      PointLatLng(pointBLocation.latitude, pointBLocation.longitude),
      travelMode: TravelMode.transit,
      avoidTolls: true,
      optimizeWaypoints: true,
      );
    
    if(result.points.isNotEmpty){
      for (var point in result.points) {
        polylineCoordinates.add(
        LatLng(point.latitude, point.longitude)
      );
      }
    }
  }

  void getBusDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    driverName = prefs.getString(constants.DRIVER_NAME);
    busNum = prefs.getString(constants.BUS_NUMBER);
    busPlateNum = prefs.getString(constants.BUS_PLATE_NUMBER);

    setState(() {
      isOnGoing = prefs.getBool('isOnGoing') ?? true; 
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: <Widget>[
                GoogleMap(
                  onMapCreated: ((GoogleMapController controller) =>
                      mapController.complete(controller)),
                  initialCameraPosition:
                      CameraPosition(target: currentLocation!, zoom: 10),
                  polylines: {
                    Polyline(
                      polylineId: PolylineId("route"),
                      points: polylineCoordinates,
                      color: Colors.blueGrey,
                      width: 6
                    )
                  },
                  markers: {
                    Marker(
                        markerId: const MarkerId("currentLocation"),
                        icon: BitmapDescriptor.defaultMarker,
                        position: (currentLocation!)),
                    Marker(
                      markerId: const MarkerId("pointALocation"),
                      icon: BitmapDescriptor.defaultMarker,
                      position: (pointALocation)),
                    Marker(
                      markerId: const MarkerId("pointBLocation"),
                      icon: BitmapDescriptor.defaultMarker,
                      position: (pointBLocation)),
                  },
                ),
                Container(
                    padding: const EdgeInsets.all(5),
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: const BoxDecoration(
                    borderRadius:BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
                    color: Colors.white,
                    boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 3,
                      offset: Offset(0, 6), // Shadow position
                    ),
                  ],
                  ),
                  child: SafeArea(
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(Icons.circle_outlined, color: Colors.blueGrey, size: 20),
                                Icon(Icons.more_vert, color: Colors.blueGrey, size: 20,),
                                Icon(Icons.location_on_rounded, color: Colors.blueGrey, size: 20,)
                              ],
                          ),
                          Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              verticalDirection: isOnGoing? VerticalDirection.up : VerticalDirection.down,
                              children: <Widget>[
                                Container(
                                  width: MediaQuery.of(context).size.width * 0.7,
                                  padding: const EdgeInsets.all(5),
                                  margin: const EdgeInsets.symmetric(vertical: 2.5),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                      border: Border.all(color: Colors.blueGrey),
                                      borderRadius: const BorderRadius.all(Radius.circular(5)),
                                      color: Colors.white
                                  ),
                                  child: Text(
                                     pointA,
                                    style: const TextStyle(
                                        fontSize: 12.0,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w200,
                                        fontFamily: "Roboto"),
                                  ),
                                ),
                                Container(
                                  width: MediaQuery.of(context).size.width * 0.7,
                                  padding: const EdgeInsets.all(5),
                                  margin: const EdgeInsets.symmetric(vertical: 2.5),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                      border: Border.all(color: Colors.blueGrey),
                                      borderRadius: const BorderRadius.all(Radius.circular(5)),
                                      color: Colors.white
                                  ),
                                  child: Text(
                                    pointB,
                                    style: const TextStyle(
                                        fontSize: 12.0,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w200,
                                        fontFamily: "Roboto"),
                                  ),
                                ),
                              ]),
                            IconButton(
                              iconSize: 50,
                              onPressed: () async {
                                SharedPreferences prefs = await SharedPreferences.getInstance();
                                prefs.setBool('isOnGoing', !isOnGoing);
                                setState(() {
                                  isOnGoing = !isOnGoing;
                                });
                              },
                              icon: const Icon(Icons.swap_vert_sharp, color: Colors.blueGrey,))
                        ]),
                  ),
                ),
              ],
            ),
    );
  }
}
