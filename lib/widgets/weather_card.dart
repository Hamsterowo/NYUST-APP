import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';

class WeatherCard extends StatelessWidget {
  const WeatherCard({super.key});

  IconData _getWeatherIcon(String wx) {
    if (wx.contains('晴')) {
      return Icons.wb_sunny;
    } else if (wx.contains('雨')) {
      return Icons.umbrella;
    } else if (wx.contains('雲') || wx.contains('陰')) {
      return Icons.cloud;
    } else {
      return Icons.wb_cloudy_outlined;
    }
  }

  Color _getWeatherColor(String wx) {
    if (wx.contains('晴')) {
      return Colors.orange;
    } else if (wx.contains('雨')) {
      return Colors.blueAccent;
    } else {
      return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, weatherProvider, child) {
        if (weatherProvider.isLoading) {
          return const Card(
            elevation: 0,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (weatherProvider.errorMessage != null) {
          return Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  weatherProvider.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          );
        }

        final data = weatherProvider.weatherData;
        if (data == null) {
          return const SizedBox.shrink(); // 初始狀態
        }

        return Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // 天氣圖示
                Icon(
                  _getWeatherIcon(data.wx),
                  size: 48,
                  color: _getWeatherColor(data.wx),
                ),
                const SizedBox(width: 16),
                
                // 天氣與溫度資訊
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.locationName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${data.currentTemp}°C • ${data.wx}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '降雨機率 ${data.pop}%',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      )
                    ],
                  ),
                ),

                // 最高 / 最低溫
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'H: ${data.maxTemp}°C', // 此處以體感最高溫代替
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'L: ${data.minTemp}°C', // 此處以露點溫度代替
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
