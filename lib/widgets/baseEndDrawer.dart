import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:run_to_sip_app/Pages/contact_form.dart';
import 'package:run_to_sip_app/Pages/home.dart';
import 'package:run_to_sip_app/Pages/auth.dart';
import 'package:run_to_sip_app/Provider/UserProvider.dart';
import 'package:run_to_sip_app/Pages/profile_page.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
                  leading: Icon(Icons.person_2),
                  title: Text('Profile'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProfilePage()));
                  },
                ),
              ],
            ),
          ),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.hasData
                  ? 'v${snapshot.data!.version}+${snapshot.data!.buildNumber}'
                  : '';
              return Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.email),
                    title: Text('Report a Bug'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ContactForm(),
                        ),
                      );
                    },
                  ),
                  const Divider(color: Colors.black54),
                  ListTile(
                    leading: Icon(Icons.logout),
                    title: Text('Logout'),
                    onTap: () {
                      Auth().signOut();
                    },
                  ),
                  SizedBox(height: 8),
                  if (snapshot.hasData)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        version,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
}
