import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:run_to_sip_app/Pages/admin_upload_run.dart';
import 'package:run_to_sip_app/models/run_model.dart';
import 'package:run_to_sip_app/widgets/baseAppBar.dart';
import 'package:run_to_sip_app/widgets/baseEndDrawer.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:async';

import 'auth.dart';

class RunPage extends StatefulWidget {
  final RunModel run;

  const RunPage({super.key, required this.run});

  @override
  State<RunPage> createState() => _RunPageState();
}

class _RunPageState extends State<RunPage> {
  bool _isAdmin = false;
  bool _isLatestRunResult = false;
  String? selectedRunDistance;
  bool isLoading = true;
  RunType? selectedRunType;
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  Timer? _updateTimer;
  bool _hasLocalChanges = false;

  final FirebaseFirestore _fireStore = FirebaseFirestore.instance;
  String? userEmail; // will get from auth

  late DocumentReference userDoc; // user's Firestore doc reference

  //Mobile Scanner Controller
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  @override
  void initState() {
    super.initState();
    userEmail = Auth().currentUser?.email;
    if (userEmail != null) {
      userDoc = _fireStore.collection('users').doc(userEmail);
      _loadUserSelection();
      _checkAdminStatus();
      _checkIfLatestRun();
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
    final result = await isLatestRun(widget.run.runNumber.toString());
    setState(() {
      _isLatestRunResult = result;
    });
  }

  @override
  void dispose() {
    mapController?.dispose();
    _updateTimer?.cancel();
    super.dispose();
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

  Future<void> _loadUserSelection() async {
    try {
      final selectionDoc = await _fireStore
          .collection('user_run_selections')
          .doc('${userEmail}_${widget.run.runNumber}')
          .get();

      if (selectionDoc.exists) {
        final data = selectionDoc.data()!;
        selectedRunDistance = data['selected_run_distance'] as String?;
      }
    } catch (e) {
      print('Error loading user selection: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
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
                Expanded(child: Center(child: PrettyQrView.data(
                  data: widget.run.runNumber.toString(),
                )
                )
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

  void _readQRCodeGen() async {
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
                  'Scan QR Code',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Expanded(
                  child: Center(
                    child: MobileScanner(
                      controller: controller,
                      onDetect: (result) async {
                        if (result.barcodes.isNotEmpty) {
                          final barcode = result.barcodes.first;
                          final runId = barcode
                              .rawValue; // The run number/id encoded in the QR

                          print('Scanned run ID: $runId');
                          if (runId == null) return;

                          // Stop the scanner and close the dialog
                          //controller.stop();
                          //Navigator.pop(context);

                          // Get current user ID/email
                          final userEmail = Auth().currentUser?.email;
                          if (userEmail == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('User not logged in')),
                            );
                            return;
                          }

                          final userRef = _fireStore
                              .collection('users')
                              .doc(userEmail);
                          final runRef = _fireStore
                              .collection('runs')
                              .doc(runId);

                          // Update the runsParticipated field on user doc (increment by 1)
                          await userRef.update({
                            'runs_total': FieldValue.increment(1),
                          });

                          // Also increment total participants for the run
                          await runRef.update({
                            'numPeople': FieldValue.increment(1),
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Run participation recorded!'),
                            ),
                          );
                        }
                      },
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
          .doc(widget.run.runNumber.toString())
          .delete();

      // Delete all user selections for this run
      final selectionsQuery = await _fireStore
          .collection('user_run_selections')
          .where('run_number', isEqualTo: widget.run.runNumber)
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
          position: LatLng(widget.run.lat, widget.run.long),
          infoWindow: InfoWindow(title: "Run Location <3"),
        ),
      );
    });
  }

  // Store the final state we want to save
  String? _finalSelectedDistance;
  String? _finalPreviouslySelected;
  bool _finalIsSelected = false;

  Future<void> _handleSelectionChange(String distance) async {
    if (userEmail == null || isLoading || !_isLatestRunResult) return;

    final previouslySelected = selectedRunDistance;
    final isSameSelected = previouslySelected == distance;

    // Update UI immediately (optimistic update)
    setState(() {
      if (isSameSelected) {
        // Deselecting
        _finalSelectedDistance = null;
        _finalPreviouslySelected = selectedRunDistance;
        _finalIsSelected = false;
        selectedRunDistance = null;
      } else {
        // Selecting new or switching
        _finalPreviouslySelected = selectedRunDistance;
        _finalSelectedDistance = distance;
        _finalIsSelected = true;
        selectedRunDistance = distance;
      }
      _hasLocalChanges = true;
    });

    // Cancel any pending Firebase update
    _updateTimer?.cancel();

    // Schedule new Firebase update after 600ms of inactivity
    _updateTimer = Timer(Duration(milliseconds: 600), () {
      _executeFirebaseUpdate();
    });
  }

  Future<void> _executeFirebaseUpdate() async {
    if (!_hasLocalChanges) return;

    final runDocRef = _fireStore
        .collection('runs')
        .doc('${widget.run.runNumber}');

    try {
      if (_finalIsSelected) {
        // User ended up selecting something
        if (_finalPreviouslySelected != null) {
          // Switch selection
          await _switchSelection(
            _finalPreviouslySelected!,
            _finalSelectedDistance!,
            runDocRef,
          );
        } else {
          // New selection
          await _newSelection(_finalSelectedDistance!, runDocRef);
        }
      } else {
        // User ended up deselecting
        await _removeSelection(_finalPreviouslySelected!, runDocRef);
      }

      _hasLocalChanges = false;
    } catch (e) {
      print('Error updating run counts: $e');
      // On error, revert UI to previous state
      setState(() {
        selectedRunDistance = _finalPreviouslySelected;
        _hasLocalChanges = false;
      });
    }
  }

  Future<void> _newSelection(
    String distance,
    DocumentReference runDocRef,
  ) async {
    final runDistanceField = _getRunDocFieldName(distance);

    // Update user document - just increment counters
    await userDoc.update({
      distance: FieldValue.increment(1),
      'runs_total': FieldValue.increment(1),
    });

    // Update run totals
    await runDocRef.update({
      runDistanceField: FieldValue.increment(1),
      'numPeople': FieldValue.increment(1),
    });
  }

  Future<void> _removeSelection(
    String previousDistance,
    DocumentReference runDocRef,
  ) async {
    final runDistanceField = _getRunDocFieldName(previousDistance);

    // Update user document - just decrement counters
    await userDoc.update({
      previousDistance: FieldValue.increment(-1),
      'runs_total': FieldValue.increment(-1),
    });

    // Update run totals
    await runDocRef.update({
      runDistanceField: FieldValue.increment(-1),
      'numPeople': FieldValue.increment(-1),
    });
  }

  Future<void> _switchSelection(
    String fromDistance,
    String toDistance,
    DocumentReference runDocRef,
  ) async {
    final fromField = _getRunDocFieldName(fromDistance);
    final toField = _getRunDocFieldName(toDistance);

    // Update user document - just switch the counters
    await userDoc.update({
      fromDistance: FieldValue.increment(-1),
      toDistance: FieldValue.increment(1),
    });

    // Update run totals
    await runDocRef.update({
      fromField: FieldValue.increment(-1),
      toField: FieldValue.increment(1),
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: buildBaseAppBar(context, 'Run #${widget.run.runNumber}'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: buildBaseAppBar(context, 'Run #${widget.run.runNumber}'),
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
                imageUrl: widget.run.image,
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
                widget.run.name,
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
                widget.run.description,
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
                    "Date: ${DateFormat('dd/MM/yyyy').format(DateFormat('dd/MM/yyyy').parse(widget.run.date))}",
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
                    "Time: ${widget.run.time}",
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
                      final link = widget.run.link ?? '';
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
                      "Run #${widget.run.runNumber} Strava Link",
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
                    "Meeting Point: ${widget.run.meetPoint}",
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
                    "Sip Location: ${widget.run.sipLocation}",
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
                  target: LatLng(widget.run.lat, widget.run.long),
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
                  onPressed: () => _readQRCodeGen(),
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
                            runNumber: widget.run.runNumber.toString(),
                            initialData: {
                              'runName': widget.run.name,
                              'description': widget.run.description,
                              'date': widget.run.date,
                              'image': widget.run.image,
                              'meetingPoint': widget.run.meetPoint,
                              'sipLocation': widget.run.sipLocation,
                              'link': widget.run.link,
                              'time': widget.run.time,
                              'location': widget.run.name,
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
DateFormat('dd/MM/yyyy').format(DateTime.parse(widget.run.date)),
style: TextStyle(fontSize: 16, color: Colors.grey[800]),
),
],
)

"Date: ${DateFormat('dd/MM/yyyy').format(DateFormat('dd/MM/yyyy').parse(widget.run.date))}",
*/

/*
Padding(
padding: const EdgeInsets.all(16),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text("Run Number: ${widget.run.runNumber}", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
SizedBox(height: 8),
Text("Date: ${widget.run.date}", style: TextStyle(fontSize: 16)),
SizedBox(height: 16),
Text("Description:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
SizedBox(height: 8),
Text(widget.run.description, style: TextStyle(fontSize: 16)),
// You can use setState here later to update UI
],
),
),*/
