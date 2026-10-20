import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background notifications
  debugPrint("Handling a background message: ${message.messageId}");
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permissions (especially iOS/Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permission');
    } else {
      debugPrint('User declined or has not accepted notification permission');
    }

    // Configure foreground notification presentation options for iOS
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Received foreground message: ${message.notification?.title}');
      final notification = message.notification;
      if (notification != null) {
        NotificationService().showNotification(
          title: notification.title ?? 'Ablerite Alert',
          body: notification.body ?? '',
          payload: message.data.toString(),
        );
      }
    });

    // Listen for when notification is tapped and opens the app
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM message opened app: ${message.notification?.title}');
    });

    // Listen to token refresh
    _fcm.onTokenRefresh.listen((newToken) async {
      debugPrint("FCM Token Refreshed: $newToken");
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await _saveTokenToSupabase(userId, newToken);
      }
    });

    _isInitialized = true;
  }

  Future<void> registerToken(String userId) async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        debugPrint("FCM Registration Token: $token");
        await _saveTokenToSupabase(userId, token);
      }
    } catch (e) {
      debugPrint("Error registering FCM token: $e");
    }
  }

  Future<void> deleteToken() async {
    try {
      if (Platform.isIOS && await _fcm.getAPNSToken() == null) {
        debugPrint(
          'Skipping FCM token deletion until an APNs token is available.',
        );
        return;
      }
      final token = await _fcm.getToken();
      if (token != null) {
        await Supabase.instance.client
            .from('fcm_tokens')
            .delete()
            .eq('token', token);
      }
      await _fcm.deleteToken();
      debugPrint("FCM Token deleted successfully.");
    } on FirebaseException catch (error) {
      if (error.code == 'apns-token-not-set') {
        debugPrint(
          'Skipping FCM token deletion until an APNs token is available.',
        );
        return;
      }
      debugPrint("Error deleting FCM token: $error");
    } catch (e) {
      debugPrint("Error deleting FCM token: $e");
    }
  }

  Future<void> _saveTokenToSupabase(String userId, String token) async {
    try {
      final deviceType = Platform.isIOS
          ? 'ios'
          : (Platform.isAndroid ? 'android' : 'web');

      // Upsert token in database
      await Supabase.instance.client.from('fcm_tokens').upsert({
        'user_id': userId,
        'token': token,
        'device_type': deviceType,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'token');
      debugPrint("FCM Token successfully synced with Supabase.");
    } catch (e) {
      debugPrint("Failed to sync FCM Token with Supabase: $e");
    }
  }
}
