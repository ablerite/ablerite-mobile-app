import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:bytebrew_sdk/bytebrew_sdk.dart';
import 'providers/settings_provider.dart';
import 'ui/login_page.dart';
import 'ui/auth_gate.dart';
import 'ui/app_messenger.dart';
import 'services/notification_service.dart';
import 'services/subscription_service.dart';
import 'services/system_ui_service.dart';
import 'services/device_layout_service.dart';
import 'services/fcm_service.dart';
import 'services/secure_local_storage.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == workManagerTaskName) {
      // Workmanager task handled in notification_service.dart
    }
    return Future.value(true);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _initializeByteBrew();

  // Phones keep the established portrait-native experience. Tablets can use
  // either orientation so the adaptive rail and wide layouts can take
  // advantage of iPad/Android tablet screens.
  await DeviceLayoutService.applyPreferredOrientations();

  // True fullscreen: bars are hidden and only overlay on swipe (no
  // relayout), auto-fading back out when idle — see SystemUiService.
  await SystemUiService.apply(SystemUiMode.immersiveSticky);

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    authOptions: const FlutterAuthClientOptions(
      localStorage: SecureLocalStorage(),
    ),
  );

  // Initialize Firebase for Push Notifications if config is present
  if (dotenv.env['FIREBASE_PROJECT_ID'] != null &&
      dotenv.env['FIREBASE_PROJECT_ID']!.isNotEmpty) {
    try {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: Platform.isAndroid
              ? (dotenv.env['FIREBASE_API_KEY_ANDROID'] ?? '')
              : (dotenv.env['FIREBASE_API_KEY_IOS'] ?? ''),
          appId: Platform.isAndroid
              ? (dotenv.env['FIREBASE_APP_ID_ANDROID'] ?? '')
              : (dotenv.env['FIREBASE_APP_ID_IOS'] ?? ''),
          messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
          projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
        ),
      );
      await FcmService().initialize();
    } catch (e) {
      debugPrint('Failed to initialize Firebase: $e');
    }
  }

  // Initialize WorkManager for habit reminders
  await Workmanager().initialize(callbackDispatcher);

  // Initialize RevenueCat
  await SubscriptionService().init();

  // Resolve the saved home mode before the first Flutter frame. Otherwise the
  // default Overview shell briefly renders before MainScaffold can open Focus.
  final settings = SettingsProvider();
  await settings.loaded;

  runApp(
    ChangeNotifierProvider.value(
      value: settings,
      child: const AbleriteMobileApp(),
    ),
  );
}

void _initializeByteBrew() {
  const androidAppId = String.fromEnvironment('BYTEBREW_ANDROID_APP_ID');
  const androidSdkKey = String.fromEnvironment('BYTEBREW_ANDROID_SDK_KEY');
  const iosAppId = String.fromEnvironment('BYTEBREW_IOS_APP_ID');
  const iosSdkKey = String.fromEnvironment('BYTEBREW_IOS_SDK_KEY');

  if (!Platform.isAndroid && !Platform.isIOS) {
    return;
  }

  final appId = Platform.isAndroid ? androidAppId : iosAppId;
  final sdkKey = Platform.isAndroid ? androidSdkKey : iosSdkKey;

  if (appId.isEmpty || sdkKey.isEmpty) {
    debugPrint(
      'ByteBrew initialization skipped: add the platform App ID and SDK key '
      'as BYTEBREW_* --dart-define values.',
    );
    return;
  }

  ByteBrewSdk.initialize(appId, sdkKey);
}

// Brand colors
const Color _brandGreenDark = Color(
  0xFF10B981,
); // Emerald 500 - Dark mode brand
const Color _brandGreenLight = Color(
  0xFF065F46,
); // Emerald 800 - Light mode brand (darker for contrast)
const Color _darkBlack = Color(0xFF050506);
const Color _darkSurface = Color(0xFF111113);
const Color _darkSurfaceRaised = Color(0xFF181A1B);
const Color _darkSurfaceSoft = Color(0xFF222528);
const Color _darkOutline = Color(0xFF33383B);
const Color _lakeForest = Color(0xFF173A28);
const Color _lakeTeal = Color(0xFF2C5954);
const Color _lakeAqua = Color(0xFF77ADA4);
const Color _lakeMist = Color(0xFFEAF0EC);
const Color _lakeStone = Color(0xFFAEB6B1);
const Color _slateInk = Color(0xFF0B0E12);
const Color _slateNight = Color(0xFF111821);
const Color _slatePanel = Color(0xFF1A232C);
const Color _slatePanelHigh = Color(0xFF25303A);
const Color _slateBlue = Color(0xFF7F9BB8);
const Color _slateTeal = Color(0xFF7FAEA8);
const Color _slateMauve = Color(0xFF9C8AA8);
const Color _slateLine = Color(0xFF3F4A55);
const Color _slateText = Color(0xFFE8ECEF);
const Color _slateMuted = Color(0xFFB5C0C9);

