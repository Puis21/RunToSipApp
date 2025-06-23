import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:run_to_sip_app/Pages/run_page.dart';
import 'package:run_to_sip_app/models/run_model.dart';
import 'package:run_to_sip_app/widgets/baseAppBar.dart';
import 'package:run_to_sip_app/widgets/baseEndDrawer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:run_to_sip_app/Pages/auth.dart';
import 'package:run_to_sip_app/Pages/admin_upload_run.dart';

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
    userEmail = Auth().currentUser?.email;
    if (userEmail != null) {
      userDoc = _fireStore.collection('users').doc(userEmail);
      _checkAdminStatus();
    }
  }

  Future<void> _checkAdminStatus() async {
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
  }

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

            return ListView.separated(
              itemCount: runs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 25),
              itemBuilder: (context, index) {
                final run = runs[index];
                return InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                        builder: (context) => RunPage(run: run)
                    ));
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: _runGradient(index),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              run.runNumber.toString(),
                              style: const TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              run.date,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
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
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                run.description,
                                style: const TextStyle(
                                  fontSize: 14,
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
                );
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