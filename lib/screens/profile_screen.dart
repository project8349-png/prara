import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final StorageService _storage = StorageService();
  final AuthService _auth = AuthService();
  String? _photoUrl;
  bool _uploading = false;

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 80);
    if (x == null) return;
    setState(() => _uploading = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final file = File(x.path);
    final url = await _storage.uploadProfilePhoto(uid, file);
    if (url != null) {
      await _auth.updatePhoto(uid, url);
      setState(() => _photoUrl = url);
    }
    setState(() => _uploading = false);
  }

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    // fetch Users doc photoUrl
    if (user != null) {
      final uid = user.uid;
      // lazy fetch
      FirebaseAuth.instance.authStateChanges().listen((u) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Provider.of<ThemeService>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(children: [
          const SizedBox(height: 12),
          _photoUrl != null
+              ? CircleAvatar(radius: 48, backgroundImage: NetworkImage(_photoUrl!))
+              : user?.photoURL != null
+                  ? CircleAvatar(radius: 48, backgroundImage: NetworkImage(user!.photoURL!))
+                  : CircleAvatar(radius: 48, child: Text(user?.displayName != null ? user!.displayName![0] : '?')),
+          const SizedBox(height: 12),
+          Text(user?.displayName ?? 'User'),
+          const SizedBox(height: 8),
+          Text(user?.email ?? ''),
+          const SizedBox(height: 16),
+          ElevatedButton(onPressed: _uploading ? null : _pickAndUpload, child: _uploading ? const CircularProgressIndicator() : const Text('Upload profile photo')),
+          const SizedBox(height: 24),
+          Row(children: [
+            const Text('Dark mode'),
+            const Spacer(),
+            Switch(value: theme.isDark, onChanged: (_) => theme.toggle())
+          ])
        ]),
      ),
    );
  }
}
