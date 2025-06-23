import 'package:run_to_sip_app/Pages/auth.dart';
import 'package:run_to_sip_app/Pages/home.dart';
import 'package:run_to_sip_app/Pages/login_register_page.dart';
import 'package:flutter/material.dart';

class WidgetTree extends StatefulWidget {
  const WidgetTree({super.key});

  @override
  State<WidgetTree> createState() => _WidgetTreeState();
}

class _WidgetTreeState extends State<WidgetTree> {

  @override
  void initState() {
    super.initState();
    final user = Auth().currentUser;  // or FirebaseAuth.instance.currentUser
    print('Current user in initState: $user');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Auth().authStateChange,
      builder: (context, snapshot){

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if(snapshot.hasData) {
          print('User is signed in');
          return HomePage();
        } else {
          print('User is NOT signed in');
          return const LoginPage();
        }
      },
    );
  }
}
