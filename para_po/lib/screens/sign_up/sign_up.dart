import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:para_po/screens/route_gate/route_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utilities/constants/constants.dart' as constants;

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignupState();
}

class _SignupState extends State<SignUp> {

  final _formKey = GlobalKey<FormBuilderState>();
  
  List<String> busRoutes = ['SM City Pampanga', 'SM City Olongapo'];

  String selectedBusRoute = 'SM City Pampanga'; // Default selected value


  void setDriverDetails() async {
    final formData = _formKey.currentState?.value;
    
    bool isOnGoing = selectedBusRoute == 'SM City Pampanga';

    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString(constants.DRIVER_NAME, formData?[constants.DRIVER_NAME]);
    await prefs.setString(constants.BUS_NUMBER, formData?[constants.BUS_NUMBER]);
    await prefs.setString(constants.BUS_PLATE_NUMBER, formData?[constants.BUS_PLATE_NUMBER]);
    await prefs.setBool('isOnGoing', isOnGoing);

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const RouteGate()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.blueGrey,
        body: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.5,
                child: FormBuilder(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Register Bus',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 35,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      FormBuilderTextField(
                        name: constants.DRIVER_NAME,
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                          labelText: 'Driver Name',
                        ),
                          validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Driver Name is required";
                          }
                          return null;
                        },
                      ),
                      FormBuilderTextField(
                        name: constants.BUS_NUMBER,
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                          labelText: 'Bus Number',
                        ),
                          validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Bus Number is required";
                          }
                          return null;
                        },
                      ),
                      FormBuilderTextField(
                        name: constants.BUS_PLATE_NUMBER,
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                          labelText: 'Plate Number',
                        ),
                          validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Plate Number is required";
                          }
                          return null;
                        },
                      ),
                      FormBuilderDropdown(
                      name: 'busRoute',
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                        labelText: 'Select Bus Route',
                      ),
                      initialValue: selectedBusRoute,
                      items: busRoutes
                          .map((route) => DropdownMenuItem(
                                value: route,
                                child: Text(route),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedBusRoute = value.toString();
                        });
                      },
                    ),
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                          ),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                                _formKey.currentState?.save();
                                setDriverDetails();
                              }
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [Text("Register")],
                          ))
                    ],
                  ),
                )),
          ],
        )));
  }
}
