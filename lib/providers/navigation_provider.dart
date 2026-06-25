import 'package:flutter/material.dart';

class NavigationProvider with ChangeNotifier {
  int _currentIndex = 0;
  bool _shouldScrollToNotification = false;

  int get currentIndex => _currentIndex;
  bool get shouldScrollToNotification => _shouldScrollToNotification;

  void setIndex(int index, {bool scrollToNotification = false}) {
    _currentIndex = index;
    _shouldScrollToNotification = scrollToNotification;
    notifyListeners();
  }

  void clearScrollFlag() {
    _shouldScrollToNotification = false;
  }
}
