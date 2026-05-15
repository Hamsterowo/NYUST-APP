import 'package:dio/dio.dart';
import '../models/weather_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 如果其他地方還要用，否則可拿掉

class WeatherService {
  final Dio _dio;

  WeatherService(this._dio);

  // 取得雲林縣 (包含斗六市) 鄉鎮天氣預報 - 路由已經移至自己架設的 Cloudflare Worker
  Future<WeatherData?> fetchWeatherForDouliu() async {
    try {
      final response = await _dio.get('/weather'); // /weather 會接在 Dio 的 BaseUrl 後面 (例如 https://api.xxx.com/api/weather)

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        
        return WeatherData(
          locationName: data['locationName'] ?? '斗六市',
          wx: data['wx'] ?? '-',
          currentTemp: data['currentTemp'] ?? '-',
          maxTemp: data['maxTemp'] ?? '-',
          minTemp: data['minTemp'] ?? '-',
          pop: data['pop'] ?? '-', 
        );
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      print('Weather Service Error: $e');
      return null;
    }
  }
}