class AbleriteMobileApp extends StatelessWidget {
  const AbleriteMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        // Define dark theme
        final darkTheme = ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: _brandGreenDark,
            brightness: Brightness.dark,
            primary: _brandGreenDark,
            secondary: const Color(0xFF6EE7B7),
            surface: _darkSurface,
            surfaceDim: _darkBlack,
            surfaceBright: _darkSurfaceSoft,
            surfaceContainerLowest: const Color(0xFF0B0C0D),
            surfaceContainerLow: _darkSurface,
            surfaceContainer: _darkSurfaceRaised,
            surfaceContainerHigh: const Color(0xFF1D2022),
            surfaceContainerHighest: _darkSurfaceSoft,
            outline: _darkOutline,
            outlineVariant: const Color(0xFF25292C),
          ),
          scaffoldBackgroundColor: _darkBlack,
          appBarTheme: const AppBarTheme(
            backgroundColor: _darkBlack,
            foregroundColor: Colors.white,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.light,
          ),
          cardTheme: CardThemeData(
            color: _darkSurfaceRaised,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.black.withAlpha(90),
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: _darkSurfaceRaised,
            surfaceTintColor: Colors.transparent,
          ),
          dividerColor: _darkOutline,
          iconTheme: const IconThemeData(color: Color(0xFFE6E8E7)),
          textTheme: ThemeData.dark().textTheme.apply(
            bodyColor: const Color(0xFFEDEFEF),
            displayColor: Colors.white,
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: _darkBlack,
            selectedItemColor: _brandGreenDark,
            unselectedItemColor: Color(0xFF8D9491),
          ),
          useMaterial3: true,
        );

        // Define light theme with slightly darker green brand
        final whiteTheme = ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: _brandGreenLight,
            brightness: Brightness.light,
            surface: Colors.white,
            primary: _brandGreenLight,
          ),
          scaffoldBackgroundColor: const Color(0xFFF9FAFB),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(
              0xFFF9FAFB,
            ), // Match scaffold for seamless look
            foregroundColor: Color(0xFF18181B),
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.dark,
          ),
          useMaterial3: true,
        );

        final lakeTheme = ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: _lakeTeal,
            brightness: Brightness.light,
            primary: _lakeForest,
            secondary: _lakeAqua,
            tertiary: _lakeTeal,
            surface: const Color(0xFFF8FBF8),
            surfaceContainerHighest: _lakeMist,
            outline: _lakeStone,
          ),
          scaffoldBackgroundColor: const Color(0xFFF4F8F5),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFF4F8F5),
            foregroundColor: _lakeForest,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.dark,
          ),
          useMaterial3: true,
        );

        final slateTheme = ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: _slateBlue,
            brightness: Brightness.dark,
            primary: _slateBlue,
            secondary: _slateTeal,
            tertiary: _slateMauve,
            surface: _slatePanel,
            surfaceDim: _slateInk,
            surfaceBright: _slatePanelHigh,
            surfaceContainerLowest: _slateInk,
            surfaceContainerLow: _slateNight,
            surfaceContainer: _slatePanel,
            surfaceContainerHigh: Color(0xFF202A34),
            surfaceContainerHighest: _slatePanelHigh,
            outline: _slateLine,
            outlineVariant: Color(0xFF2B3540),
          ),
          scaffoldBackgroundColor: _slateInk,
          appBarTheme: const AppBarTheme(
            backgroundColor: _slateInk,
            foregroundColor: _slateText,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.light,
          ),
          cardTheme: CardThemeData(
            color: _slatePanel,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.black.withAlpha(110),
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: _slatePanel,
            surfaceTintColor: Colors.transparent,
          ),
          dividerColor: _slateLine,
          iconTheme: const IconThemeData(color: _slateText),
          textTheme: ThemeData.dark().textTheme.apply(
            bodyColor: _slateText,
            displayColor: Colors.white,
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: _slateInk,
            selectedItemColor: _slateBlue,
            unselectedItemColor: _slateMuted,
          ),
          useMaterial3: true,
        );

        final selectedTheme = switch (settings.themeChoice) {
          AppThemeChoice.black => darkTheme,
          AppThemeChoice.lake => lakeTheme,
          AppThemeChoice.slate => slateTheme,
          AppThemeChoice.white => whiteTheme,
        };

        return MaterialApp(
          title: 'Ablerite',
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: appScaffoldMessengerKey,
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            final adjustedMediaQuery = mediaQuery.copyWith(
              textScaler: TextScaler.linear(settings.textScaleFactor),
            );
            final content = MediaQuery(data: adjustedMediaQuery, child: child!);
            if (mediaQuery.size.shortestSide < 600) return content;

            final popupWidth =
                (mediaQuery.size.width > mediaQuery.size.height ? 820.0 : 680.0)
                    .clamp(0.0, mediaQuery.size.width - 48)
                    .toDouble();
            final theme = Theme.of(context);
            return Theme(
              data: theme.copyWith(
                dialogTheme: theme.dialogTheme.copyWith(
                  constraints: BoxConstraints(maxWidth: popupWidth),
                ),
                bottomSheetTheme: theme.bottomSheetTheme.copyWith(
                  constraints: BoxConstraints(maxWidth: popupWidth),
                ),
              ),
              child: content,
            );
          },
          theme: selectedTheme,
          darkTheme: darkTheme,
          themeMode: ThemeMode.light,
          home: const AuthGate(),
          routes: {'/login': (context) => const LoginPage()},
        );
      },
    );
  }
}
