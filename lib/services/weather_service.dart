import '../models/weather_model.dart';
import 'api_service.dart';

class WeatherService {
  final ApiService _apiService = ApiService();

  Future<WeatherData?> fetchWeatherForDouliu() async {
    try {
      final response = await _apiService.dio.get('/api/weather');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return WeatherData.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['error'] ?? 'Failed to load weather data from backend');
      }
    } catch (e) {
      print('Weather Service Error: $e');
      rethrow;
    }
  }
}
