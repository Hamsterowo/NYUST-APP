import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NavigationProvider with ChangeNotifier {
  int _currentIndex = 0;
  static const String _storageKey = 'last_tab_index';

  NavigationProvider() {
    _loadIndex();
  }

  int get currentIndex => _currentIndex;

  Future<void> _loadIndex() async {
    final prefs = await SharedPreferences.getInstance();
    _currentIndex = prefs.getInt(_storageKey) ?? 0;
    notifyListeners();
  }

  Future<void> setIndex(int index) async {
    _currentIndex = index;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_storageKey, index);
  }
}
