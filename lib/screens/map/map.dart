import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Map extends StatefulWidget {
  const Map({super.key});

  @override
  State<Map> createState() => _MapState();
}

const kGoogleApiKey = "AIzaSyACyZcjQBMmrjdaX5yK0piILmwTI0d-SGc";
// GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: kGoogleApiKey);

class _MapState extends State<Map> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          GestureDetector(
            onPanUpdate: null,
            onPanEnd: null,
            child: GoogleMap(initialCameraPosition: CameraPosition(target: LatLng(37.43296265331129, -122.08832357078792),),)// Center(child: Text("Sample"))
            
              // GoogleMap(
              // onCameraMove: _manager.onCameraMove,
              // zoomControlsEnabled: true,
              // zoomGesturesEnabled: true,
              // myLocationEnabled: false,
              // myLocationButtonEnabled: false,
              // mapToolbarEnabled: false,
              // mapType: MapType.normal,
              // initialCameraPosition: CameraPosition(
              //   target: 
              //           14.75400000,
              //           120.95560000),
              //   zoom:  -5,
              // ),
              // polygons: _polygons,
              // polylines: _polyLines,
              // // markers: Set<Marker>.of(_markers),
              // markers: _markersSet,
              // onMapCreated: (GoogleMapController controller) async {
              //   mapController = controller;
              //   _manager.setMapId(controller.mapId);
              //   _controller.complete(controller);
              // },
              // onCameraIdle: _manager.updateMap,
              // onCameraMove: (position) => _updateMarkers(position.zoom),
            ),
        ],
      ),
    );
  }
}