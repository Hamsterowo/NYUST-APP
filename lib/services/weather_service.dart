import 'package:dio/dio.dart';
import '../models/weather_model.dart';
import 'api_service.dart';

class WeatherService {
  final Dio _dio = Dio();
  final ApiService _apiService = ApiService();

  // 將天氣資料獲取轉交給後端 API 處理
  Future<WeatherData?> fetchWeatherForDouliu() async {
    try {
      final response = await _dio.get(
        '${_apiService.baseUrl}/api/weather',
        options: Options(
          headers: {
            'X-Nyust-App-Secret': 'lrR2Uf-E6No13m45iCa7', // 這裡應與 ApiService 中的金鑰一致
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return WeatherData.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['error'] ?? 'Failed to load weather data from backend');
      }
    } catch (e) {
      print('Weather Service Error: $e');
      rethrow; // 拋出錯誤讓 Provider 捕捉並顯示
    }
  }
}
