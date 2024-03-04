import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:para_po/screens/bus_list/bus_list.dart';

class Map extends StatefulWidget {
  const Map({super.key});

  @override
  State<Map> createState() => _MapState();
}

class _MapState extends State<Map> {
  // final Completer<GoogleMapController> _controller =
  //     Completer<GoogleMapController>();

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(15.0521, 120.6989),
    zoom: 14.4746,
  );

  @override
  Widget build(BuildContext context) {
return Scaffold(
      appBar: AppBar(
        title: const Center(child:  Text('Para po')),
        automaticallyImplyLeading: false, // Disable back button
        backgroundColor:Colors.lightGreen,
      ),
body: Stack(
        children: [
          const GoogleMap(
            initialCameraPosition: _kGooglePlex,
            mapType: MapType.normal,
            myLocationEnabled: true,
          ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Row(
              children: [
                Expanded(
                  child: Column(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      width: 280, // Adjust the width as needed
                      height: 30, // Adjust the height as needed
                      decoration: BoxDecoration(
                        color: Colors.white, // Background color
                        borderRadius: BorderRadius.circular(8),
                      // Rounded corners
                      ),
                      child: DropdownButton<String>(
                         isExpanded: true,
                        onChanged: (String? newValue) {
                          // Handle dropdown value change
                        },
                        items: <String>["Sm Pampanga to Olongapo", "Olongapo to Sm Pampanga"]
                        .map<DropdownMenuItem<String>>(
                          (String value) => DropdownMenuItem<String>(value: value, child: Text(value))
                        )
                        .toList(),
                        hint: const Text('Select a route'),
                      ),
                    ),
                    const SizedBox(height: 10,),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      width: 280, // Adjust the width as needed
                      height: 30, // Adjust the height as needed
                      decoration: BoxDecoration(
                        color: Colors.white, // Background color
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextFormField(
                          decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(vertical: 7), 
                          hintText: 'Enter your pickup point',
                          border: InputBorder.none,
                        ),
                      ),
                    )
                  ],),
                ),
                ElevatedButton(onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (context) => const BusList())); }, child: const Text("Bus List"))
              ],
            ),
          ),
        ],
      ),
    );
  }
}