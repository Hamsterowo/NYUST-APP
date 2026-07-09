import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:yun_tool/data/privacy_policy.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 讓 rootBundle 直接從磁碟讀 repo 根目錄的 md 檔。
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
          final key = const StringCodec().decodeMessage(message) as String;
          final bytes = await File(key).readAsBytes();
          return ByteData.view(bytes.buffer);
        });
  });

  test('zh policy parses with version and blocks', () async {
    final policy = await loadPrivacyPolicy('zh');
    expect(policy.version, '2026-07-09');
    expect(policy.lastUpdated, '2026年07月09日');
    // 10 個 ## 章節標題
    expect(
      policy.blocks.where((b) => b.type == PolicyBlockType.header).length,
      10,
    );
    // 5 個 ### 子標題（一~五）
    expect(
      policy.blocks.where((b) => b.type == PolicyBlockType.subheader).length,
      5,
    );
    // 4 個 bullet
    expect(
      policy.blocks.where((b) => b.type == PolicyBlockType.bullet).length,
      4,
    );
    // 有粗體 span
    expect(policy.blocks.any((b) => b.spans.any((s) => s.bold)), isTrue);
    // 連結解析為帶 url 的片段（文字與網址分離）
    final linkSpans = policy.blocks
        .expand((b) => b.spans)
        .where((s) => s.url != null)
        .toList();
    expect(linkSpans, isNotEmpty);
    expect(
      linkSpans.any(
        (s) =>
            s.text == 'GitHub Issues' &&
            s.url!.startsWith('https://github.com/Hamsterowo'),
      ),
      isTrue,
    );
    // 純文字片段不應殘留 markdown 連結語法
    final flat = policy.blocks.expand((b) => b.spans).map((s) => s.text).join();
    expect(flat, isNot(contains('](')));
  });

  test('en policy parses and version matches zh', () async {
    final policy = await loadPrivacyPolicy('en');
    expect(policy.version, '2026-07-09');
    expect(policy.lastUpdated, 'July 9, 2026');
    expect(
      policy.blocks.where((b) => b.type == PolicyBlockType.header).length,
      10,
    );
    expect(await loadPrivacyPolicyVersion(), policy.version);
  });
}
