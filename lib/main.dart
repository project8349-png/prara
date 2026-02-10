import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'services/theme_service.dart';
import 'services/presence_service.dart';
import 'package:flutter/scheduler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: Consumer<ThemeService>(builder: (context, theme, _) {
        return MaterialApp(
          title: 'Studentify',
          theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo, brightness: Brightness.light),
          darkTheme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo, brightness: Brightness.dark),
          themeMode: theme.isDark ? ThemeMode.dark : ThemeMode.light,
          home: AuthPresenceWrapper(child: const HomeScreen(), fallback: const LoginScreen()),
        );
      }),
    );
  }
}

class AuthPresenceWrapper extends StatefulWidget {
  final Widget child;
  final Widget fallback;
  const AuthPresenceWrapper({required this.child, required this.fallback, super.key});

  @override
  State<AuthPresenceWrapper> createState() => _AuthPresenceWrapperState();
}

class _AuthPresenceWrapperState extends State<AuthPresenceWrapper> with WidgetsBindingObserver {
  final PresenceService _presence = PresenceService();
  User? _user;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    FirebaseAuth.instance.authStateChanges().listen((u) {
      _user = u;
      if (u != null) {
        _presence.goOnline();
      } else {
        _presence.goOffline();
      }
      setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_user == null) return;
    if (state == AppLifecycleState.resumed) {
      _presence.goOnline();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _presence.goOffline();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _presence.goOffline();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_user != null) return widget.child;
    return widget.fallback;
  }
}
