import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _authService.currentUser != null;

  void setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  Future<void> loadCurrentUser() async {
    _currentUser = await _authService.getCurrentUser();
    notifyListeners();
  }

  Future<String?> register({
    required String name,
    required String email,
    required String password,
    File? profileImage,
  }) async {
    try {
      setLoading(true);
      _currentUser = await _authService.registerUser(
        name: name,
        email: email,
        password: password,
        profileImage: profileImage,
      );
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      setLoading(false);
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      setLoading(true);
      _currentUser = await _authService.loginUser(
        email: email,
        password: password,
      );
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      setLoading(false);
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  Future<String?> updateProfileImage(File imageFile) async {
    if (_currentUser == null) return 'Not logged in';
    try {
      setLoading(true);
      final url = await _storageService.uploadProfileImage(
        _currentUser!.uid,
        imageFile,
      );
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .update({'profileImage': url});

      _currentUser = UserModel(
        uid: _currentUser!.uid,
        name: _currentUser!.name,
        email: _currentUser!.email,
        profileImage: url,
        isOnline: _currentUser!.isOnline,
        lastSeen: _currentUser!.lastSeen,
        createdAt: _currentUser!.createdAt,
      );
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      setLoading(false);
    }
  }
}
