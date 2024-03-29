import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../utilities/constants/constants.dart' as constants;

class BusList extends StatefulWidget {
  const BusList({super.key});

  @override
  State<BusList> createState() => _BusListState();
}

class _BusListState extends State<BusList> {
  final String pointA = "SM City Pampanga";
  final String pointB = "SM City Pampanga";
  final String isOngoing = "isOnGoing"; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Busses', style: TextStyle(color: Colors.white),),
        backgroundColor:Colors.blueGrey,
        centerTitle: true,
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
                      offset: const Offset(0, 2), // changes position of shadow
                    ),
                  ],
                ),
                child: ListTile(
                  title: Text('Bus ${snapshot.data!.docs[index][constants.BUS_NUMBER]} | ${snapshot.data!.docs[index][constants.BUS_PLATE_NUMBER]}'),
                  subtitle: snapshot.data!.docs[index][isOngoing] ? Text(pointB) : Text(pointA),
                  trailing: const Text("Text"),//const Expanded(child: Row(children: <Widget> [ Text("40 mins away") , Text("8 km away")],)),
                  onTap: () {
                    // Handle bus item tap
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