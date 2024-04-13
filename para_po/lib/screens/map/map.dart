import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter/services.dart';
import 'package:para_po/screens/bus_list/bus_list.dart';
import 'package:image/image.dart' as img; // Import image package for resizing
import '../../utilities/constants/constants.dart' as constants;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  MapScreenState createState() => MapScreenState();
} 
class MapScreenState extends State<MapScreen> {

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
            mapType: MapType.normal,
            myLocationEnabled: true,
            initialCameraPosition: const CameraPosition(
              target: LatLng(14.8361, 120.2827),
              zoom: 15,
            ),
            markers: _markers,
            polylines: _polylines,
          ),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('location').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox();
              }

              snapshot.data!.docChanges.forEach((change) {
                if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
                  // Get the document data
                  Map<String, dynamic> data = change.doc.data() as Map<String, dynamic>;
                  double latitude = data[constants.LATITUDE];
                  double longitude = data[constants.LONGITUDE];
                  String markerId = data[constants.BUS_NUMBER];
                  _addBusMarker(LatLng(latitude, longitude), MarkerId(markerId));
                } 
                // Deleting bus if applicable
                // else if (change.type == DocumentChangeType.removed) {
                //   // Remove marker if document is removed
                //   String markerId = change.doc.id;
                //   Marker? markerToRemove = _markers.firstWhere(
                //     (marker) => marker.markerId.value == markerId,
                //     orElse: () => null,
                //   );2

                //   if (markerToRemove != null) {
                //     setState(() {
                //       _markers.remove(markerToRemove);
                //     });
                //   }
                // }
              }
              );

              return SizedBox(); // Return an empty SizedBox since we're just updating markers
            },
          ),
        ],
      ),
    );
  }

  bool isMarkerOnMap(MarkerId markerId) {
    for (Marker marker in _markers) {
      if (marker.markerId == markerId) {
        return true;
      }
    }
    return false;
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      _controller = controller;
    });
    // Add markers
    _addMarker( const LatLng(constants.SM_OLONGAPO_LATITUDE, constants.SM_OLONGAPO_LONGITUDE)); // Point A
    _addMarker( const LatLng(constants.SM_PAMPANGA_LATITUDE, constants.SM_PAMPANGA_LONGITUDE)); // Po  int B
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

  void _addBusMarker(LatLng position, MarkerId id) async {
    BitmapDescriptor customIcon = await getCustomBusIcon();
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
    } else {
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

  Future<BitmapDescriptor> getCustomBusIcon() async {
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
      constants.GOOLE_API_KEY, // Google Map API Key
      PointLatLng(firstMarkerLatLng.latitude, firstMarkerLatLng.longitude),
      PointLatLng(lastMarkerLatLng.latitude, lastMarkerLatLng.longitude),
      travelMode: TravelMode.transit,
      avoidTolls: true,
      optimizeWaypoints: true,
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

}