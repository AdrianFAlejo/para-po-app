import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:para_po/screens/home_page.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelGroupKey: 'notification_channel_group',
        channelKey: 'notification_channel', 
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
    return MaterialApp(
      title: 'Para Po',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue, // Using blue as primary swatch
          accentColor: Colors.white, // White as accent color
          backgroundColor: Colors.grey, // Grey as background color
          cardColor: Colors.white, // White as card color
          errorColor: Colors.red, // Red as error color
          brightness: Brightness.light, // Light theme
          ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
