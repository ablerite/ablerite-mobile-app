import 'package:flutter/material.dart';

final appScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void showAppSnackBar(SnackBar snackBar) {
  final messenger = appScaffoldMessengerKey.currentState;
  if (messenger == null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showAppSnackBar(snackBar);
    });
    return;
  }

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(snackBar);
}
