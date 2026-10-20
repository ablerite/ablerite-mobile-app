import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DeviceLayoutService {
  const DeviceLayoutService._();

  static bool get isTablet {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final logicalSize = view.physicalSize / view.devicePixelRatio;
    return logicalSize.shortestSide >= 600;
  }

  static Future<void> applyPreferredOrientations() {
    return SystemChrome.setPreferredOrientations(
      isTablet
          ? DeviceOrientation.values
          : [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
    );
  }
}
