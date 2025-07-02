import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:run_to_sip_app/Pages/run_page.dart';
import 'package:run_to_sip_app/models/run_model.dart';
import 'package:run_to_sip_app/widgets/baseAppBar.dart';
import 'package:run_to_sip_app/widgets/baseEndDrawer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:run_to_sip_app/Pages/auth.dart';
import 'package:run_to_sip_app/Pages/admin_upload_run.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:run_to_sip_app/Provider/UserProvider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'dart:ui';


class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _MyHomePageState();
}


class _MyHomePageState extends State<HomePage> {
  bool _isAdmin = false;
  final User? user = Auth().currentUser;

  final FirebaseFirestore _fireStore = FirebaseFirestore.instance;
  String? userEmail; // will get from auth

  late DocumentReference userDoc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final email = FirebaseAuth.instance.currentUser?.email;
      if (email != null) {
        context.read<UserProvider>().loadUserByEmail(email);
      }
    });

    subscribeToAllUsersTopic();
  }

  Future<void> subscribeToAllUsersTopic() async {
    await FirebaseMessaging.instance.subscribeToTopic('all_users');
    print('Subscribed to all_users topic');
  }

  ///MOVED TO PROVIDER
/*  Future<void> _checkAdminStatus() async {
    final user = Auth().currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .get();
      setState(() {
        _isAdmin = doc.data()?['is_admin'] ?? false;
      });
    }
  }*/

  LinearGradient _runGradient(int index) {
    if(index == 0)
      {
        return LinearGradient(
            colors: [
              Colors.yellow,
              Colors.blue,
              Colors.red],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      }
    else
      {
        return LinearGradient(
            colors: [
              Colors.black,
              Colors.grey,
              Colors.black26],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      }

  }



  @override
  Widget build(BuildContext context) {
    _isAdmin = context.watch<UserProvider>().isAdmin;

    return Scaffold(
      appBar: buildBaseAppBar(context, "List of Runs"),
      endDrawer: buildBaseEndDrawer(context),
      body: buildBody(),
      floatingActionButton: Visibility(
        visible: _isAdmin,
        child: FloatingActionButton(
          onPressed: () {
            // Navigate to create run page
            Navigator.push(context, MaterialPageRoute(
                builder: (context) => CreateRunPage()
            ));
          },
          child: Icon(Icons.add),
          backgroundColor: Colors.yellow,
        ),
      ),
    );
  }

  Widget buildBody() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Container(
        height: 835,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: StreamBuilder<QuerySnapshot>(
          stream:  FirebaseFirestore.instance
              .collection('runs')
              .orderBy('runNumber', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final runs = snapshot.data!.docs
                .map((doc) => RunModel.fromFirestore(doc.data() as Map<String, dynamic>))
                .toList();

            ///Listing only last 20 runs for optimisation
            final last20Runs = runs.take(20).toList();

            return ListView.separated(
              itemCount: last20Runs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 25),
              itemBuilder: (context, index) {
                final run = last20Runs[index];
                final runTile = InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                        builder: (context) => RunPage(runNumber: run.runNumber.toString())
                    ));
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 150, // or any fixed height if needed
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      ///REMOVED GRADIENT
                      //gradient: _runGradient(index),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          // Step 1: Background Image
                          Positioned.fill(
                            child: CachedNetworkImage(
                              imageUrl: run.image,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) => Center(child: Text("Image not available")),
                            ),
                          ),

                          // Blur layer over the image
                          Positioned.fill(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                              child: Container(
                                color: Colors.black.withOpacity(0.4), // slight dark overlay for contrast
                              ),
                            ),
                          ),

                          // Text content
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 15),
                                    Text(
                                      '#${run.runNumber.toString()}',
                                      style: const TextStyle(
                                        fontSize: 25,
                                        fontFamily: 'Montserrat',
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    Text(
                                      run.date,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'Montserrat',
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        run.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontFamily: 'RacingSansOne',
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        run.description,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'Montserrat',
                                          color: Colors.white70,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );

                ///Optional?: Make Runs other than first run grey
                if (index == 0) {
                  return runTile;
                } else {
                  return ColorFiltered(
                    colorFilter: const ColorFilter.matrix(<double>[
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0, 0, 0, 1, 0,
                    ]),
                    child: runTile,
                  );
                }

              },
            );
          },
        ),
      ),
    );
  }

}


// title: Text("List of Runs", style: TextStyle(
// fontWeight: FontWeight.bold
// )),
// centerTitle: true,
// backgroundColor: Colors.yellow,
// elevation: 5.0,
// shadowColor: Colors.black,
// leading: SizedBox(
// width: 60, // increase as needed
// child: Padding(
// padding: EdgeInsets.only(left: 8),
// child: Image.asset(
// 'assets/RTSLog.png',
// fit: BoxFit.contain,
// ),
// ),
// ),