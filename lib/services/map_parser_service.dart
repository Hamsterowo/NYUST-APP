import 'dart:ui';
import 'package:flutter/services.dart' show rootBundle;
import 'package:html/parser.dart' show parseFragment;
import 'package:html/dom.dart' as dom;
import 'package:path_drawing/path_drawing.dart';

class SvgPathData {
  final String id;
  final Path path;
  final Color? fillColor;
  final Color? strokeColor;
  final double strokeWidth;
  final bool isBuilding;

  SvgPathData({
    required this.id,
    required this.path,
    this.fillColor,
    this.strokeColor,
    this.strokeWidth = 1.0,
    required this.isBuilding,
  });
}

class MapParserService {
  /// 載入並解析校園地圖的 SVG 檔案
  static Future<List<SvgPathData>> parseMapSvg(String assetPath) async {
    final svgString = await rootBundle.loadString(assetPath);
    final document = parseFragment(svgString);
    final List<SvgPathData> results = [];

    final pathElements = document.querySelectorAll('path');

    for (var element in pathElements) {
      final dAttr = element.attributes['d'];
      if (dAttr == null || dAttr.trim().isEmpty) continue;

      String id = _getEffectiveAttribute(element, 'id') ?? '';

      bool isBuilding = id.startsWith('building-');

      Path path;
      try {
        path = parseSvgPathData(dAttr);
      } catch (e) {
        continue;
      }

      final fillStr = _getEffectiveAttribute(element, 'fill');
      final strokeStr = _getEffectiveAttribute(element, 'stroke');

      Color? fillColor = _parseColor(fillStr);
      Color? strokeColor = _parseColor(strokeStr);

      results.add(
        SvgPathData(
          id: id,
          path: path,
          fillColor: fillColor,
          strokeColor: strokeColor,
          strokeWidth: 1.0,
          isBuilding: isBuilding,
        ),
      );
    }

    return results;
  }

  /// 向上遞迴尋找屬性（支援從 `<g>` 繼承 fill, stroke, id 等）
  static String? _getEffectiveAttribute(
    dom.Element element,
    String attributeName,
  ) {
    dom.Element? current = element;
    while (current != null) {
      final value = current.attributes[attributeName];
      if (value != null && value.isNotEmpty) {
        return value;
      }
      if (current.localName == 'svg') break;
      current = current.parent;
    }
    return null;
  }

  /// 解析 Hex 顏色字串
  static Color? _parseColor(String? colorStr) {
    if (colorStr == null) return null;
    colorStr = colorStr.trim().toLowerCase();
    if (colorStr == 'none') return null;
    if (colorStr == 'black') return const Color(0xFF000000);
    if (colorStr == 'white') return const Color(0xFFFFFFFF);
    if (colorStr.startsWith('#')) {
      final hex = colorStr.substring(1);
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      } else if (hex.length == 3) {
        final r = hex[0];
        final g = hex[1];
        final b = hex[2];
        return Color(int.parse('FF$r$r$g$g$b$b', radix: 16));
      }
    }
    return null;
  }
}
