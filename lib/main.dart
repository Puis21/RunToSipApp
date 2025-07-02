import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:run_to_sip_app/Pages/home.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:run_to_sip_app/Pages/widget_tree.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:run_to_sip_app/Provider/UserProvider.dart';
import 'package:run_to_sip_app/services/NotificationService.dart';

import 'Pages/login_register_page.dart';
import 'Pages/run_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.initialize();


/*
  String? token = await FirebaseMessaging.instance.getToken();
  print('FCM Token: $token');
*/

  //FOR PHONE 2 (CHANGES THO) xd

  ///FCM TOKEN: dYLqMDRnRrifWgg9HOXUe2:APA91bEYXhjXCJ5k56OZ_BYWRaJYt56T-0BS48Hf-THgobBSpmbVylRwHvDg3tMkwhRfJZQfpJLo2hlffUr1UX0bkE1s24rkaPrE-xCNd_QSdXL8HE2qZrE

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Received foreground message: ${message.notification?.title}');
    // Mby local notification here ??
  });

  // Handle notification tap when app is in background (but not terminated)
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    final runId = message.data['runId'];
    print('Notification opened with runId: $runId');
    _handleNotificationTap(runId);
  });

  // Handle notification tap when app is terminated
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    final runId = initialMessage.data['runId'];
    print('App opened from terminated state by notification with runId: $runId');
    _handleNotificationTap(runId);
  }

  // Sign out any cached user before running app
  await FirebaseAuth.instance.signOut();

  final GoogleMapsFlutterPlatform mapsImplementation =
      GoogleMapsFlutterPlatform.instance;
  if (mapsImplementation is GoogleMapsFlutterAndroid) {
    mapsImplementation.useAndroidViewSurface = true;
  }


  runApp(
    ChangeNotifierProvider(
      create: (context) => UserProvider(),
      child: const MyApp(),
    ),
  );
}

void _handleNotificationTap(String? runId) {
  if (runId == null) return;

  print("INSIDE HANDLE");

  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    navigatorKey.currentState?.pushNamed('/run', arguments: {'runNumber': runId});
  } else {
    navigatorKey.currentState?.pushNamed('/login');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: WidgetTree(),
      theme: ThemeData(fontFamily: 'Montserrat'),
      routes: {
        '/home': (context) => HomePage(),
        '/login': (context) => LoginPage(),
        '/run': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          print('args raw: $args');

          if (args == null || args is! Map) {
            print('args null or wrong type, redirecting to HomePage');
            return HomePage();
          }

          final run = args['runNumber'];
          print('run from args: $run');

          if (run == null) {
            print('run is null, redirecting to HomePage');
            return HomePage();
          }

          return RunPage(runNumber: run);
        }
      },
    );
  }
}
