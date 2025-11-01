import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontSizeService {
  static const String _key = 'app_font_size';
  static const double _defaultFontSize = 16.0;
  static const double _minFontSize = 10.0;
  static const double _maxFontSize = 30.0;
  static const double _stepSize = 2.0;

  static final FontSizeService instance = FontSizeService._();
  FontSizeService._();

  final ValueNotifier<double> fontSize = ValueNotifier<double>(_defaultFontSize);

  double get currentFontSize => fontSize.value;
  double get minFontSize => _minFontSize;
  double get maxFontSize => _maxFontSize;
  double get stepSize => _stepSize;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSize = prefs.getDouble(_key);
    if (savedSize != null && savedSize >= _minFontSize && savedSize <= _maxFontSize) {
      fontSize.value = savedSize;
    } else {
      fontSize.value = _defaultFontSize;
    }
  }

  Future<void> increaseFontSize() async {
    if (fontSize.value < _maxFontSize) {
      fontSize.value = (fontSize.value + _stepSize).clamp(_minFontSize, _maxFontSize);
      await _saveFontSize();
    }
  }

  Future<void> decreaseFontSize() async {
    if (fontSize.value > _minFontSize) {
      fontSize.value = (fontSize.value - _stepSize).clamp(_minFontSize, _maxFontSize);
      await _saveFontSize();
    }
  }

  Future<void> setFontSize(double newSize) async {
    if (newSize >= _minFontSize && newSize <= _maxFontSize) {
      fontSize.value = newSize;
      await _saveFontSize();
    }
  }

  Future<void> _saveFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_key, fontSize.value);
  }
}

