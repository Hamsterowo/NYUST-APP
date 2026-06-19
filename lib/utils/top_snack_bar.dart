import 'dart:ui';
import 'package:flutter/material.dart';

enum SnackBarType { success, error, info, warning }

class _SnackBarItem {
  final String message;
  final SnackBarType type;
  final BuildContext context;

  _SnackBarItem({
    required this.message,
    required this.type,
    required this.context,
  });
}

final List<_SnackBarItem> _snackBarQueue = [];
bool _isSnackBarShowing = false;
VoidCallback? _currentDismissAction;

void showTopSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
  SnackBarType type = SnackBarType.success,
}) {
  final resolvedType = isError ? SnackBarType.error : type;

  _snackBarQueue.add(
    _SnackBarItem(
      message: message,
      type: resolvedType,
      context: context,
    ),
  );

  // 避免佇列無限增長，若大於 2 個等待項目則丟棄最舊的
  if (_snackBarQueue.length > 2) {
    _snackBarQueue.removeRange(0, _snackBarQueue.length - 1);
  }

  if (_isSnackBarShowing && _currentDismissAction != null) {
    _currentDismissAction!();
  } else {
    _showNextSnackBar();
  }
}

void _showNextSnackBar() {
  if (_isSnackBarShowing || _snackBarQueue.isEmpty) return;

  _isSnackBarShowing = true;
  final item = _snackBarQueue.removeAt(0);

  if (!item.context.mounted) {
    _isSnackBarShowing = false;
    _showNextSnackBar();
    return;
  }

  final overlay = Overlay.of(item.context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (_) => _TopSnackBar(
      message: item.message,
      type: item.type,
      onDismissed: () {
        if (entry.mounted) entry.remove();
        _isSnackBarShowing = false;
        _currentDismissAction = null;
        Future.delayed(const Duration(milliseconds: 80), () {
          _showNextSnackBar();
        });
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

    _currentDismissAction = () {
      if (mounted) _ctrl.reverse();
    };

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      reverseDuration: const Duration(milliseconds: 250),
    );

    _slide = Tween<Offset>(begin: const Offset(0, 1.4), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _ctrl,
            curve: Curves.easeOutBack,
            reverseCurve: Curves.fastOutSlowIn,
          ),
        );

    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
        reverseCurve: Curves.easeOut,
      ),
    );

    _scale = Tween<double>(begin: 0.9, end: 1.0).animate(
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
    _currentDismissAction = null;
    _ctrl.dispose();
    super.dispose();
  }

  (IconData, Color, Color) _typeStyle(ColorScheme cs) => switch (widget.type) {
    SnackBarType.error => (
      Icons.error_rounded,
      cs.error,
      cs.onError,
    ),
    SnackBarType.warning => (
      Icons.warning_amber_rounded,
      Colors.orange.shade800,
      Colors.white,
    ),
    SnackBarType.info => (
      Icons.info_rounded,
      cs.secondary,
      cs.onSecondary,
    ),
    SnackBarType.success => (
      Icons.check_circle_rounded,
      cs.primary,
      cs.onPrimary,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (icon, bgColor, fgColor) = _typeStyle(cs);
    final mq = MediaQuery.of(context);

    final keyboardHeight = mq.viewInsets.bottom;

    // 透過 Navigator 判定當前是否在沒有 AppBar 返回按鈕的底層/首頁
    bool hasNavBar = false;
    try {
      hasNavBar = !Navigator.of(context).canPop();
    } catch (_) {}

    final navBarHeight = hasNavBar ? 80.0 : 0.0;
    final bottomOffset = keyboardHeight > 0
        ? keyboardHeight + 16
        : mq.padding.bottom + navBarHeight + 16;

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
            child: Material(
              type: MaterialType.transparency,
              child: GestureDetector(
                onTap: () {
                  if (mounted) _ctrl.reverse();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: fgColor.withValues(alpha: 0.15),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: fgColor, size: 24),
                      const SizedBox(width: 12),
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
    );
  }
}
