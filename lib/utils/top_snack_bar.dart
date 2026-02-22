import 'dart:ui';
import 'package:flutter/material.dart';

enum SnackBarType { success, error, info, warning }

void showTopSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
  SnackBarType type = SnackBarType.success,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  final resolvedType = isError ? SnackBarType.error : type;

  entry = OverlayEntry(
    builder: (_) => _TopSnackBar(
      message: message,
      type: resolvedType,
      onDismissed: () {
        if (entry.mounted) entry.remove();
      },
    ),
  );

  overlay.insert(entry);
}

class _TopSnackBar extends StatefulWidget {
  final String message;
  final SnackBarType type;
  final VoidCallback onDismissed;

  const _TopSnackBar({
    required this.message,
    required this.type,
    required this.onDismissed,
  });

  @override
  State<_TopSnackBar> createState() => _TopSnackBarState();
}

class _TopSnackBarState extends State<_TopSnackBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
      reverseDuration: const Duration(milliseconds: 320),
    );

    // 進場：從底部彈跳滑入
    _slide = Tween<Offset>(begin: const Offset(0, 1.4), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _ctrl,
            curve: Curves.easeOutBack,
            reverseCurve: Curves.easeInCubic,
          ),
        );

    // 進場：淡入；退場：淡出
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
        reverseCurve: Curves.easeOut,
      ),
    );

    // 輕微縮放，讓彈跳感更立體
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
        reverseCurve: Curves.easeIn,
      ),
    );

    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) widget.onDismissed();
    });

    _ctrl.forward();

    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) _ctrl.reverse();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  (IconData, Color, Color) _typeStyle(ColorScheme cs) => switch (widget.type) {
    SnackBarType.error => (
      Icons.error_rounded,
      cs.errorContainer,
      cs.onErrorContainer,
    ),
    SnackBarType.warning => (
      Icons.warning_amber_rounded,
      const Color(0xFFFFF3CD),
      const Color(0xFF856404),
    ),
    SnackBarType.info => (
      Icons.info_rounded,
      cs.secondaryContainer,
      cs.onSecondaryContainer,
    ),
    SnackBarType.success => (
      Icons.check_circle_rounded,
      cs.primaryContainer,
      cs.onPrimaryContainer,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (icon, bgColor, fgColor) = _typeStyle(cs);
    final mq = MediaQuery.of(context);
    // 鍵盤高度（開啟時 > 0）
    final keyboardHeight = mq.viewInsets.bottom;
    // NavigationBar 高度：Material 3 預設 80，加上底部 safe area
    const navBarHeight = 80.0;
    final bottomOffset = keyboardHeight > 0
        ? keyboardHeight +
              12 // 鍵盤上方
        : mq.padding.bottom + navBarHeight + 12; // 導覽列上方

    return Positioned(
      bottom: bottomOffset,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: GestureDetector(
              onTap: () {
                if (mounted) _ctrl.reverse();
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: bgColor.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(16),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 20,
                          spreadRadius: 0,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: fgColor, size: 22),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            widget.message,
                            style: TextStyle(
                              color: fgColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
