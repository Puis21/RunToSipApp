import 'package:flutter/material.dart';
import 'package:run_to_sip_app/Pages/home.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:run_to_sip_app/Pages/widget_tree.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Sign out any cached user before running app
  await FirebaseAuth.instance.signOut();

  final GoogleMapsFlutterPlatform mapsImplementation = GoogleMapsFlutterPlatform.instance;
  if(mapsImplementation is GoogleMapsFlutterAndroid){
    mapsImplementation.useAndroidViewSurface = true;
  }

  runApp(const MyApp());
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
      home: WidgetTree(),
      theme: ThemeData(
        fontFamily: 'Montserrat'
      ),
    );
  }
}
