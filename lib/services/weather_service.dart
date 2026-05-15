import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/weather_model.dart';

class WeatherService {
  final Dio _dio = Dio();

  // 中央氣象署 API 基底網址
  final String baseUrl = 'https://opendata.cwa.gov.tw/api';

  // 取得雲林縣 (包含斗六市) 鄉鎮天氣預報
  Future<WeatherData?> fetchWeatherForDouliu() async {
    final apiKey = dotenv.env['CWA_API_KEY'];
    
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API Key is missing');
    }

    try {
      // 雲林縣未來 2 天天氣預報 (F-D0047-025)
      final response = await _dio.get(
        '$baseUrl/v1/rest/datastore/F-D0047-025',
        queryParameters: {
          'Authorization': apiKey,
          'LocationName': '斗六市',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        // 氣象署開放資料 API 結構較深，我們逐層訪問出 斗六市 的天氣元素列表
        final locations = data['records']['Locations'][0]['Location'];
        final douliuData = locations.firstWhere((loc) => loc['LocationName'] == '斗六市');
        final weatherElements = douliuData['WeatherElement'] as List<dynamic>;

        // 建立一個小工具函數幫助我們抽出特定的 ElementName 的數值
        String getValue(String elementName, String valueKey) {
          try {
            final element = weatherElements.firstWhere((e) => e['ElementName'] == elementName);
            return element['Time'][0]['ElementValue'][0][valueKey].toString();
          } catch (_) {
            return '-';
          }
        }

        // 解析並組合我們的 Data Model
        return WeatherData(
          locationName: '斗六市',
          wx: getValue('天氣現象', 'Weather'),
          currentTemp: getValue('溫度', 'Temperature'),
          maxTemp: getValue('體感溫度', 'ApparentTemperature'), // 未來2天 API 沒有當日單純的 MaxT，暫時用體感最高示意或後續改用其他 API
          minTemp: getValue('露點溫度', 'DewPoint'),        // 同上
          pop: getValue('3小時降雨機率', 'ProbabilityOfPrecipitation'), 
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
