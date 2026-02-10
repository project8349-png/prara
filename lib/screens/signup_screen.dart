import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _auth = AuthService();
  final _storage = StorageService();
  XFile? _picked;
  bool _loading = false;

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 80);
    if (x != null) setState(() => _picked = x);
  }

  void _submit() async {
    setState(() => _loading = true);
    try {
      final user = await _auth.signUp(_email.text.trim(), _password.text.trim(), _name.text.trim(), _username.text.trim());
      if (user != null && _picked != null) {
        final url = await _storage.uploadProfilePhoto(user.uid, File(_picked!.path));
        if (url != null) await _auth.updatePhoto(user.uid, url);
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          GestureDetector(
            onTap: _pickPhoto,
            child: CircleAvatar(
              radius: 44,
              backgroundImage: _picked != null ? FileImage(File(_picked!.path)) : null,
              child: _picked == null ? const Icon(Icons.camera_alt) : null,
            ),
          ),
          const SizedBox(height: 12),
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Full name')),
          TextField(controller: _username, decoration: const InputDecoration(labelText: 'Username')),
          TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
          TextField(controller: _password, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loading ? null : _submit, child: _loading ? const CircularProgressIndicator() : const Text('Sign up'))
        ]),
      ),
    );
  }
}
