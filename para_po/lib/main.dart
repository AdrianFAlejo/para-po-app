import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:para_po/screens/home_page.dart';
import 'package:para_po/screens/map/directions_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelGroupKey: 'notification_channel_group',
        channelKey: 'scheduled', 
        channelName: 'notification_channel', 
        channelDescription: 'channel for notification')
    ],
    channelGroups: [
      NotificationChannelGroup(
        channelGroupKey: 'notification_channel_group', 
        channelGroupName: 'notification_channel_group')
    ]
  );
  bool isAllowedNotification = await AwesomeNotifications().isNotificationAllowed();
  if(!isAllowedNotification){
    AwesomeNotifications().requestPermissionToSendNotifications();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
@override
Widget build(BuildContext context) {
  return FutureBuilder<Widget>(
    future: checkSelectedBus(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        // Show a loading indicator while waiting for the future to complete
        return CircularProgressIndicator();
      } else if (snapshot.hasError) {
        // Handle any errors that occurred during the future execution
        return Text('Error: ${snapshot.error}');
      } else {
        // Return the widget based on the future result
        return MaterialApp(
          title: 'Para Po',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSwatch(
              primarySwatch: Colors.blue,
              accentColor: Colors.white,
              backgroundColor: Colors.grey,
              cardColor: Colors.white,
              errorColor: Colors.red,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          home: snapshot.data ?? Container(), // Ensure a valid widget is returned
        );
      }
    },
  );
}

Future<Widget> checkSelectedBus() async {
  SharedPreferences info = await SharedPreferences.getInstance();
  String savedBusNumber = info.getString('busNumber') ?? '';
  double? savedLat = double.tryParse(info.getString('prevLat') ?? '');
  double? savedLng = double.tryParse(info.getString('prevLng') ?? '');

  if (savedBusNumber == '') {
    return const HomePage();
  } else {
    return MapPage(
      busNumber: savedBusNumber,
      busLat: savedLat ?? 0.0,
      busLng: savedLng ?? 0.0,
    );
  }
}
}
