import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:provider/provider.dart';
import 'package:run_to_sip_app/Pages/admin_upload_run.dart';
import 'package:run_to_sip_app/models/run_model.dart';
import 'package:run_to_sip_app/models/user_model.dart';
import 'package:run_to_sip_app/widgets/baseAppBar.dart';
import 'package:run_to_sip_app/widgets/baseEndDrawer.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:lottie/lottie.dart' as lottie;
import 'package:run_to_sip_app/Provider/UserProvider.dart';
import 'package:provider/provider.dart';

import 'dart:async';
import 'auth.dart';

enum QRScanStage { scanning, buttons, animation }

class RunPage extends StatefulWidget {
  final String runNumber;

  const RunPage({super.key, required this.runNumber});

  @override
  State<RunPage> createState() => _RunPageState();
}

class _RunPageState extends State<RunPage> {
  //Init for fetching data for RunModel
  RunModel? run;
  bool isLoadingRun = true;

  bool _isAdmin = false;
  bool _isLatestRunResult = false;
  String? selectedRunDistance;
  bool isLoading = true;
  RunType? selectedRunType;
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  Timer? _updateTimer;

  //Logic for debouncing and processing user selections
  final _operationQueue = Queue<Future Function()>();
  bool _isProcessingQueue = false;
  final int _maxQueueSize = 5;
  late final Future<SharedPreferences> _prefsFuture;
  SharedPreferences? _prefs;

  bool canCloseQR = true;

  //Scan switch statement
  QRScanStage _currentStage = QRScanStage.scanning;

  final FirebaseFirestore _fireStore = FirebaseFirestore.instance;

  ///USED IN PREV VERSION AND CHANGED WITH APPUSERMODEL
  late DocumentReference userDoc; // user's Firestore doc reference

  late UserProvider _userProvider;

  //Mobile Scanner Controller
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  @override
  void initState() {
    super.initState();
    _loadRun();
    _userProvider = context.read<UserProvider>();
    loadUserData();
    _checkIfLatestRun();
    _prefsFuture = SharedPreferences.getInstance();
    _initializePreferences();
  }

  Future<void> _loadRun() async {
    // Example: fetch run by number from Firestore
    final doc = await FirebaseFirestore.instance
        .collection('runs')
        .doc(widget.runNumber
        .toString()) // make sure runNumber is a String here if needed
        .get();

    if (doc.exists) {
      final data = doc.data(); // nullable safety
      if (data != null) {
        setState(() {
          run = RunModel.fromFirestore(data);
          isLoading = false;
        });
      } else {
        // Handle empty data case
      }
    } else {
      // Handle document not found
    }
  }

