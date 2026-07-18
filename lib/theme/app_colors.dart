import 'dart:ui';

/// 全 App 共用的品牌色。
///
/// 主題 seed 與底部導覽列、NavigationRail 等處都應引用這裡，
/// 避免 Material teal 與 Tailwind teal 兩種色相並存。
abstract final class AppColors {
  /// 品牌 teal（Tailwind teal-500）。
  static const Color brandTeal = Color(0xFF14B8A6);
}
