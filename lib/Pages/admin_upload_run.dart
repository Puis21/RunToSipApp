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

  final String token = '1234567890';
  String? _selectedLocation;
  Map<String, double>? _selectedLatLng;

  Timer? _debounce;

  var uuid = const Uuid();
  List<dynamic> listOfLocations = [];

  DateTime? _selectedDate;
  bool get isEditMode => widget.runNumber != null;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      _onChange();
    });

    if (isEditMode && widget.initialData != null) {
      // Pre-populate form with existing data for edit mode
      _runNumberController.text = widget.runNumber!;
      _runNameController.text = widget.initialData!['runName'] ?? '';
      _descriptionController.text = widget.initialData!['description'] ?? '';

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

      // Handle image URL - if it's an asset, show in field
      final imageUrl = widget.initialData!['imageUrl'] ?? '';
      _driveLinkController.text = imageUrl;
    }

  }

  _onChange(){
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
    const apiKey = "AIzaSyA604H27JH_Fct5dBUNf3yMOshcahnWUc0";
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
            '?place_id=$placeId'
            '&key=$apiKey'
            '&fields=geometry'
    );

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

    const String apiKey = "AIzaSyA604H27JH_Fct5dBUNf3yMOshcahnWUc0";
    try {
      String baseUrl = "https://maps.googleapis.com/maps/api/place/autocomplete/json";
      String encodedInput = Uri.encodeComponent(input); // Encode the input
      String request = '$baseUrl?input=$encodedInput&key=$apiKey&sessiontoken=$token';

      if (kDebugMode) {
        print("Sending request to: $request");
      }

      var response = await http.get(Uri.parse(request));
      var data = json.decode(response.body);

      if (kDebugMode) {
        print("API Response: $data");
      }

      if (response.statusCode == 200) {
        setState(() {
          listOfLocations = (data['predictions'] as List).take(3).toList(); // Use correct field name and null check
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

  String? convertDriveLinkToDirect(String link) {
    // If it's already an asset path, return as is
    if (link.startsWith('assets/')) {
      return link;
    }

    // Handle Google Drive links
    final regExp = RegExp(r'/d/([^/]+)');
    final match = regExp.firstMatch(link);
    if (match != null && match.groupCount >= 1) {
      final fileId = match.group(1);
      return 'https://drive.google.com/uc?export=view&id=$fileId';
    }

    // If it's neither asset nor Google Drive, return as is (could be direct URL)
    return link;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a valid location")),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please select a date')));
      return;
    }

    final convertedLink = convertDriveLinkToDirect(_driveLinkController.text);

    if (convertedLink == null || convertedLink.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid image path or Google Drive link'),
        ),
      );
      return;
    }

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      final runData = {
        'runName': _runNameController.text,
        'description': _descriptionController.text,
        'date': _selectedDate,
        'lat': _selectedLatLng!['lat'],
        'long': _selectedLatLng!['lng'],
        'imageUrl': convertedLink,
      };

      if (isEditMode) {
        // Update existing run
        runData['updatedAt'] = Timestamp.now();
        await FirebaseFirestore.instance
            .collection('runs')
            .doc(widget.runNumber)
            .update(runData);
      } else {
        // Create new run
        runData.addAll({
          'runNumber': int.parse(_runNumberController.text),
          'numPeople': 0,
          'numPeople3km': 0,
          'numPeople5km': 0,
          'numPeople7km': 0,
          'viewIsSelected': false,
          'lat': _selectedLatLng!['lat'],
          'long': _selectedLatLng!['lng'],
          'createdAt': Timestamp.now(),
        });

        await FirebaseFirestore.instance
            .collection('runs')
            .doc(_runNumberController.text)
            .set(runData);
      }

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
        setState(() {
          _selectedDate = null;
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

              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter description' : null,
              ),

              SizedBox(height: 16),

              TextField(
                controller: _searchController,
                decoration: InputDecoration(hintText: 'Add Run Loc'),
                onChanged: (value) {
                  setState(() {

                  });
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
                          final coords = await getPlaceLatLng(listOfLocations[index]['place_id']);
                          setState(() {
                            _selectedLatLng = coords;
                            _selectedLocation = listOfLocations[index]['description'];
                            _searchController.text = _selectedLocation!;
                            listOfLocations = []; // Clear the suggestions
                          });
                        },
                        child: ListTile(
                          title: Text(listOfLocations[index]['description'],
                          ),
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

              TextFormField(
                controller: _driveLinkController,
                decoration: InputDecoration(
                  labelText: 'Image Path or Google Drive Link',
                  hintText:
                      'e.g., assets/RTSLog.png or Google Drive share link',
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Enter image path or link'
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
    _debounce?.cancel();
    super.dispose();
  }
}
