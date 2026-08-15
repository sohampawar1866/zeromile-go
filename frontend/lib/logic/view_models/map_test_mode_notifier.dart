// lib/logic/view_models/map_test_mode_notifier.dart

import 'package:flutter/material.dart';

/// Global toggle for "Test Mode" on the live map.
///
/// When [isTestMode] is true, 4 simulated demo riders are overlaid on
/// the map alongside any real participants who are actively connected.
/// This allows demos to show a populated map even before real users join.
class MapTestModeNotifier extends ChangeNotifier {
  bool _isTestMode = false;

  bool get isTestMode => _isTestMode;

  void toggle() {
    _isTestMode = !_isTestMode;
    notifyListeners();
  }

  void setValue(bool val) {
    if (_isTestMode == val) return;
    _isTestMode = val;
    notifyListeners();
  }
}
