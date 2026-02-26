import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DesktopScreen extends StatelessWidget {
  const DesktopScreen({super.key});

  Future<void> _launchUrl() async {
    final Uri url = Uri.parse('https://webapp.yuntech.edu.tw/yuntechsso/');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.desktop_windows_outlined,
                  size: 120,
                  color: Colors.teal,
                ),
                const SizedBox(height: 32),
                Text(
                  'NYUST+ 是為行動裝置設計的工具',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Text(
                  '您目前正在使用電腦版網頁\n\n'
                  '建議您直接前往「國立雲林科技大學單一入口服務網」\n'
                  '可以獲得更好的使用體驗',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    height: 1.6,
                    color: Colors.grey.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                FilledButton.icon(
                  onPressed: _launchUrl,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('前往單一入口服務網'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 20,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: _launchUrl,
                  child: const Text(
                    'https://webapp.yuntech.edu.tw/yuntechsso/',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
