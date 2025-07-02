import 'package:cloud_firestore/cloud_firestore.dart';

class AppUserModel{
  final String email;
  final String fullName;
  int level;
  int xp;
  int runsTotal;
  int km3;
  int km5;
  int km7;
  int noDistance;
  bool isAdmin;

  AppUserModel({
    required this.email,
    required this.fullName,
    required this.level,
    required this.xp,
    required this.runsTotal,
    required this.km3,
    required this.km5,
    required this.km7,
    required this.noDistance,
    required this.isAdmin,
  });

  factory AppUserModel.fromMap(Map<String, dynamic> data) {
    return AppUserModel(
      email: data['email'],
      fullName: data['fullName'],
      level: data['Level'],
      xp: data['Xp'],
      runsTotal: data['runs_total'],
      km3: data['3km'],
      km5: data['5km'],
      km7: data['7km'],
      noDistance: data['noDistance'],
      isAdmin: data['isAdmin']
    );
}

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullName': fullName,
      'Level': level,
      'Xp': xp,
      'runs_total': runsTotal,
      '3km': km3,
      '5km': km5,
      '7km': km7,
      'noDistance': noDistance,
      'isAdmin' : isAdmin
    };
  }

  ///ADDED ALL THE LOGIC TO USER PROVIDER
  /// Method to increase XP and level up
/*  Future<void> increaseXp(int amount) async {
    print("Amountxp: $amount");
    print("xp base: $xp");
    print("level base: $level");

    xp += amount;
    if (xp >= checkLevelRequirement()) {
      level++;
      xp = 0; // Reset XP after level-up
    }

    await FirebaseFirestore.instance.collection('users').doc(email).update({
      'Xp': xp,
      'Level': level,
    });

  }

  Future<void> incrementRun(String distanceKey) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(email);

    await userRef.update({
      if(distanceKey != '') distanceKey: FieldValue.increment(1),
      'runs_total': FieldValue.increment(1),
    });

    // Also update local fields
    runsTotal++;
    if (distanceKey == '3km') km3++;
    if (distanceKey == '5km') km5++;
    if (distanceKey == '7km') km7++;
    if (distanceKey == 'noDistance') noDistance--;
  }

  Future<void> decrementRun(String distanceKey) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(email);

    await userRef.update({
      distanceKey: FieldValue.increment(-1),
      'runs_total': FieldValue.increment(-1),
    });

    // Also update local fields
    runsTotal--;
    if (distanceKey == '3km') km3--;
    if (distanceKey == '5km') km5--;
    if (distanceKey == '7km') km7--;
    if (distanceKey == 'noDistance') noDistance--;
  }

  int checkLevelRequirement() {
    if(level == 0) {
      return 1;
    } else {
      return 3;
    }
  }*/

}