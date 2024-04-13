import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:para_po/screens/map/directions_service.dart';
import 'package:para_po/screens/map/map.dart';
import '../../utilities/constants/constants.dart' as constants;

class BusList extends StatefulWidget {
  const BusList({super.key});

  @override
  State<BusList> createState() => _BusListState();
}

class _BusListState extends State<BusList> {
  final String pointA = "SM City Pampanga Terminal";
  final String pointB = "SM Olongapo Terminal";
  final String isOngoing = "isOnGoing"; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Busses', style: TextStyle(color: Colors.white),),
        backgroundColor:Colors.blueGrey,
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Colors.white, // Change the color here
        ),
      ),
      backgroundColor: Colors.white,
            body: StreamBuilder<Object>(
              stream: FirebaseFirestore.instance.collection('location').snapshots(),
              builder: (context, AsyncSnapshot snapshot) {
                if(!snapshot.hasData){
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView.builder(
                        itemCount: snapshot.data?.docs.length,
                        itemBuilder: (context, index) {
                          return Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: const Icon(Icons.directions_bus), 
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plate Number: ${snapshot.data!.docs[index][constants.BUS_PLATE_NUMBER]}',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Bus Number: ${snapshot.data!.docs[index][constants.BUS_NUMBER]}',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Driver: ${snapshot.data!.docs[index][constants.DRIVER_NAME]}',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  subtitle: snapshot.data!.docs[index][constants.IS_ON_GOING] 
                    ? Text('Location: $pointB')
                    : Text('Location: $pointA'),
                  onTap: () {
                     String busNumber = snapshot.data!.docs[index][constants.BUS_NUMBER];
                     double busLat = snapshot.data!.docs[index][constants.LATITUDE];
                     double busLng = snapshot.data!.docs[index][constants.LONGITUDE];
                    // 
                     Navigator.push(context, MaterialPageRoute(builder: (context) => MapPage(busNumber : busNumber, busLat: busLat, busLng: busLng))); 
                  },
                ),
              );
            },
          );
        }
      ),
    );
  }
}