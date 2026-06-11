class WeatherData {
  final String locationName;
  final String wx;
  final String currentTemp;
  final String maxTemp;
  final String minTemp;
  final String pop;

  WeatherData({
    required this.locationName,
    required this.wx,
    required this.currentTemp,
    required this.maxTemp,
    required this.minTemp,
    required this.pop,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {

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
  final String timeText;
  final String temp;
  final String wx;

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
