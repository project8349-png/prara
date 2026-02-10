import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadProfilePhoto(String uid, File file) async {
    final ref = _storage.ref().child('profilePhotos').child('$uid.jpg');
    final uploadTask = await ref.putFile(file);
    if (uploadTask.state == TaskState.success) {
      final url = await ref.getDownloadURL();
      return url;
    }
    return null;
  }
}
