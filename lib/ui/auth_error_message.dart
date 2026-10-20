import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

const String offlineLoginMessage =
    'Connect to Wi-Fi or a cellular network to log in.';

String authErrorMessage(Object error, {required String fallback}) {
  if (_isOfflineAuthError(error)) return offlineLoginMessage;
  if (error is AuthException) return error.message;
  return fallback;
}

bool _isOfflineAuthError(Object error) {
  if (error is AuthRetryableFetchException && error.statusCode == null) {
    return true;
  }
  if (error is TimeoutException || error is http.ClientException) return true;

  // Social-auth platform plugins can surface native network errors directly.
  final message = error.toString().toLowerCase();
  return message.contains('socketexception') ||
      message.contains('failed host lookup') ||
      message.contains('network is unreachable') ||
      message.contains('internet connection appears to be offline') ||
      message.contains('not connected to the internet');
}
