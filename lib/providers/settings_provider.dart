import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeChoice { white, black, lake, slate }

enum HomeScreenChoice { overview, focus }

extension HomeScreenChoiceLabel on HomeScreenChoice {
  String get label => switch (this) {
    HomeScreenChoice.overview => 'Overview',
    HomeScreenChoice.focus => 'Power Focus',
  };
}

extension AppThemeChoiceLabel on AppThemeChoice {
  String get label {
    switch (this) {
      case AppThemeChoice.white:
        return 'White';
      case AppThemeChoice.black:
        return 'Black';
      case AppThemeChoice.lake:
        return 'Lake';
      case AppThemeChoice.slate:
        return 'Slate';
    }
  }
}

class SettingsProvider extends ChangeNotifier {
  static const String _textScaleFactorKey = 'textScaleFactor';
  static const String _isDarkModeKey = 'isDarkMode';
  static const String _themeChoiceKey = 'themeChoice';
  static const String _homeScreenChoiceKey = 'homeScreenChoice';
  double _textScaleFactor = 1.0;
  AppThemeChoice _themeChoice = AppThemeChoice.lake;
  HomeScreenChoice _homeScreenChoice = HomeScreenChoice.overview;
  late final Future<void> loaded;

  double get textScaleFactor => _textScaleFactor;
  AppThemeChoice get themeChoice => _themeChoice;
  HomeScreenChoice get homeScreenChoice => _homeScreenChoice;
  bool get isDarkMode => _themeChoice == AppThemeChoice.black;

  SettingsProvider() {
    loaded = _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _textScaleFactor = prefs.getDouble(_textScaleFactorKey) ?? 1.0;
    final themeName = prefs.getString(_themeChoiceKey);
    _themeChoice = _themeChoiceFromStorage(
      themeName,
      legacyDarkMode: prefs.getBool(_isDarkModeKey),
    );
    _homeScreenChoice = switch (prefs.getString(_homeScreenChoiceKey)) {
      'focus' => HomeScreenChoice.focus,
      _ => HomeScreenChoice.overview,
    };
    notifyListeners();
  }

  AppThemeChoice _themeChoiceFromStorage(
    String? value, {
    required bool? legacyDarkMode,
  }) {
    switch (value) {
      case 'light':
      case 'white':
        return AppThemeChoice.white;
      case 'dark':
      case 'black':
        return AppThemeChoice.black;
      case 'slate':
        return AppThemeChoice.slate;
      case 'lake':
        return AppThemeChoice.lake;
    }
    if (legacyDarkMode == true) return AppThemeChoice.black;
    return AppThemeChoice.lake;
  }

  Future<void> setTextScaleFactor(double scaleFactor) async {
    if (_textScaleFactor != scaleFactor) {
      _textScaleFactor = scaleFactor;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_textScaleFactorKey, scaleFactor);
      notifyListeners();
    }
  }

  Future<void> setDarkMode(bool isDarkMode) async {
    await setThemeChoice(
      isDarkMode ? AppThemeChoice.black : AppThemeChoice.white,
    );
  }

  Future<void> setThemeChoice(AppThemeChoice choice) async {
    if (_themeChoice == choice) return;
    _themeChoice = choice;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeChoiceKey, choice.name);
    await prefs.setBool(_isDarkModeKey, choice == AppThemeChoice.black);
    notifyListeners();
  }

  Future<void> setHomeScreenChoice(HomeScreenChoice choice) async {
    if (_homeScreenChoice == choice) return;
    _homeScreenChoice = choice;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_homeScreenChoiceKey, choice.name);
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    await setDarkMode(!isDarkMode);
  }
}
