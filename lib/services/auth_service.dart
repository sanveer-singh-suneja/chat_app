import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import 'storage_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();

  User? get currentUser => _auth.currentUser;

  Future<UserModel?> registerUser({
    required String name,
    required String email,
    required String password,
    File? profileImage,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    String imageUrl = '';
    if (profileImage != null) {
      imageUrl = await _storageService.uploadProfileImage(
        cred.user!.uid,
        profileImage,
      );
    }

    final user = UserModel(
      uid: cred.user!.uid,
      name: name,
      email: email,
      profileImage: imageUrl,
      isOnline: true,
      createdAt: Timestamp.now(),
    );

    await _firestore
        .collection('users')
        .doc(cred.user!.uid)
        .set(user.toMap());

    return user;
  }

  Future<UserModel?> loginUser({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _firestore.collection('users').doc(cred.user!.uid).update({
      'isOnline': true,
    });

    final doc =
        await _firestore.collection('users').doc(cred.user!.uid).get();
    return UserModel.fromMap(doc.data()!);
  }

  Future<void> logout() async {
    if (_auth.currentUser != null) {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .update({
        'isOnline': false,
        'lastSeen': Timestamp.now(),
      });
    }
    await _auth.signOut();
  }

  Future<UserModel?> getCurrentUser() async {
    if (_auth.currentUser == null) return null;
    final doc =
        await _firestore.collection('users').doc(_auth.currentUser!.uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  Future<void> setOnline(bool isOnline) async {
    if (_auth.currentUser == null) return;
    final update = isOnline
        ? {'isOnline': true}
        : {'isOnline': false, 'lastSeen': Timestamp.now()};
    await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .update(update);
  }
}
