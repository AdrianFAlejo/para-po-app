import 'package:flutter/material.dart';
import 'package:para_po/screens/sign_up/sign_up.dart';
import 'package:para_po/screens/map/map.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utilities/constants/constants.dart' as constants;

//This file redirect the user on Map component if the driver information is existing,
//else it will redirect the user to driver form
class RouteGate extends StatefulWidget {
  const RouteGate({super.key});

  @override
  State<RouteGate> createState() => _RouteGateState();
}

class _RouteGateState extends State<RouteGate> {
  @override
  void initState() {
    super.initState();
    checkUsername();
  }

  void checkUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? driverName = prefs.getString(constants.DRIVER_NAME);

    if (driverName == null || driverName.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SignUp()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Map()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(), // Placeholder while checking
      ),
    );
  }
}