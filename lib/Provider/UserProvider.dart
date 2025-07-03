import 'dart:async';

import 'package:flutter/material.dart';
import 'package:run_to_sip_app/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:run_to_sip_app/animations/LevelUpAnimation.dart';

final Map<int, String> levelRanks = {
  0: 'Idle Walker',
  1: 'Baby Runner',
  2: 'Starter Runner',
  3: 'Novice Runner',
  4: 'Ass Runner',
  5: 'Legs Runner',
  6: 'King Runner',
};

class UserProvider extends ChangeNotifier {
  AppUserModel? _user;
  bool _isAdmin = false;
  StreamSubscription? _userListener;
  bool _isDisposed = false;

  AppUserModel? get user => _user;
  bool get isAdmin => _isAdmin;

  int get runsTotal => _user?.runsTotal ?? 0;
  int get km3 => _user?.km3 ?? 0;
  int get km5 => _user?.km5 ?? 0;
  int get km7 => _user?.km7 ?? 0;
  int get currentStreak => _user?.currentStreak ?? 0;
  int get maxStreak => _user?.maxStreak ?? 0;
  int get noDistance => _user?.noDistance ?? 0;

  void setUser(AppUserModel newUser) {
    _user = newUser;
    _isAdmin = newUser.isAdmin;
    notifyListeners(); // rebuild widgets
  }

  Future<void> checkAdminStatus() async {
    if (_user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.email)
        .get();

    _isAdmin = doc.data()?['is_admin'] ?? false;
    notifyListeners();
  }

  Future<void> loadUserByEmail(String email) async {
    // Cancel previous listener if exists
    _userListener?.cancel();

    // Real-time listener
    _userListener = FirebaseFirestore.instance
        .collection('users')
        .doc(email)
        .snapshots()
        .listen((doc) {
          if (doc.exists && !_isDisposed) {
            setUser(AppUserModel.fromMap(doc.data()!));
          }
        });

    // Initial load
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(email)
        .get();
    if (doc.exists && !_isDisposed) {
      setUser(AppUserModel.fromMap(doc.data()!));
    }
  }

  Future<void> increaseStreak() async {
    if (_user == null || _isDisposed) return;

    final prevStreak = _user!.currentStreak;

    try {
      _user!.currentStreak++;

      if (_user!.currentStreak > _user!.maxStreak) {
        _user!.maxStreak = _user!.currentStreak;
      }

      notifyListeners();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.email)
          .update({
        'current_streak': _user!.currentStreak,
        'max_streak': _user!.maxStreak,
      });
    } catch (e) {
      if (!_isDisposed) {
        _user!.currentStreak = prevStreak;
        notifyListeners();
      }
      rethrow;
    }
  }

  ///TO DO: Need to add a new var for the user, the get the latest run he has been
  /// and compare it to the latest run, if the difference is let's say more than 8 days
  /// RESEEET
  Future<void> checkResetStreak() async {
    if (_user == null || _isDisposed || currentStreak == 0) return;

    final runsSnapshot = await FirebaseFirestore.instance
        .collection('runs')
        .orderBy('date', descending: true) // Could try runNumber too if i get problems
        .limit(1)
        .get();

    if (runsSnapshot.docs.isEmpty) return;

    final latestRunData = runsSnapshot.docs.first.data();
    final latestRunDate = (latestRunData['date'] as Timestamp).toDate();

    final today = DateTime.now();
    final yesterday = DateTime(today.year, today.month, today.day).subtract(Duration(days: 1));

    print(latestRunDate);
    print(yesterday);

    try {
      if (latestRunDate.isBefore(yesterday)) {
        _user!.currentStreak = 0;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.email)
            .update({'current_streak': 0});
        notifyListeners();
      }
    } catch (e) {
      if (!_isDisposed) {
        _user!.currentStreak = 0;
        notifyListeners();
      }
      rethrow;
    }

  }


  Future<void> increaseXp(int amount, {BuildContext? context}) async {
    if (_user == null || _isDisposed) return;

    try {
      // Optimistic update
      _user!.xp += amount;
      int newLevel = _user!.level;

      final didLevelUp = _user!.xp >= checkLevelRequirement(newLevel);
      if (didLevelUp) {
        newLevel++;
        _user!.xp = 0;

        //print("WAIT LEVEL: $newLevel");
        // Show level-up animation
        if (didLevelUp && context != null) {

          //print("DID LEVEL");

          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).push(
              PageRouteBuilder(
                opaque: false,
                pageBuilder: (_, __, ___) =>
                    LevelUpAnimation(newLevel: newLevel),
              ),
            );
          });
        }
      }

      notifyListeners(); // Immediate UI update

      // Push to Firebase
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.email)
          .update({'Xp': _user!.xp, 'Level': newLevel});
    } catch (e) {
      // Revert on error
      if (!_isDisposed) {
        _user!.xp -= amount;
        notifyListeners();
      }
      rethrow;
    }
  }

  int checkLevelRequirement(int level) {
    return (level == 0) ? 1 : 3;
  }

  double get levelProgress {
    if (_user == null) return 0;
    final requiredXp = checkLevelRequirement(_user!.level);
    return (_user!.xp / requiredXp).clamp(0.0, 1.0);
  }

  String getRank(int level) => levelRanks[level] ?? 'Unknown';

  Future<double> getUserPercentile() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('users').get();

      final totalRuns = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalRuns.add(data['runs_total']);
      }

      totalRuns.sort();
      var num = totalRuns.length;
      //print('Total Runs: $totalRuns');

      int userRuns = _user!.runsTotal;
      int lowerIndex = totalRuns.indexWhere((value) => value == userRuns);
      int upperIndex = totalRuns.lastIndexWhere((value) => value == userRuns);
      int avgIndex = ((lowerIndex + upperIndex) / 2).floor();

      //print('UserIndex: $avgIndex');

      double percentile = (avgIndex / (num - 1)) * 100;
      percentile = double.parse(percentile.toStringAsFixed(0));
      percentile = percentile.clamp(1, 99);

      return percentile;

      //print('User is in the top ${100 - percentile}%');
      //print('User is in the top ${percentile.toStringAsFixed(0)}th percentile');

    } catch (e) {
      print('Error getting users: $e');
    }
    return 0;
  }

  // Call this to increment runs count and update Firestore
  Future<void> incrementRun(String distanceKey) async {
    if (_user == null) return;
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.email);

    await userRef.update({
      if (distanceKey.isNotEmpty) distanceKey: FieldValue.increment(1),
      'runs_total': FieldValue.increment(1),
    });

    // Update local data and notify listeners
    switch (distanceKey) {
      case '3km':
        _user!.km3++;
        break;
      case '5km':
        _user!.km5++;
        break;
      case '7km':
        _user!.km7++;
        break;
      case 'noDistance':
        _user!.noDistance++;
        break;
    }
    _user!.runsTotal++;
    notifyListeners();
  }

  Future<void> decrementRun(String distanceKey) async {
    if (_user == null) return;
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.email);

    await userRef.update({
      distanceKey: FieldValue.increment(-1),
      'runs_total': FieldValue.increment(-1),
    });

    // Update local data and notify listeners
    switch (distanceKey) {
      case '3km':
        _user!.km3--;
        break;
      case '5km':
        _user!.km5--;
        break;
      case '7km':
        _user!.km7--;
        break;
      case 'noDistance':
        _user!.noDistance--;
        break;
    }
    _user!.runsTotal--;
    notifyListeners();
  }

  // Destructor
  @override
  void dispose() {
    _isDisposed = true;
    _userListener?.cancel();
    super.dispose();
  }
}
