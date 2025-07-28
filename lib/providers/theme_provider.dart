import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/theme.dart';

class AppThemeProvider extends ChangeNotifier {
  final _settingsBox = Hive.box('settings');
  static const _themeKey = 'theme';
  static const _adaptiveColorKey = 'adaptiveColor';
  static const _customColorKey = 'customSeedColor';
  Color? _customSeedColor;

  AppTheme _appTheme = AppTheme.system;
  bool _useAdaptiveColor = false;

  AppThemeProvider() {
    _loadTheme();
  }

  AppTheme get appTheme => _appTheme;

  bool get isDarkMode {
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
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

  bool get useAdaptiveColor => _useAdaptiveColor;

  Color? get customSeedColor => _customSeedColor;

  void setTheme(AppTheme theme) {
    _appTheme = theme;
    _settingsBox.put(_themeKey, theme.index);
    notifyListeners();
  }

  void setAdaptiveColor(bool value) {
    _useAdaptiveColor = value;
    _settingsBox.put(_adaptiveColorKey, value);
    notifyListeners();
  }

  void setCustomSeedColor(Color? color) {
    _customSeedColor = color;
    if (color != null) {
      _settingsBox.put(_customColorKey, color.value);
    } else {
      _settingsBox.delete(_customColorKey);
    }
    notifyListeners(); // Always notify to trigger theme rebuild
  }

  void _loadTheme() {
    final index =
        _settingsBox.get(_themeKey, defaultValue: AppTheme.system.index);
    _appTheme = AppTheme.values[index];
    _useAdaptiveColor =
        _settingsBox.get(_adaptiveColorKey, defaultValue: false);
    final colorValue = _settingsBox.get(_customColorKey);
    if (colorValue != null) {
      _customSeedColor = Color(colorValue);
    }
  }
}
