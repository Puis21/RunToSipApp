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
import 'package:run_to_sip_app/widgets/RunTile.dart';

import 'dart:ui';


///OPTIONAL CODE??? FOR CHECKING USER AUTH ID TOKEN (COULD USE IN THE FUTURE)
/*final Auth auth = Auth();
fetchProtectedData();
void fetchProtectedData() async {
  final response = await auth.callBackendWithAuth('http://10.0.2.2:5000/protected-route');

  if (response == null) {
    print('User not logged in');
    return;
  }

  if (response.statusCode == 200) {
    print('Backend response: ${response.body}');
    // You can setState here to update your UI with the data
  } else {
    print('Backend error: ${response.statusCode} ${response.reasonPhrase}');
  }
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    // your UI here
  );
}*/


class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _MyHomePageState();
}


class _MyHomePageState extends State<HomePage> {
  List<RunModel>? _cachedRuns;
  bool _isAdmin = false;
  final User? user = Auth().currentUser; /// Not needed mby delete?/?

  final FirebaseFirestore _fireStore = FirebaseFirestore.instance;
  String? userEmail; // will get from auth /// Not needed mby delete?/?

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


  /// TO DO: Check if this is needed now
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


  ///OLD FUNC TO ADD GRADIENT BACKGROUND TO RUNS
/*  LinearGradient _runGradient(int index) {
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

  }*/

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
          backgroundColor: Colors.yellow,
          child: Icon(Icons.add),
        ),
      ),
    );
  }

  Widget buildBody() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('runs')
              .orderBy('runNumber', descending: true)
              .limit(10)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final runs = snapshot.data!.docs
                .map((doc) => RunModel.fromFirestore(doc.data() as Map<String, dynamic>))
                .toList();

            return ListView.separated(
              addAutomaticKeepAlives: false,
              itemCount: runs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 25),
              itemBuilder: (context, index) {
                final run = runs[index];

                // Create the RunTile widget
                final runTile = RunTile(
                  run: run,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RunPage(runNumber: run.runNumber.toString()),
                      ),
                    );
                  },
                );

                // Apply conditional rendering logic
                if (run.checkIfExpired()) {
                  return ColorFiltered(
                    colorFilter: const ColorFilter.matrix(<double>[
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0, 0, 0, 1, 0,
                    ]),
                    child: runTile,
                  );
                } else {
                  return  runTile;
                }

              },
            );
          },
        ),
      ),
    );
  }
}



/*                final date = DateTime.now();
                final day = run.date.split('/')[0];
                final month = run.date.split('/')[1];
                final year = run.date.split('/')[2];

                bool isLessThanRunDay = ((date.day <= int.parse(day) && date.month <= int.parse(month)) || date.year < int.parse(year));
                bool isSameAsRunDay = (date.day == int.parse(day) && date.month == int.parse(month) && date.year == int.parse(year));

                final hour = run.time.split(':')[0];*/

//print(date.hour);

/*if(isSameAsRunDay && date.hour >= (int.parse(hour)))
                {
                  return ColorFiltered(
                    colorFilter: const ColorFilter.matrix(<double>[
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0, 0, 0, 1, 0,
                    ]),
                    child: runTile,
                  );
                }else if (isLessThanRunDay)
                {
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
                }*/

//print(run.time);

///Optional?: Make Runs other than first run grey
/*if (index == 0) {
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
                }*/


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