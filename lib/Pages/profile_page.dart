import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:run_to_sip_app/Provider/UserProvider.dart';
import 'package:provider/provider.dart';
import 'package:run_to_sip_app/widgets/baseEndDrawer.dart';
import 'package:run_to_sip_app/widgets/baseAppBar.dart';

import 'auth.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late UserProvider _userProvider;
  bool _didLoadDependencies = false;
  bool isLoading = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_didLoadDependencies) {
      _userProvider = context.read<UserProvider>();
      loadUserData();
      _didLoadDependencies = true;
    }
  }

  ///UNUSED FOR GETTING THE VALUE THAT CORRESPONDS THAT A PERCENTILE
  /*void getPercentile(List<dynamic> totalRuns, var numTotal, final percentile)
  {
    var index = percentile/100 * (numTotal - 1);
    print('index: $index');

    var floorIndex = index.floor();
    var ceilIndex = index.ceil();
    var fraction = index - floorIndex;
    fraction = double.parse(fraction.toStringAsFixed(1));

    var percentileVal = totalRuns[floorIndex] + (totalRuns[ceilIndex] - totalRuns[floorIndex]) * fraction ;

    print('floorIndex: $floorIndex');
    print('ceilIndex: $ceilIndex');
    print('fraction: $fraction');
    print('percentile_val: $percentileVal');
  }*/

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  Future<void> loadUserData() async {
    print('loadUserData started');
    try {
      setState(() => isLoading = true);

      final email = Auth().currentUser?.email;
      if (email != null) {
        await _userProvider.loadUserByEmail(email);
      }
      print('User loaded successfully');
    } catch (e, stack) {
      print('Error loading user data: $e');
      print(stack);
    } finally {
      setState(() => isLoading = false);
      print('Loading done, isLoading set to false');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildBaseAppBar(context, "Profile Page"),
      endDrawer: buildBaseEndDrawer(context),
      body: buildBody(),
    );
  }

  Widget buildBody() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Center(
            child: Container(
              height: 200,
              width: 200,
              padding: EdgeInsets.all(16),
              alignment: Alignment.centerLeft,
              child: Image.asset(
                'assets/images/profile_default.png',
                fit: BoxFit.fill,
              ),
            ),
          ),
          SizedBox(height: 5),
          Text(
            _userProvider.user!.fullName,
            style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
          ),
          Text(
            _userProvider.getRank(_userProvider.user!.level),
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Level ${_userProvider.user!.level}',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 15),
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  value: _userProvider.levelProgress,
                  minHeight: 24,
                  borderRadius: BorderRadius.circular(15),
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                ),
              ),
            ],
          ),
          SizedBox(height: 25),

          Card(
            margin: EdgeInsets.symmetric(vertical: 10),
            child: ListTile(
              leading: Icon(Icons.run_circle, size: 30),
              title: Text("Runs Completed"),
              trailing: Text(
                "${_userProvider.runsTotal}",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          ///I AM CALLING A FUNC TO GET THIS MBY ADD IT AS USER VARIABLE SO IT LOADS WITH THE PROVIDER?
          Card(
            margin: EdgeInsets.symmetric(vertical: 10),
            child: ListTile(
              leading: Icon(Icons.star, size: 30),
              title: Text("Runs Percentile"),
              trailing: FutureBuilder<double>(
                future: _userProvider.getUserPercentile(),  // async call here
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();  // or something else for loading :)
                  } else if (snapshot.hasError) {
                    return Text("Error");
                  } else {
                    return Text(
                      "${snapshot.data?.toStringAsFixed(0) ?? '0'}%",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    );
                  }
                },
              ),
            ),
          ),

          Card(
            margin: EdgeInsets.symmetric(vertical: 10),
            child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.accessible_forward_sharp, size: 30),
                title: Text("Current Streak"),
                trailing: Text(
                  "10 Runs",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: const Divider(color: Colors.black54, thickness: 2, indent: 20, endIndent: 20),
              ),
              ListTile(
                leading: Icon(Icons.local_fire_department_rounded, size: 30),
                title: Text("Max Streak"),
                trailing: Text(
                  "20 Runs",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            ),
          ),

          Card(
            margin: EdgeInsets.symmetric(vertical: 10),
            child: ListTile(
              leading: Icon(Icons.emoji_events, size: 30),
              title: Text("Personal Best"),
              trailing: Text(
                "5k",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
