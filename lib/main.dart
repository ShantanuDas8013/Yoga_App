import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoga_session_app/features/yoga_session/screens/session_screen.dart';
import 'package:yoga_session_app/features/yoga_session/notifier/session_notifier.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Optimize memory usage and performance
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    // ProviderScope is required to use Riverpod for state management
    const ProviderScope(child: MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6D9EEB),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      fontFamily: 'Roboto',
    );

    return MaterialApp(
      title: 'Yoga Flow',
      theme: baseTheme.copyWith(
        scaffoldBackgroundColor: const Color(0xFFF7F7FB),
        textTheme: baseTheme.textTheme.apply(
          bodyColor: const Color(0xFF2E2E4F),
          displayColor: const Color(0xFF2E2E4F),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6D9EEB),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? const Color(0xFF6D9EEB)
                : Colors.grey.shade300,
          ),
          trackColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? const Color(0xFFB4AEE8)
                : Colors.grey.shade400,
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const _LifecycleWrapper(child: SessionScreen()),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(1.0)),
        child: child!,
      ),
    );
  }
}

/// Wraps the app to listen to lifecycle changes and forward them to the
/// SessionNotifier so audio can be paused/resumed appropriately.
class _LifecycleWrapper extends StatefulWidget {
  final Widget child;
  const _LifecycleWrapper({required this.child});

  @override
  State<_LifecycleWrapper> createState() => _LifecycleWrapperState();
}

class _LifecycleWrapperState extends State<_LifecycleWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Use context.mounted check not needed here since WidgetsBinding ensures call sequence.
    // We access provider only if mounted.
    if (!mounted) return;
    // Defer provider access to next frame to avoid setState during build edge cases.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final container = ProviderScope.containerOf(context, listen: false);
      final notifier = container.read(sessionNotifierProvider.notifier);
      notifier.handleLifecycle(state);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
