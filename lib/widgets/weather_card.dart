import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../utils/top_snack_bar.dart';
import '../screens/weather_error_detail_screen.dart';
import 'shimmer_box.dart';

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

  Widget _buildSkeleton(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          children: [
            ShimmerBox(width: 48, height: 48, borderRadius: 24),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 80, height: 18),
                  SizedBox(height: 8),
                  ShimmerBox(width: 120, height: 16),
                  SizedBox(height: 6),
                  ShimmerBox(width: 60, height: 14),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ShimmerBox(width: 40, height: 14),
                SizedBox(height: 8),
                ShimmerBox(width: 40, height: 14),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, weatherProvider, child) {
        if (weatherProvider.isLoading) {
          return _buildSkeleton(context);
        }

        if (weatherProvider.errorMessage != null) {
          return Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.5),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WeatherErrorDetailScreen(
                      errorMessage: weatherProvider.errorMessage!,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '載入天氣時出現錯誤',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '點擊查看更多',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.error),
                  ],
                ),
              ),
            ),
          );
        }

        final data = weatherProvider.weatherData;
        if (data == null) {
          return const SizedBox.shrink();
        }

        return Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              showTopSnackBar(
                context,
                '資料來源：中央氣象署',
                type: SnackBarType.info,
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [

                  // 修正某些圖示方向（例如雨傘顛倒）
                  Builder(builder: (ctx) {
                    final iconData = _getWeatherIcon(data.wx);
                    final iconColor = _getWeatherColor(data.wx);
                    if (iconData == Icons.umbrella) {
                      return Transform.rotate(
                        angle: 3.141592653589793, // 180°
                        child: Icon(iconData, size: 48, color: iconColor),
                      );
                    }
                    return Icon(iconData, size: 48, color: iconColor);
                  }),
                  const SizedBox(width: 16),

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

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'H: ${data.maxTemp}°C',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'L: ${data.minTemp}°C',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
