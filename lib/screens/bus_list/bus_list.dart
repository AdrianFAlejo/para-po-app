import 'package:flutter/material.dart';

class BusList extends StatefulWidget {
  const BusList({super.key});

  @override
  State<BusList> createState() => _BusListState();
}

class _BusListState extends State<BusList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child:  Text('Available Busses')),
        backgroundColor:Colors.lightGreen,
      ),
      backgroundColor: Colors.white,
            body: ListView.builder(
        itemCount: 10, // Replace with the actual number of buses
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.all(8),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 2), // changes position of shadow
                ),
              ],
            ),
            child: ListTile(
              title: Text('Bus ${index + 1} | {Plate No.}'),
              subtitle: const Text('Destination: Example Destination'),
              trailing: const Text("Text"),//const Expanded(child: Row(children: <Widget> [ Text("40 mins away") , Text("8 km away")],)),
              onTap: () {
                // Handle bus item tap
              },
            ),
          );
        },
      ),
    );
  }
}