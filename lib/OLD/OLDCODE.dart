/*
class _RunPageState extends State<RunPage> {
  RunType? selectedRunType; // track selected type

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildBaseAppBar(context, widget.run.number),
      endDrawer: buildBaseEndDrawer(context),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              child: SizedBox(
                height: 250,
                width: double.infinity,
                child: Image.asset(
                  widget.run.image,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  widget.run.name,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                  style: TextStyle(fontSize: 16),
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
                        style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                      ),
                    ],
                  )
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
                  initialCameraPosition: CameraPosition(target: LatLng(44.416792, 26.191511), zoom: 12),
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
            // *** Here is your checkboxes row ***
            Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: RunType.values.map((type) {
                  Color checkboxColor;
                  Color textColor;

                  // Assign different colors for each type:
                  switch (type) {
                    case RunType.easy:
                      checkboxColor = Colors.green;
                      textColor = Colors.green[800]!;
                      break;
                    case RunType.medium:
                      checkboxColor = Colors.orange;
                      textColor = Colors.orange[800]!;
                      break;
                    case RunType.hard:
                      checkboxColor = Colors.red;
                      textColor = Colors.red[800]!;
                      break;
                  }

                  return Row(
                    children: [
                      Checkbox(
                        activeColor: checkboxColor,
                        value: selectedRunType == type,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              selectedRunType = type;
                            } else {
                              selectedRunType = null; // or keep selection mandatory, then remove this line
                            }
                          });
                        },
                      ),
                      Text(
                        type.label,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
*/

///OLD CREATE PAGE
///
/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateRunPage extends StatefulWidget {
  @override
  _CreateRunPageState createState() => _CreateRunPageState();
}

class _CreateRunPageState extends State<CreateRunPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _runNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _driveLinkController = TextEditingController();
  final TextEditingController _runNumberController = TextEditingController();

  DateTime? _selectedDate;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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
    final regExp = RegExp(r'/d/([^/]+)');
    final match = regExp.firstMatch(link);
    if (match != null && match.groupCount >= 1) {
      final fileId = match.group(1);
      return 'https://drive.google.com/uc?export=view&id=$fileId';
    }
    return null;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a date')),
      );
      return;
    }

    final convertedLink = convertDriveLinkToDirect(_driveLinkController.text);

    if (convertedLink == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid Google Drive link')),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('runs')
        .doc(_runNumberController.text) // Use runNumber as document ID
        .set({
      'runName': _runNameController.text,
      'description': _descriptionController.text,
      'date': _selectedDate,
      'runNumber': _runNumberController.text, // Still store it as a field
      'imageUrl': convertedLink,
      'numPeople': 0,
      'numPeople3km': 0,
      'numPeople5km': 0,
      'numPeople7km': 0,
      'createdAt': Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Run created successfully!')),
    );

    _runNameController.clear();
    _descriptionController.clear();
    _driveLinkController.clear();
    setState(() {
      _selectedDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Run')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _runNumberController,
                decoration: InputDecoration(labelText: 'Run Number'),
                validator: (value) =>
                value == null || value.isEmpty ? 'Enter run number' : null,
              ),
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
              TextButton(
                onPressed: _pickDate,
                child: Text(_selectedDate == null
                    ? 'Select Date'
                    : 'Date: ${_selectedDate!.toLocal()}'.split(' ')[0]),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _driveLinkController,
                decoration:
                InputDecoration(labelText: 'Google Drive Share Link'),
                validator: (value) =>
                value == null || value.isEmpty ? 'Enter link' : null,
              ),
              SizedBox(height: 24),
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
}*/
