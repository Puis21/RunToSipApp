import 'package:flutter/material.dart';
import 'package:run_to_sip_app/Pages/home.dart';
import 'package:run_to_sip_app/Pages/auth.dart';

Widget buildBaseEndDrawer(BuildContext context) {
  return Drawer(
    width: 200,
    child: Column(
      children: [
        // Main list (scrollable)
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                height: 100,
                padding: EdgeInsets.all(16),
                color: Colors.yellow,
                alignment: Alignment.centerLeft,
                child: Text('Navigation Menu', style: TextStyle(fontSize: 20)),
              ),
              ListTile(
                leading: Icon(Icons.home),
                title: Text('Home'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.settings),
                title: Text('Profile'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),

        const Divider(color: Colors.black54),
        // Logout button at bottom
        ListTile(
          leading: Icon(Icons.logout),
          title: Text('Logout'),
          onTap: () {
            // Handle logout logic
              Auth().signOut();
          },
        ),
        SizedBox(height: 16),
      ],
    ),
  );
}
