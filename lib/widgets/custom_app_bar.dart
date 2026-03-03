import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Future<void> Function()? onRefresh;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    required this.title,
    this.onRefresh,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 頂部的一橫線 (視覺裝飾)
        Container(
          height: 4.0, // 橫線粗細
          width: double.infinity,
          color: Theme.of(context).primaryColor, // 根據主題色顯示橫線
        ),
        AppBar(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0, // 移除陰影讓視覺更延伸到上方橫線
          scrolledUnderElevation: 0, // 關閉 M3 往下捲動時的背景變色
          backgroundColor: Theme.of(context).scaffoldBackgroundColor, // 強制使用背景色
          surfaceTintColor: Colors.transparent, // 徹底關閉 Material3 表面染色
          actions: [
            if (actions != null) ...actions!,
            if (onRefresh != null)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: onRefresh,
                tooltip: '重新整理',
              ),
          ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize {
    // Scaffold 預期的 AppBar 高度 + 上方橫線高度
    return const Size.fromHeight(kToolbarHeight + 4.0);
  }
}
