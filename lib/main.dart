import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'services/api_service.dart';
import 'screens/splash_screen.dart';
import 'screens/notifications_screen.dart';
import 'localization.dart';

class AppColors {
  static const bg = Color(0xFF0B0B10);
  static const surface = Color(0xFF15151C);
  static const fieldFill = Color(0xFF1A1A22);
  static const border = Color(0xFF2C2C36);
  static const hint = Color(0xFF8E8E99);
  static const primary = Color(0xFF6C4CF1);
  static const white = Colors.white;
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background messages are handled automatically by the OS notification tray.
  // No action needed here unless custom background processing is required.
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    // Firebase init failure shouldn't block the app — push notifications just won't work
  }

  await AppLanguage.instance.load();
  runApp(const MyGameApp());
}

class MyGameApp extends StatefulWidget {
  const MyGameApp({super.key});

  @override
  State<MyGameApp> createState() => _MyGameAppState();
}

class _MyGameAppState extends State<MyGameApp> {
  @override
  void initState() {
    super.initState();
    _setupFcm();
  }

  Future<void> _setupFcm() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      final token = await messaging.getToken();
      if (token != null) {
        final loggedIn = await ApiService.getToken();
        if (loggedIn != null) {
          await ApiService.saveFcmToken(token);
        }
      }

      messaging.onTokenRefresh.listen((newToken) async {
        final loggedIn = await ApiService.getToken();
        if (loggedIn != null) {
          await ApiService.saveFcmToken(newToken);
        }
      });

      // Foreground messages: show a snackbar-style banner via a top-level overlay
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final context = navigatorKey.currentContext;
        if (context != null && message.notification != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${tr(message.notification!.title ?? '')}: ${tr(message.notification!.body ?? '')}'),
              backgroundColor: AppColors.surface,
              action: SnackBarAction(
                label: tr('View'),
                onPressed: () {
                  navigatorKey.currentState?.push(
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  );
                },
              ),
            ),
          );
        }
      });

      // Notification tapped while app was in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        );
      });

      // App opened from a terminated state via notification tap
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          );
        });
      }
    } catch (e) {
      // Non-critical — app continues without push notifications
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppLanguage.instance,
      builder: (context, _) => MaterialApp(
      navigatorKey: navigatorKey,
      locale: Locale(AppLanguage.instance.localeCode),
      title: 'MYGame Marketplace',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          surface: AppColors.surface,
        ),
        brightness: Brightness.dark,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.bg,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primary.withOpacity(0.25),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 11, color: Colors.white),
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.fieldFill,
          hintStyle: const TextStyle(color: AppColors.hint),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.white54),
          ),
        ),
        dividerTheme: const DividerThemeData(color: AppColors.border),
        listTileTheme: const ListTileThemeData(
          iconColor: AppColors.hint,
          textColor: Colors.white,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? AppColors.primary : AppColors.hint),
          trackColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected)
                  ? AppColors.primary.withOpacity(0.4)
                  : AppColors.border),
        ),
      ),
      themeMode: ThemeMode.dark,
      home: const SplashScreen(),
    ),
    );
  }
}
