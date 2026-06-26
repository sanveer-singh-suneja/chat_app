import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../models/message_model.dart';
import 'storage_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StorageService _storageService = StorageService();

  String createChatId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  Stream<List<UserModel>> getAllUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .where((user) => user.uid != _auth.currentUser!.uid)
          .toList();
    });
  }

  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data()))
          .toList();
    });
  }

  Future<void> sendTextMessage({
    required String chatId,
    required String receiverId,
    required String message,
  }) async {
    final senderId = _auth.currentUser!.uid;
    final messageId = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc()
        .id;

    final msg = MessageModel(
      messageId: messageId,
      senderId: senderId,
      receiverId: receiverId,
      message: message,
      messageType: 'text',
      timestamp: Timestamp.now(),
    );

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .set(msg.toMap());

    // Update participants list on chat doc
    await _firestore.collection('chats').doc(chatId).set({
      'participants': [senderId, receiverId],
    }, SetOptions(merge: true));
  }

  Future<void> sendImageMessage({
    required String chatId,
    required String receiverId,
    required File imageFile,
  }) async {
    final senderId = _auth.currentUser!.uid;
    final messageId = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc()
        .id;

    final imageUrl = await _storageService.uploadChatImage(chatId, imageFile);

    final msg = MessageModel(
      messageId: messageId,
      senderId: senderId,
      receiverId: receiverId,
      imageUrl: imageUrl,
      messageType: 'image',
      timestamp: Timestamp.now(),
    );

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .set(msg.toMap());

    await _firestore.collection('chats').doc(chatId).set({
      'participants': [senderId, receiverId],
    }, SetOptions(merge: true));
  }

  Future<void> deleteMessage(String chatId, String messageId) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }
}
