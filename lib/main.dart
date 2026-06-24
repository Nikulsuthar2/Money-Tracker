import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/core/router/app_router.dart';
import 'package:money_manager/core/theme/app_theme.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:money_manager/core/theme/theme_provider.dart';
import 'package:money_manager/features/settings/application/security_provider.dart';
import 'package:money_manager/features/settings/data/backup_service.dart';
import 'package:gap/gap.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    runApp(const ProviderScope(child: MoneyManagerApp()));
  } catch (e, stackTrace) {
    debugPrint('Error initializing Isar: $e');
    runApp(InitializationErrorApp(error: e, stackTrace: stackTrace));
  }
}

class MoneyManagerApp extends ConsumerStatefulWidget {
  const MoneyManagerApp({super.key});

  @override
  ConsumerState<MoneyManagerApp> createState() => _MoneyManagerAppState();
}

class _MoneyManagerAppState extends ConsumerState<MoneyManagerApp> with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Trigger auth on start if enabled
    Future.microtask(() {
      final security = ref.read(securityProvider);
      if (security.isBiometricEnabled && !security.isAuthenticated) {
        ref.read(securityProvider.notifier).authenticate();
      }
      
      // Initialize backup service globally
      ref.read(backupServiceProvider);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
       // Lock app when going background if enabled
       ref.read(securityProvider.notifier).lock();
    }
    if (state == AppLifecycleState.resumed) {
       final security = ref.read(securityProvider);
       if (security.isBiometricEnabled && !security.isAuthenticated) {
          ref.read(securityProvider.notifier).authenticate();
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final dynamicEnabled = ref.watch(dynamicColorProvider);
    final security = ref.watch(securityProvider);

    final manualColor = ref.watch(manualThemeColorProvider);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        ColorScheme? lightScheme;
        ColorScheme? darkScheme;

        if (dynamicEnabled && lightDynamic != null) {
          lightScheme = lightDynamic;
          darkScheme = darkDynamic;
        } else {
          lightScheme = ColorScheme.fromSeed(seedColor: Color(manualColor));
          darkScheme = ColorScheme.fromSeed(seedColor: Color(manualColor), brightness: Brightness.dark);
        }

        return MaterialApp.router(
          title: 'Money Tracker',
          theme: AppTheme.lightTheme(lightScheme),
          darkTheme: AppTheme.darkTheme(darkScheme),
          themeMode: themeMode,
          routerConfig: router,
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
             // Overlay Lock Screen
             if (security.isBiometricEnabled && !security.isAuthenticated) {
               return _LockScreen(onUnlock: () {
                 ref.read(securityProvider.notifier).authenticate();
               });
             }
             return child!;
          },
        );
      },
    );
  }
}

class _LockScreen extends StatelessWidget {
  final VoidCallback onUnlock;
  const _LockScreen({required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Colors.teal),
            const Gap(24),
            const Text('App Locked', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Gap(16),
            FilledButton.icon(
              onPressed: onUnlock,
              icon: const Icon(Icons.fingerprint),
              label: const Text('Unlock'),
            ),
          ],
        ),
      ),
    );
  }
}

class InitializationErrorApp extends StatelessWidget {
  final Object error;
  final StackTrace stackTrace;

  const InitializationErrorApp({
    super.key,
    required this.error,
    required this.stackTrace,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red.shade50,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Initialization Error',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'The app could not start because the database failed to load. Please screenshot this issue.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      error.toString(),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Stack Trace:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    stackTrace.toString().split('\n').take(5).join('\n'),
                     style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

