import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  bool get isDark {
    return _mode == ThemeMode.dark;
  }

  void toggle() {
    if (_mode == ThemeMode.dark) {
      _mode = ThemeMode.light;
    } else {
      _mode = ThemeMode.dark;
    }
    notifyListeners();
  }

  void setMode(ThemeMode mode) {
    _mode = mode;
    notifyListeners();
  }
}
