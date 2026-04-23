import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SetupProfileState {
  final bool isLoading;
  final String? error;

  const SetupProfileState({this.isLoading = false, this.error});

  SetupProfileState copyWith({bool? isLoading, String? error}) =>
      SetupProfileState(isLoading: isLoading ?? this.isLoading, error: error);
}

final setupProfileViewModelProvider =
    NotifierProvider<SetupProfileViewModel, SetupProfileState>(SetupProfileViewModel.new);

class SetupProfileViewModel extends Notifier<SetupProfileState> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  @override
  SetupProfileState build() => const SetupProfileState();

  Future<bool> setupUsername(String username) async {
    final user = _auth.currentUser;
    if (user == null) {
      state = state.copyWith(error: 'User not authenticated.');
      return false;
    }

    final name = username.trim();
    if (name.length < 3) {
      state = state.copyWith(error: 'Username must be at least 3 characters.');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Check if username is taken
      final doc = await _db.collection('usernames').doc(name.toLowerCase()).get();
      if (doc.exists && doc.data()?['uid'] != user.uid) {
        state = state.copyWith(isLoading: false, error: 'Username is already taken.');
        return false;
      }

      await user.updateDisplayName(name);

      // Write username → email mapping
      await _db.collection('usernames').doc(name.toLowerCase()).set({
        'uid': user.uid,
        'email': user.email ?? '',
      });

      // Create/Repair user document
      await _db.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': name,
        'avatarId': 'default',
        'level': 1,
        'totalScore': 0,
        'worldRank': 0,
        'matchesPlayed': 0,
        'currentStreak': 0,
        'bestStreak': 0,
        'dailySortDate': null,
        'dailySortScore': 0,
        'dailySkipsUsed': 0,
        'dailySkipDate': null,
        'clubIds': [],
        'primaryClubId': null,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to setup profile. Try again.');
      return false;
    }
  }
}
