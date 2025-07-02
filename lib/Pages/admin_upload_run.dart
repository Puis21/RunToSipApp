import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class CreateRunPage extends StatefulWidget {
  final String? runNumber; // null for create, populated for edit
  final Map<String, dynamic>?
  initialData; // null for create, populated for edit

  CreateRunPage({this.runNumber, this.initialData});

  @override
  _CreateRunPageState createState() => _CreateRunPageState();
}

class _CreateRunPageState extends State<CreateRunPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _runNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _driveLinkController = TextEditingController();
  final TextEditingController _runNumberController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _stravalinkController = TextEditingController();
  final TextEditingController _meetPointController = TextEditingController();
  final TextEditingController _sipLocationController = TextEditingController();

  final String token = '1234567890';
  String? _selectedLocation;
  Map<String, double>? _selectedLatLng;

  Timer? _debounce;

  var uuid = const Uuid();
  List<dynamic> listOfLocations = [];

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  bool get isEditMode => widget.runNumber != null;

  @override
  void initState() {
    super.initState();

    widget.initialData?.forEach((key, value) {
      print('$key: $value');
    });

    _searchController.addListener(() {
      _onChange();
    });

    if (isEditMode && widget.initialData != null) {
      // Pre-populate form with existing data for edit mode
      _runNumberController.text = widget.runNumber!;
      _runNameController.text = widget.initialData!['runName'] ?? '';
      _descriptionController.text = widget.initialData!['description'] ?? '';
      _searchController.text = '';
      _stravalinkController.text = widget.initialData!['link'] ?? '';
      _driveLinkController.text = widget.initialData!['image'] ?? '';
      _meetPointController.text = widget.initialData!['meetPoint'] ?? '';
      _sipLocationController.text = widget.initialData!['sipLocation'] ?? '';

      // Handle date - could be String, DateTime, or Timestamp
      final dateData = widget.initialData!['date'];
      if (dateData is String) {
        try {
          _selectedDate = DateFormat('dd/MM/yyyy').parse(dateData);
        } catch (e) {
          print('Error parsing date string: $e');
        }
      } else if (dateData is DateTime) {
        _selectedDate = dateData;
      } else if (dateData is Timestamp) {
        _selectedDate = dateData.toDate();
      }

      final timeData = widget.initialData!['time'];
      if (timeData is String) {
        try {
          _selectedTime = TimeOfDay.fromDateTime(
            DateFormat('HH:mm').parse(timeData),
          );
        } catch (e) {
          print('Error parsing time string: $e');
        }
      } else if (timeData is TimeOfDay) {
        _selectedTime = timeData;
      } else if (timeData is Timestamp) {
        _selectedTime = TimeOfDay.fromDateTime(timeData.toDate());
      }

    }
  }

  _onChange() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      placeSuggestion(_searchController.text);
    });
  }

  void _onPlaceSelected(Map<String, dynamic> prediction) async {
    final placeId = prediction['place_id'];
    final coords = await getPlaceLatLng(placeId);

    setState(() {
      _selectedLatLng = coords;
      _searchController.text = prediction['description'];
    });
  }

  Future<Map<String, double>?> getPlaceLatLng(String placeId) async {

    ///HTTP for TESTING Flask
    //http://10.0.2.2:5000

    final url = Uri.parse('https://rts-backend-md5r.onrender.com/place-details?place_id=$placeId');
    final response = await http.get(url);
    final data = json.decode(response.body);

    if (data['status'] == 'OK') {
      final lat = data['result']['geometry']['location']['lat'];
      final lng = data['result']['geometry']['location']['lng'];
      return {'lat': lat, 'lng': lng};
    } else {
      throw Exception('Failed to fetch coordinates: ${data['error_message']}');
    }
  }

  void placeSuggestion(String input) async {
    if (input.isEmpty) {
      setState(() => listOfLocations = []);
      return;
    }

    try {
      String encodedInput = Uri.encodeComponent(input);
      final url = Uri.parse(
        'https://rts-backend-md5r.onrender.com/place-autocomplete?input=$encodedInput&sessiontoken=$token',
      );

      if (kDebugMode) {
        print("Sending request to: $url");
      }

      final response = await http.get(url);
      final data = json.decode(response.body);

      if (kDebugMode) {
        print("API Response: $data");
      }

      if (response.statusCode == 200 && data['status'] == 'OK') {
        setState(() {
          listOfLocations = (data['predictions'] as List).take(3).toList();
        });
      } else {
        throw Exception('Failed to load predictions: ${data['error_message']}');
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error in placeSuggestion: $e");
      }
      setState(() => listOfLocations = []);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  String? convertDriveLinkToDirect(String link) {
    if (link.contains("uc?export=view&id=")) return link; // already direct

    final patterns = [
      RegExp(r'drive\.google\.com\/file\/d\/([^\/]+)'),
      RegExp(r'drive\.google\.com\/open\?id=([^&]+)'),
      RegExp(r'drive\.google\.com\/uc\?id=([^&]+)'),
      RegExp(r'drive\.google\.com\/uc\?export=view&id=([^&]+)'),
    ];

    for (var pattern in patterns) {
      final match = pattern.firstMatch(link);
      if (match != null) {
        final fileId = match.group(1);
        return 'https://drive.google.com/uc?export=view&id=$fileId';
      }
    }

    return link; // fallback, better than returning null
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLatLng == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Please select a valid location")));
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please select a date')));
      return;
    }

    if (_selectedTime == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please select a time')));
      return;
    }

    final convertedLink = convertDriveLinkToDirect(_driveLinkController.text);

    if (convertedLink == null || !convertedLink.startsWith("http")) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid Google Drive link')),
      );
      return;
    }

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Shared run data
      final runData = {
        'runName': _runNameController.text,
        'description': _descriptionController.text,
        'link': _stravalinkController.text,
        'meetPoint': _meetPointController.text,
        'sipLocation': _sipLocationController.text,
        'date': _selectedDate,
        'time': _selectedTime != null ? formatTimeOfDay24(_selectedTime!) : null,
        'lat': _selectedLatLng!['lat'],
        'long': _selectedLatLng!['lng'],
        'image': convertedLink,
      };

      if (isEditMode) {
        // Edit existing run
        runData['updatedAt'] = Timestamp.now();

        await FirebaseFirestore.instance
            .collection('runs')
            .doc(widget.runNumber)
            .update(runData);
      } else {
        // Add new fields for new run
        runData.addAll({
          'runNumber': int.parse(_runNumberController.text),
          'numPeople': 0,
          'numPeople3km': 0,
          'numPeople5km': 0,
          'numPeople7km': 0,
          'viewIsSelected': false,
          'createdAt': Timestamp.now(),
        });

        await FirebaseFirestore.instance
            .collection('runs')
            .doc(_runNumberController.text)
            .set(runData);
      }

      Navigator.of(context).pop();
    } catch (e) {
      // Dismiss loading if error
      Navigator.of(context).pop();

      // Optional: show error dialog/snackbar
      print('Error saving run: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save run.')));

      // Hide loading
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditMode
                ? 'Run updated successfully!'
                : 'Run created successfully!',
          ),
        ),
      );

      if (isEditMode) {
        // Go back to run page
        Navigator.of(context).pop(true);
      } else {
        // Clear form for creating another run
        _runNameController.clear();
        _descriptionController.clear();
        _driveLinkController.clear();
        _runNumberController.clear();
        _stravalinkController.clear();
        _meetPointController.clear();
        _sipLocationController.clear();
        setState(() {
          _selectedDate = null;
          _selectedTime = null;
        });
      }
    } catch (e) {
      // Hide loading
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error ${isEditMode ? 'updating' : 'creating'} run: $e',
          ),
        ),
      );
    }
  }

  String formatTimeOfDay24(TimeOfDay tod) {
    final hour = tod.hour.toString().padLeft(2, '0');
    final minute = tod.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditMode ? 'Edit Run #${widget.runNumber}' : 'Create Run',
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Run number field - readonly in edit mode
              if (isEditMode)
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Run Number: ${widget.runNumber}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                )
              else
                TextFormField(
                  controller: _runNumberController,
                  decoration: InputDecoration(labelText: 'Run Number'),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Enter run number'
                      : null,
                ),

              SizedBox(height: 16),

              TextFormField(
                controller: _runNameController,
                decoration: InputDecoration(labelText: 'Run Name'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter run name' : null,
              ),

              SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter description' : null,
              ),

              SizedBox(height: 16),

              TextField(
                controller: _searchController,
                decoration: InputDecoration(hintText: 'Add Run Loc'),
                onChanged: (value) {
                  setState(() {});
                },
              ),
              Visibility(
                visible: _searchController.text.isEmpty ? false : true,
                child: SizedBox(
                  height: 165,
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: listOfLocations.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () async {
                          final coords = await getPlaceLatLng(
                            listOfLocations[index]['place_id'],
                          );
                          setState(() {
                            _selectedLatLng = coords;
                            _selectedLocation =
                                listOfLocations[index]['description'];
                            _searchController.text = _selectedLocation!;
                            listOfLocations = []; // Clear the suggestions
                          });
                        },
                        child: ListTile(
                          title: Text(listOfLocations[index]['description']),
                        ),
                      );
                    },
                  ),
                ),
              ),

              ///UNCOMPLETE CODE FOR MY LOCATION
              /*Container(
                margin: EdgeInsets.only(top: 20),
                child: ElevatedButton(onPressed: (){}, child: Row(children: [
                  Icon(Icons.my_location, color: Colors.green),
                  Text('My Location', style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green)
                  ),

                ],
                ),
                ),
              ),*/
              SizedBox(height: 16),

              TextButton(
                onPressed: _pickDate,
                child: Text(
                  _selectedDate == null
                      ? 'Select Date'
                      : 'Date: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}',
                ),
              ),

              SizedBox(height: 16),

              TextButton(
                onPressed: _pickTime,
                child: Text(
                  _selectedTime == null
                      ? 'Select Time'
                      : 'Time: ${_selectedTime != null ? formatTimeOfDay24(_selectedTime!) : 'No time selected'}',
                ),
              ),

              SizedBox(height: 16),

              TextFormField(
                controller: _stravalinkController,
                decoration: InputDecoration(labelText: 'StravaLink'),
                validator: (value) =>
                value == null || value.isEmpty ? 'Enter Strava Link' : null,
              ),

              SizedBox(height: 16),

              TextFormField(
                controller: _meetPointController,
                decoration: InputDecoration(labelText: 'Meet Point'),
                validator: (value) =>
                value == null || value.isEmpty ? 'Enter meet Point' : null,
              ),

              SizedBox(height: 16),

              TextFormField(
                controller: _sipLocationController,
                decoration: InputDecoration(labelText: 'Sip Location'),
                validator: (value) =>
                value == null || value.isEmpty ? 'Enter Sip Location' : null,
              ),

              SizedBox(height: 16),

              TextFormField(
                controller: _driveLinkController,
                decoration: InputDecoration(
                  labelText: 'Google Drive Link',
                  hintText:
                      'Google Drive share link',
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Enter link'
                    : null,
              ),

              SizedBox(height: 24),

              if (isEditMode)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        child: Text('Update Run'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Cancel'),
                      ),
                    ),
                  ],
                )
              else
                ElevatedButton(
                  onPressed: _submitForm,
                  child: Text('Create Run'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _runNameController.dispose();
    _descriptionController.dispose();
    _driveLinkController.dispose();
    _runNumberController.dispose();
    _searchController.dispose();
    _stravalinkController.dispose();
    _meetPointController.dispose();
    _sipLocationController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}
