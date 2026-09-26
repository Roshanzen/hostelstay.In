import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/landing/screens/landing_screen.dart';
import 'features/authentication/screens/login_screen.dart';
import 'features/navigation/screens/main_scaffold.dart';
import 'state/app_state.dart';

class HostelGharApp extends StatefulWidget {
  final bool? startAtHome;
  final AppState? appState;

  const HostelGharApp({
    super.key,
    this.startAtHome,
    this.appState,
  });

  @override
  State<HostelGharApp> createState() => _HostelGharAppState();
}

class _HostelGharAppState extends State<HostelGharApp> {
  late final AppState _state;
  late final bool _ownedState;

  @override
  void initState() {
    super.initState();
    if (widget.appState != null) {
      _state = widget.appState!;
      _ownedState = false;
    } else {
      _state = AppState();
      _ownedState = true;
    }
  }

  @override
  void dispose() {
    if (_ownedState) {
      _state.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _state,
      builder: (context, _) {
        final bool shouldStartAtHome = widget.startAtHome ?? _state.isLoggedIn;
        return MaterialApp(
          title: 'HostelGhar — Warden Management App',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _state.themeMode,
          home: shouldStartAtHome
              ? MainScaffold(appState: _state)
              : LandingScreen(appState: _state),
          routes: {
            '/landing': (context) => LandingScreen(appState: _state),
            '/login': (context) => LoginScreen(appState: _state),
            '/home': (context) => MainScaffold(appState: _state),
          },
        );
      },
    );
  }
}