  Future<void> _initializePreferences() async {
    _prefs = await _prefsFuture;
    _loadSelection(); // Now we can load the selection
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

  Future<void> _loadSelection() async {
    if (_prefs == null) return;

    final savedDistance = _prefs!.getString('selectedRun_${run!.runNumber}');
    if (savedDistance != null && mounted) {
      setState(() {
        selectedRunDistance = savedDistance;
      });
    }

    _verifyWithFirebase(savedDistance ?? '');

  }

  Future<void> _verifyWithFirebase(String distance) async {
    final doc = await _fireStore.collection('runs')
        .doc('${run!.runNumber}')
        .get();

    if (!doc.exists || !(doc.data()?[_getRunDocFieldName(distance)] ?? false)) {
      await _saveSelection(null);
      if (mounted) {
        setState(() => selectedRunDistance = null);
      }
    }
  }

  Future<void> _saveSelection(String? distance) async {
    if (_prefs == null) return;

    if (distance != null) {
      await _prefs!.setString('selectedRun_${run!.runNumber}', distance);
    } else {
      await _prefs!.remove('selectedRun_${run!.runNumber}');
    }
  }

  Future<bool> isLatestRun(String runId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('runs')
        .orderBy('runNumber', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return false;

    final latestRunDoc = snapshot.docs.first;

    return latestRunDoc.id == runId;
  }

  void _checkIfLatestRun() async {
    final result = await isLatestRun(run!.runNumber.toString());
    setState(() {
      _isLatestRunResult = result;
    });
  }

  @override
  void dispose() {
    mapController?.dispose();
    _updateTimer?.cancel();
    _operationQueue.clear();
    super.dispose();
  }

  // Helper method to get colors for distances
  Color _getColorForDistance(String distance) {
    switch (distance) {
      case '3km':
        return Colors.green;
      case '5km':
        return Colors.orange;
      case '7km':
        return Colors.brown;
      default:
        return Colors.blue;
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Run'),
          content: Text(
            'Are you sure you want to delete this run? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteRun();
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showQRCodeGen() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Color(0xFFffff00),
          insetPadding: EdgeInsets.all(20),
          child: Container(
            padding: EdgeInsets.all(16),
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              children: [
                Text(
                  'QR Code for Run',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Expanded(
                  child: Center(
                    child: PrettyQrView.data(
                      data: run!.runNumber.toString(),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6F4E37),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _readQRCodeGen(BuildContext context) async {
    _currentStage = QRScanStage.scanning;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder:
              (
                BuildContext context,
                void Function(void Function()) setStateDialog,
              ) {
                return Dialog(
                  backgroundColor: Color(0xFFffff00),
                  insetPadding: EdgeInsets.all(20),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    height: MediaQuery.of(context).size.height * 0.8,
                    child: Column(
                      children: [
                        Text(
                          'Scan QR Code',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        //SizedBox(height: 20),
                        Expanded(
                          child: Center(
                            child: _switchScanWidget(setStateDialog),
                          ),
                        ),
                        SizedBox(height: 20),
                        Visibility(
                          visible: canCloseQR,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF6F4E37),
                              foregroundColor: Colors.white,
                            ),
                            child: Text('Close'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
        );
      },
    );
  }

  Widget _switchScanWidget(void Function(void Function()) setStateDialog) {
    switch (_currentStage) {
      case QRScanStage.scanning:
        return MobileScanner(
          controller: controller,
          onDetect: (result) async {
            if (result.barcodes.isNotEmpty) {
              final barcode = result.barcodes.first;
              final runId = barcode.rawValue;

              print('Scanned run ID: $runId');
              if (runId == null) return;

              await controller.stop(); // Await stop before UI changes

              final userEmail = Auth().currentUser?.email;
              if (userEmail == null) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('User not logged in')));
                return;
              }

              // Update the dialog state
              setStateDialog(() {
                canCloseQR = false;
                _currentStage = QRScanStage.buttons;
              });
            }
          },
        );
      case QRScanStage.buttons:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              "Choose a run group!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            _buildRunOption(
              '3km',
              setStateDialog,
              _userProvider.user!.email,
              run!.runNumber.toString(),
            ),
            _buildRunOption(
              '5km',
              setStateDialog,
              _userProvider.user!.email,
              run!.runNumber.toString(),
            ),
            _buildRunOption(
              '7km',
              setStateDialog,
              _userProvider.user!.email,
              run!.runNumber.toString(),
            ),
            _buildRunOption(
              'Skip',
              setStateDialog,
              _userProvider.user!.email,
              run!.runNumber.toString(),
            ),
          ],
        );
      case QRScanStage.animation:
        canCloseQR = true;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Registered!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF22cc88),
              ),
            ),
            lottie.Lottie.asset(
              'assets/animations/checkmark.json',
              repeat: false,
            ),
          ],
        );

      default:
        return Text('Loading...');
    }
  }

  Widget _buildRunOption(
    String label,
    StateSetter setStateDialogue,
    String userEmail,
    String runId,
  ) {
    //Optional parameters? mby delete
    final isSelected = selectedRunDistance == label;
    final color = _getColorForDistance(label);

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: _getColorForDistance(label),
        foregroundColor: Colors.white,
        fixedSize: Size(double.infinity, 100),
      ),
      onPressed: () async {
        print("Selected: $label");

        ///NOT USED ANYMORE
        //final userRef = _fireStore.collection('users').doc(userEmail);

        final runRef = _fireStore.collection('runs').doc(runId);
        final userProvider = context.read<UserProvider>();

        // Determine field names for selected distance
        String userField = '';
        String runField = '';
        switch (label) {
          case '3km':
            userProvider.incrementRun('3km');
            runField = 'numPeople3km';
            break;
          case '5km':
            userProvider.incrementRun('5km');
            runField = 'numPeople5km';
            break;
          case '7km':
            userProvider.incrementRun('7km');
            runField = 'numPeople7km';
            break;
          case 'Skip':
            userProvider.incrementRun('noDistance');
            runField = '';
            break;
          default:
            break;
        }

        userProvider.increaseXp(1, context: context);

        /*   // Firestore updates
        await userRef.update({
          'runs_total': FieldValue.increment(1),
          if (userField != '') userField: FieldValue.increment(1),
        });*/

        await runRef.update({
          'numPeople': FieldValue.increment(1),
          if (runField != '') runField: FieldValue.increment(1),
        });

        // Save choice or proceed to next stage
        setStateDialogue(() {
          _currentStage = QRScanStage.animation;
        });
      },
      child: Text(
        "$label",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26),
      ),
    );
  }

  Future<void> _deleteRun() async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      // Delete the run document
      await _fireStore
          .collection('runs')
          .doc(run!.runNumber.toString())
          .delete();

      // Delete all user selections for this run
      final selectionsQuery = await _fireStore
          .collection('user_run_selections')
          .where('run_number', isEqualTo: run!.runNumber)
          .get();

      for (var doc in selectionsQuery.docs) {
        await doc.reference.delete();
      }

      // Hide loading
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Run deleted successfully!')));

      // Go back to previous screen
      Navigator.of(context).pop();
    } catch (e) {
      // Hide loading
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting run: $e')));
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    setState(() {
      markers.add(
        Marker(
          markerId: MarkerId("runLocation"),
          position: LatLng(run!.lat, run!.long),
          infoWindow: InfoWindow(title: "Run Location <3"),
        ),
      );
    });
  }

  Future<void> _handleSelectionChange(String distance) async {
    if (_userProvider.user?.email == null || isLoading || !_isLatestRunResult) return;

    final isCurrentlySelected = selectedRunDistance == distance;
    final newState = !isCurrentlySelected;

    // Save to local storage immediately
    await _saveSelection(newState ? distance : null);

    // Immediate UI update
    setState(() {
      selectedRunDistance = newState ? distance : null;
    });

    if (_operationQueue.length >= _maxQueueSize) {
      _operationQueue.removeFirst(); // Drop oldest operation
    }

    // Add to operation queue
    _operationQueue.add(() => _createFirebaseOperation(distance, newState));

    if (!_isProcessingQueue) {
      _processQueue();
    }
  }

  Future<void> _processQueue() async {
    _isProcessingQueue = true;

    while (_operationQueue.isNotEmpty) {
      final operation = _operationQueue.removeFirst();
      await operation();
      await Future.delayed(
        Duration(milliseconds: 200),
      ); // Small delay between ops
    }

    _isProcessingQueue = false;
  }

  Future<void> _createFirebaseOperation(String distance, bool isSelect) async {
    final docRef = _fireStore.collection('runs').doc('${run!.runNumber}');
    final field = _getRunDocFieldName(distance);

    try {
      if (isSelect) {
        await docRef.update({
          field: FieldValue.increment(1),
          'numPeople': FieldValue.increment(1),
        });
        if (_userProvider.user != null) {
          await _userProvider.incrementRun(distance);
        }
      } else {
        await docRef.update({
          field: FieldValue.increment(-1),
          'numPeople': FieldValue.increment(-1),
        });
        if (_userProvider.user != null) {
          await _userProvider.decrementRun(distance);
        }
      }
    } catch (e) {
      // Revert UI on error
      setState(() {
        selectedRunDistance = isSelect ? null : distance;
      });
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    _isAdmin = context.watch<UserProvider>().isAdmin;

    if (isLoading) {
      return Scaffold(
        appBar: buildBaseAppBar(context, 'Run #${run!.runNumber}'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: buildBaseAppBar(context, 'Run #${run!.runNumber}'),
      endDrawer: buildBaseEndDrawer(context),
      body: buildBody(),
    );
  }

  Widget buildBody() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 40),
      // Wrap in scroll view if content may overflow
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ///OPTIONAL??? ASK NEMIR AND ALE
          /*        Container(
            margin: EdgeInsets.all(16), //Add some margin
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: */
          ClipRRect(
            //borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 250,
              width: double.infinity,
              child: CachedNetworkImage(
                imageUrl: run!.image,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) =>
                    Center(child: Text("Image not available")),
              ),
            ),
          ),
          //),
          Padding(
            padding: EdgeInsets.all(12),
            child: Align(
              alignment: Alignment.center,
              child: Text(
                run!.name,
                style: TextStyle(fontSize: 30, fontFamily: 'RacingSansOne'),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: EdgeInsets.all(15),
              child: Text(
                run!.description,
                style: TextStyle(fontSize: 16, fontFamily: 'Montserrat'),
                textAlign: TextAlign.justify,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 18, color: Colors.grey[700]),
                  SizedBox(width: 8),
                  Text(
                    "Date: ${DateFormat('dd/MM/yyyy').format(DateFormat('dd/MM/yyyy').parse(run!.date))}",
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Montserrat',
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 12, top: 5, bottom: 5),
            child: SizedBox(
              child: Row(
                children: [
                  Icon(Icons.timer, size: 18, color: Colors.grey[700]),
                  SizedBox(width: 8),
                  Text(
                    "Time: ${run!.time}",
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Montserrat',
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 12, top: 5, bottom: 5),
            child: SizedBox(
              child: Row(
                children: [
                  Icon(Icons.link, size: 18, color: Colors.grey[700]),
                  SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      final link = run!.link ?? '';
                      if (link.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('No link available')),
                        );
                        return;
                      }

                      final url = Uri.parse(link);

                      if (await canLaunchUrl(url)) {
                        final launched = await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                        print('Launch result: $launched');
                        if (!launched) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Could not launch the link'),
                            ),
                          );
                        }
                      } else {
                        print('Cannot launch the URL');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Could not launch the link')),
                        );
                      }
                    },
                    child: Text(
                      "Run #${run!.runNumber} Strava Link",
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Montserrat',
                        color: Colors.blue, // To make it look like a link
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 12, top: 5, bottom: 5),
            child: SizedBox(
              child: Row(
                children: [
                  Icon(Icons.map_rounded, size: 18, color: Colors.grey[700]),
                  SizedBox(width: 8),
                  Text(
                    "Meeting Point: ${run!.meetPoint}",
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Montserrat',
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 12, top: 5, bottom: 5),
            child: SizedBox(
              child: Row(
                children: [
                  Icon(Icons.coffee, size: 18, color: Colors.grey[700]),
                  SizedBox(width: 8),
                  Text(
                    "Sip Location: ${run!.sipLocation}",
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Montserrat',
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12),
            child: Container(
              color: Colors.blueGrey,
              padding: EdgeInsets.only(left: 12, right: 12),
              height: 250,
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                markers: markers,
                initialCameraPosition: CameraPosition(
                  target: LatLng(run!.lat, run!.long),
                  zoom: 12,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12),
            child: Align(
              alignment: Alignment.center,
              child: Text(
                "Choose Your Challenge!",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['3km', '5km', '7km'].map((distance) {
                final isSelected = selectedRunDistance == distance;
                final color = _getColorForDistance(distance); // helper

                return OutlinedButton(
                  onPressed: !_isLatestRunResult
                      ? null
                      : () => _handleSelectionChange(distance),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isSelected ? color : Colors.transparent,
                    side: BorderSide(color: color),
                    foregroundColor: isSelected ? Colors.white : color,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    distance,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12),
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () => _readQRCodeGen(context),
                icon: Icon(Icons.add),
                label: Text('Read QR Code'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF5316),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                /// Edit Button
                Visibility(
                  visible: _isAdmin,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateRunPage(
                            runNumber: run!.runNumber.toString(),
                            initialData: {
                              'runName': run!.name,
                              'description': run!.description,
                              'date': run!.date,
                              'image': run!.image,
                              'meetingPoint': run!.meetPoint,
                              'sipLocation': run!.sipLocation,
                              'link': run!.link,
                              'time': run!.time,
                              'location': run!.name,
                            },
                          ),
                        ),
                      );
                    },
                    icon: Icon(Icons.edit),
                    label: Text('Edit Run'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),

                ///Delete Button
                Visibility(
                  visible: _isAdmin,
                  child: ElevatedButton.icon(
                    onPressed: () => _showDeleteConfirmation(),
                    icon: Icon(Icons.delete),
                    label: Text('Delete Run'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12),
            child: Visibility(
              visible: _isAdmin,
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: () => _showQRCodeGen(),
                  icon: Icon(Icons.add),
                  label: Text('Generate QR Code'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  //Helper for updating runs
  String _getRunDocFieldName(String distance) {
    switch (distance) {
      case '3km':
        return 'numPeople3km';
      case '5km':
        return 'numPeople5km';
      case '7km':
        return 'numPeople7km';
      default:
        throw ArgumentError('Invalid distance: $distance');
    }
  }
}

/*
Row(
children: [
Icon(Icons.calendar_today, size: 18, color: Colors.grey[700]),
SizedBox(width: 8),
Text(
DateFormat('dd/MM/yyyy').format(DateTime.parse(run!.date)),
style: TextStyle(fontSize: 16, color: Colors.grey[800]),
),
],
)

"Date: ${DateFormat('dd/MM/yyyy').format(DateFormat('dd/MM/yyyy').parse(run!.date))}",
*/

/*
Padding(
padding: const EdgeInsets.all(16),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text("Run Number: ${run!.runNumber}", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
SizedBox(height: 8),
Text("Date: ${run!.date}", style: TextStyle(fontSize: 16)),
SizedBox(height: 16),
Text("Description:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
SizedBox(height: 8),
Text(run!.description, style: TextStyle(fontSize: 16)),
// You can use setState here later to update UI
],
),
),*/
