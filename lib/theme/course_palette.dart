import 'package:flutter/material.dart';

/// 課表課程方塊的一組配色（背景／文字／邊框）。
class CourseColor {
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;

  const CourseColor({
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
  });
}

// 淺色模式調色盤 (16種和諧柔和的粉彩莫蘭迪配色)
const List<CourseColor> _lightPalette = [
  // 1. 藍色
  CourseColor(
    backgroundColor: Color(0xFFE0F2FE),
    textColor: Color(0xFF0369A1),
    borderColor: Color(0xFFBAE6FD),
  ),
  // 2. 綠色
  CourseColor(
    backgroundColor: Color(0xFFDCFCE7),
    textColor: Color(0xFF15803D),
    borderColor: Color(0xFFBBF7D0),
  ),
  // 3. 粉紅
  CourseColor(
    backgroundColor: Color(0xFFFCE7F3),
    textColor: Color(0xFFBE185D),
    borderColor: Color(0xFFFBCFE8),
  ),
  // 4. 黃橘
  CourseColor(
    backgroundColor: Color(0xFFFEF3C7),
    textColor: Color(0xFFB45309),
    borderColor: Color(0xFFFDE68A),
  ),
  // 5. 紫色
  CourseColor(
    backgroundColor: Color(0xFFF3E8FF),
    textColor: Color(0xFF6B21A8),
    borderColor: Color(0xFFE9D5FF),
  ),
  // 6. 青色
  CourseColor(
    backgroundColor: Color(0xFFE0F7FA),
    textColor: Color(0xFF006064),
    borderColor: Color(0xFFB2EBF2),
  ),
  // 7. 靛藍
  CourseColor(
    backgroundColor: Color(0xFFE0E7FF),
    textColor: Color(0xFF4338CA),
    borderColor: Color(0xFFC7D2FE),
  ),
  // 8. 橙色
  CourseColor(
    backgroundColor: Color(0xFFFFEED9),
    textColor: Color(0xFFC2410C),
    borderColor: Color(0xFFFFD8A8),
  ),
  // 9. 薄荷綠
  CourseColor(
    backgroundColor: Color(0xFFECFDF5),
    textColor: Color(0xFF047857),
    borderColor: Color(0xFFD1FAE5),
  ),
  // 10. 玫瑰紅
  CourseColor(
    backgroundColor: Color(0xFFFFF1F2),
    textColor: Color(0xFFBE123C),
    borderColor: Color(0xFFFFE4E6),
  ),
  // 11. 琥珀黃
  CourseColor(
    backgroundColor: Color(0xFFFEF9C3),
    textColor: Color(0xFF854D0E),
    borderColor: Color(0xFFFEF08A),
  ),
  // 12. 翠青綠
  CourseColor(
    backgroundColor: Color(0xFFCCFBF1),
    textColor: Color(0xFF0F766E),
    borderColor: Color(0xFF99F6E4),
  ),
  // 13. 珊瑚紅
  CourseColor(
    backgroundColor: Color(0xFFFFE4E6),
    textColor: Color(0xFF9F1239),
    borderColor: Color(0xFFFECDD3),
  ),
  // 14. 丁香紫
  CourseColor(
    backgroundColor: Color(0xFFFAE8FF),
    textColor: Color(0xFF86198F),
    borderColor: Color(0xFFF5D0FE),
  ),
  // 15. 石頭褐
  CourseColor(
    backgroundColor: Color(0xFFF5F5F4),
    textColor: Color(0xFF44403C),
    borderColor: Color(0xFFE7E5E4),
  ),
  // 16. 藍板岩
  CourseColor(
    backgroundColor: Color(0xFFF1F5F9),
    textColor: Color(0xFF334155),
    borderColor: Color(0xFFE2E8F0),
  ),
];

// 深色模式調色盤 (16種和諧明亮的深暗莫蘭迪配色)
const List<CourseColor> _darkPalette = [
  // 1. 藍色
  CourseColor(
    backgroundColor: Color(0xFF082F49),
    textColor: Color(0xFF38BDF8),
    borderColor: Color(0xFF0C4A6E),
  ),
  // 2. 綠色
  CourseColor(
    backgroundColor: Color(0xFF064E3B),
    textColor: Color(0xFF4ADE80),
    borderColor: Color(0xFF065F46),
  ),
  // 3. 粉紅
  CourseColor(
    backgroundColor: Color(0xFF500724),
    textColor: Color(0xFFF472B6),
    borderColor: Color(0xFF701A40),
  ),
  // 4. 黃橘
  CourseColor(
    backgroundColor: Color(0xFF451A03),
    textColor: Color(0xFFFBBF24),
    borderColor: Color(0xFF78350F),
  ),
  // 5. 紫色
  CourseColor(
    backgroundColor: Color(0xFF3B0764),
    textColor: Color(0xFFC084FC),
    borderColor: Color(0xFF581C87),
  ),
  // 6. 青色
  CourseColor(
    backgroundColor: Color(0xFF083344),
    textColor: Color(0xFF22D3EE),
    borderColor: Color(0xFF155E75),
  ),
  // 7. 靛藍
  CourseColor(
    backgroundColor: Color(0xFF1E1B4B),
    textColor: Color(0xFF818CF8),
    borderColor: Color(0xFF312E81),
  ),
  // 8. 橙色
  CourseColor(
    backgroundColor: Color(0xFF431407),
    textColor: Color(0xFFFB923C),
    borderColor: Color(0xFF7C2D12),
  ),
  // 9. 薄荷綠
  CourseColor(
    backgroundColor: Color(0xFF022C22),
    textColor: Color(0xFF34D399),
    borderColor: Color(0xFF064E3B),
  ),
  // 10. 玫瑰紅
  CourseColor(
    backgroundColor: Color(0xFF4C0519),
    textColor: Color(0xFFFDA4AF),
    borderColor: Color(0xFF881337),
  ),
  // 11. 琥珀黃
  CourseColor(
    backgroundColor: Color(0xFF3F2F00),
    textColor: Color(0xFFFDE047),
    borderColor: Color(0xFF713F12),
  ),
  // 12. 翠青綠
  CourseColor(
    backgroundColor: Color(0xFF042F2E),
    textColor: Color(0xFF2DD4BF),
    borderColor: Color(0xFF115E59),
  ),
  // 13. 珊瑚紅
  CourseColor(
    backgroundColor: Color(0xFF3B100E),
    textColor: Color(0xFFFB7185),
    borderColor: Color(0xFF6F1D1B),
  ),
  // 14. 丁香紫
  CourseColor(
    backgroundColor: Color(0xFF300B3B),
    textColor: Color(0xFFE879F9),
    borderColor: Color(0xFF4A1054),
  ),
  // 15. 石頭褐
  CourseColor(
    backgroundColor: Color(0xFF292524),
    textColor: Color(0xFFD6D3D1),
    borderColor: Color(0xFF44403C),
  ),
  // 16. 藍板岩
  CourseColor(
    backgroundColor: Color(0xFF1E293B),
    textColor: Color(0xFF94A3B8),
    borderColor: Color(0xFF334155),
  ),
];

/// 依課程序號取得循環使用的課程配色（超出 16 色時取餘數）。
CourseColor getCourseColor(BuildContext context, int index) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final palette = isDark ? _darkPalette : _lightPalette;
  if (index < 0) {
    return palette[0];
  }
  return palette[index % palette.length];
}
