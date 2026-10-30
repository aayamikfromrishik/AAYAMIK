import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/demo_repository.dart';
import 'data/models.dart';
import 'data/repository.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/profile_setup_screen.dart';
import 'screens/home_shell.dart';
import 'ui/theme.dart';
import 'widgets/common.dart';

class BaakiBuildApp extends StatelessWidget {
  const BaakiBuildApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BAAKI BUILD',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      builder: demoMode ? (context, child) => _DemoStrip(child: child!) : null,
      home: !demoMode
          ? const AuthGate()
          : Uri.base.queryParameters['start'] == 'home'
              ? const ProfileGate()
              : const LoginScreen(),
    );
  }
}

/// Login screen when signed out; profile setup on first sign-in; app otherwise.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;
    return StreamBuilder<AuthState>(
      stream: auth.onAuthStateChange,
      builder: (context, _) {
        final user = auth.currentUser;
        if (user == null) return const LoginScreen();
        return ProfileGate(key: ValueKey(user.id));
      },
    );
  }
}

class ProfileGate extends StatefulWidget {
  const ProfileGate({super.key});

  @override
  State<ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<ProfileGate> {
  late Future<Profile?> _profile = Repository.instance.myProfile();

  void _reload() => setState(() => _profile = Repository.instance.myProfile());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Profile?>(
      future: _profile,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snap.hasError) {
          return Scaffold(body: ErrorView(error: snap.error!, onRetry: _reload));
        }
        if (snap.data == null) return ProfileSetupScreen(onSaved: _reload);
        return const HomeShell();
      },
    );
  }
}

/// Shown when the app was built without the Supabase settings.
class MissingConfigApp extends StatelessWidget {
  const MissingConfigApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: buildTheme(),
      debugShowCheckedModeBanner: false,
      home: const Scaffold(
        body: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'App is not configured.\n\nBuild it with:\n'
              '--dart-define=SUPABASE_URL=...\n--dart-define=SUPABASE_PUBLISHABLE_KEY=...',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

/// Thin strip on top of every screen in demo builds.
class _DemoStrip extends StatelessWidget {
  const _DemoStrip({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Material(
        color: Brand.primary,
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 24,
            width: double.infinity,
            child: Center(
              child: Text(
                'DEMO · sample listings · no real payments',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Brand.onPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
              ),
            ),
          ),
        ),
      ),
      Expanded(child: MediaQuery.removePadding(context: context, removeTop: true, child: child)),
    ]);
  }
}
