import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';

class WeatherProvider with ChangeNotifier {
  final WeatherService _weatherService = WeatherService();

  WeatherData? _weatherData;
  bool _isLoading = false;
  String? _errorMessage;

  WeatherData? get weatherData => _weatherData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchWeather() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _weatherService.fetchWeatherForDouliu();
      if (data != null) {
        _weatherData = data;
      } else {
        _errorMessage = '無法取得天氣資料';
      }
    } catch (e) {
      _errorMessage = '載入天氣失敗: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
