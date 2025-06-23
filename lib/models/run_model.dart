import "package:flutter/material.dart";
import 'package:cloud_firestore/cloud_firestore.dart';

enum RunType { threeKm, fiveKm, sevenKm }

extension RunTypeExtension on RunType {
  String get label {
    switch (this) {
      case RunType.threeKm:
        return '3km';
      case RunType.fiveKm:
        return '5km';
      case RunType.sevenKm:
        return '7km';
    }
  }

  String get fieldName {
    // The field name used in Firestore for this run type
    switch (this) {
      case RunType.threeKm:
        return "3km";
      case RunType.fiveKm:
        return "5km";
      case RunType.sevenKm:
        return "7km";
    }
  }

  Color get color {
    switch (this) {
      case RunType.threeKm: return Colors.green;
      case RunType.fiveKm: return Colors.orange;
      case RunType.sevenKm: return Colors.red;
    }
  }
}

class RunModel {
  String name;
  String date;
  int runNumber;
  String description;
  String image = 'assets/RTSLog.png';

  RunType runType = RunType.threeKm;


  int numPeople = 0;
  int numPeople3Km = 0;
  int numPeople5Km = 0;
  int numPeople7Km = 0;

  double lat = 21.502888;
  double long = -157.999006;

  bool viewIsSelected; //Not sure if used


  RunModel({
    required this.name,
    required this.date,
    required this.description,
    required this.runNumber,
    required this.lat,
    required this.long,
    required this.viewIsSelected,
  });

  factory RunModel.fromFirestore(Map<String, dynamic> data) {
    // Extract date safely
    String dateString = '';
    if (data['date'] is Timestamp) {
      Timestamp timestamp = data['date'] as Timestamp;
      DateTime dateTime = timestamp.toDate();
      // Format date dd/MM/yyyy:
      dateString = "${dateTime.day.toString().padLeft(2,'0')}/${dateTime.month.toString().padLeft(2,'0')}/${dateTime.year}";
    } else if (data['date'] is String) {
      dateString = data['date'];
    }

    return RunModel(
      name: data['runName'] ?? '',
      date: dateString,
      description: data['description'] ?? '',
      runNumber: data['runNumber'] ?? 0,
      lat: data['lat'] ?? 21.502888,
      long: data['long'] ?? -157.999006,
      viewIsSelected: data['viewIsSelected'] ?? false,
    );
  }

  ///Old code for manual runs
 /* static List<RunModel> getRuns() {
    List<RunModel> runs = [];

    runs.add(
      RunModel(
        name: 'RUN From me with the demon speed',
        date: '27/09/2025',
        description: 'Lorem ipsum dolor sit amet, ctus elit sed cursus. Vivamus tempus rhoncus tellus, quis commodo.....',
        number: '#20',
        viewIsSelected: false
    )
  );

    return runs;
  }*/

}

