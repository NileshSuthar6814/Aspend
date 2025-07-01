import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/theme.dart';

class AppThemeProvider extends ChangeNotifier {
  final _settingsBox = Hive.box('settings');
  static const _themeKey = 'theme';

  AppTheme _appTheme = AppTheme.system;

  AppThemeProvider() {
    _loadTheme();
  }

  AppTheme get appTheme => _appTheme;

  bool get isDarkMode {
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    if (_appTheme == AppTheme.system) {
      return brightness == Brightness.dark;
    }
    return _appTheme == AppTheme.dark;
  }

  ThemeMode get themeMode {
    switch (_appTheme) {
      case AppTheme.light:
        return ThemeMode.light;
      case AppTheme.dark:
        return ThemeMode.dark;
      case AppTheme.system:
      return ThemeMode.system;
    }
  }

  void setTheme(AppTheme theme) {
    _appTheme = theme;
    _settingsBox.put(_themeKey, theme.index);
    notifyListeners();
  }

  void _loadTheme() {
    final index = _settingsBox.get(_themeKey, defaultValue: AppTheme.system.index);
    _appTheme = AppTheme.values[index];
  }
}
