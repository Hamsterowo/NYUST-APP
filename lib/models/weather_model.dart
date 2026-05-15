class WeatherData {
  final String locationName; // 地區名稱 (如：斗六市)
  final String wx; // 天氣現象 (晴、多雲)
  final String currentTemp; // 目前溫度
  final String maxTemp; // 當日最高溫
  final String minTemp; // 當日最低溫
  final String pop; // 降雨機率

  WeatherData({
    required this.locationName,
    required this.wx,
    required this.currentTemp,
    required this.maxTemp,
    required this.minTemp,
    required this.pop,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    // 這裡的解析是基於氣象署的 JSON 結構 (鄉鎮預報 F-D0047-029 或 一般預報 F-C0032-001)
    // 由於氣象署 API 層層包裝，實作時會依據傳入的 element 陣列進行抽出
    // 目前先提供基礎架構，待建立 Service 撈到實際資料後再實作完整的 mapping
    return WeatherData(
      locationName: json['locationName'] ?? '斗六市',
      wx: json['wx'] ?? '未知',
      currentTemp: json['currentTemp'] ?? '-',
      maxTemp: json['maxTemp'] ?? '-',
      minTemp: json['minTemp'] ?? '-',
      pop: json['pop'] ?? '0',
    );
  }
}

class WeatherForecast {
  final String timeText; // 預報時間 (如：下午 3:00 或 明天)
  final String temp; // 該時段溫度
  final String wx; // 天氣狀態

  WeatherForecast({
    required this.timeText,
    required this.temp,
    required this.wx,
  });

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    return WeatherForecast(
      timeText: json['timeText'] ?? '',
      temp: json['temp'] ?? '',
      wx: json['wx'] ?? '',
    );
  }
}
