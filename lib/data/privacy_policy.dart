/// 本地隱私權政策：直接讀取打包進 assets 的 `PRIVACY.zh-TW.md` / `PRIVACY.en.md`。
///
/// repo 根目錄的這兩份 Markdown 即為**唯一來源**——GitHub 頁面對外展示、
/// App 內同意閘門與政策頁皆渲染同一份內容。修改政策時：
/// 1. 中英兩份 `.md` 同步修改；
/// 2. 內容有實質變更時，將兩份 front matter 的 `version:` 更新為當天日期
///    （此為與語系無關的同意版本鍵，變更會觸發使用者重新同意）。
library;

import 'package:flutter/services.dart' show rootBundle;

/// 內容區塊類型。
enum PolicyBlockType { header, subheader, bullet, paragraph }

/// 行內文字片段（支援 `**粗體**`）。
class PolicySpan {
  final String text;
  final bool bold;

  const PolicySpan(this.text, {this.bold = false});
}

/// 單一內容區塊。
class PolicyBlock {
  final PolicyBlockType type;
  final List<PolicySpan> spans;

  const PolicyBlock(this.type, this.spans);
}

/// 一份隱私權政策。
class PrivacyPolicy {
  /// 同意版本鍵（front matter `version:`，與顯示語系無關）。
  final String version;

  /// 顯示用的最後更新日期（front matter `lastUpdated:`，依語系）。
  final String lastUpdated;

  final List<PolicyBlock> blocks;

  const PrivacyPolicy({
    required this.version,
    required this.lastUpdated,
    required this.blocks,
  });
}

String _assetFor(String languageCode) =>
    languageCode == 'en' ? 'PRIVACY.en.md' : 'PRIVACY.zh-TW.md';

/// 依語系載入並解析隱私權政策。
Future<PrivacyPolicy> loadPrivacyPolicy(String languageCode) async {
  final raw = await rootBundle.loadString(_assetFor(languageCode));
  return _parseMarkdown(raw);
}

/// 取得目前政策的同意版本鍵。
///
/// 一律讀取 zh（template）檔的 `version:`，確保同意狀態與顯示語系無關。
Future<String> loadPrivacyPolicyVersion() async {
  final raw = await rootBundle.loadString(_assetFor('zh'));
  return _parseFrontMatter(raw)['version'] ?? '';
}

// ---- Markdown 解析（僅支援政策檔用到的子集）----

Map<String, String> _parseFrontMatter(String raw) {
  final result = <String, String>{};
  final lines = raw.split('\n');
  if (lines.isEmpty || lines.first.trim() != '---') return result;
  for (var i = 1; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line == '---') break;
    final sep = line.indexOf(':');
    if (sep > 0) {
      result[line.substring(0, sep).trim()] = line.substring(sep + 1).trim();
    }
  }
  return result;
}

PrivacyPolicy _parseMarkdown(String raw) {
  final frontMatter = _parseFrontMatter(raw);
  final lines = raw.split('\n');

  // 跳過 front matter 區塊。
  var start = 0;
  if (lines.isNotEmpty && lines.first.trim() == '---') {
    for (var i = 1; i < lines.length; i++) {
      if (lines[i].trim() == '---') {
        start = i + 1;
        break;
      }
    }
  }

  final blocks = <PolicyBlock>[];
  for (var i = start; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) continue;
    if (line.startsWith('# ')) continue; // 頁面標題由 AppBar 顯示
    if (line.startsWith('## ')) {
      blocks.add(
        PolicyBlock(PolicyBlockType.header, _parseInline(line.substring(3))),
      );
    } else if (line.startsWith('### ')) {
      blocks.add(
        PolicyBlock(PolicyBlockType.subheader, _parseInline(line.substring(4))),
      );
    } else if (line.startsWith('- ')) {
      blocks.add(
        PolicyBlock(PolicyBlockType.bullet, _parseInline(line.substring(2))),
      );
    } else {
      blocks.add(PolicyBlock(PolicyBlockType.paragraph, _parseInline(line)));
    }
  }

  return PrivacyPolicy(
    version: frontMatter['version'] ?? '',
    lastUpdated: frontMatter['lastUpdated'] ?? frontMatter['version'] ?? '',
    blocks: blocks,
  );
}

/// 解析行內語法：`**粗體**`、`[文字](連結)` → 「文字（連結）」。
List<PolicySpan> _parseInline(String text) {
  // Markdown 連結攤平為「文字 (連結)」。
  final linked = text.replaceAllMapped(
    RegExp(r'\[([^\]]+)\]\(([^)]+)\)'),
    (m) => '${m[1]} (${m[2]})',
  );

  final spans = <PolicySpan>[];
  var bold = false;
  for (final part in linked.split('**')) {
    if (part.isNotEmpty) spans.add(PolicySpan(part, bold: bold));
    bold = !bold;
  }
  return spans;
}
