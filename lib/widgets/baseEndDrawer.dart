import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:run_to_sip_app/Pages/home.dart';
import 'package:run_to_sip_app/Pages/auth.dart';
import 'package:run_to_sip_app/Provider/UserProvider.dart';

Widget buildBaseEndDrawer(BuildContext context) {
  return Consumer<UserProvider>(
    builder: (context, userProvider, child) => Drawer(
      width: 200,
      child: Column(
        children: [
          // Main list (scrollable)
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Container(
                  height: 125,
                  padding: EdgeInsets.all(16),
                  color: Colors.yellow,
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userProvider.user?.fullName.split(' ').last ?? 'No Name', style: TextStyle(fontSize: 20)),
                      SizedBox(height: 15),
                      Text(userProvider.getRank(userProvider.user!.level)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text("Lvl. ${userProvider.user?.level}"),
                          SizedBox(width: 10),
                          SizedBox(
                            width: 100,
                            child: LinearProgressIndicator(
                              value: userProvider.levelProgress,
                              minHeight: 10,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
    ),
  );
}
