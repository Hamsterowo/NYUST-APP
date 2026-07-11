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
    _SnackBarItem(message: message, type: resolvedType, context: context),
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
    with TickerProviderStateMixin {
  // 進退場動畫
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;
  late Animation<double> _scale;

  // 自動關閉的倒數進度條（滿 → 空）
  late AnimationController _countdown;

  static const Duration _visibleDuration = Duration(milliseconds: 2800);

  @override
  void initState() {
    super.initState();

    _currentDismissAction = () {
      if (mounted) _dismiss();
    };

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
      reverseDuration: const Duration(milliseconds: 240),
    );

    // 進場較克制：滑距短、無過衝
    _slide = Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _ctrl,
            curve: Curves.easeOutCubic,
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

    _scale = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeIn,
      ),
    );

    _countdown = AnimationController(
      vsync: this,
      duration: _visibleDuration,
      value: 1.0,
    );

    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) widget.onDismissed();
      // 進場完成後才開始倒數，計時與退場同步
      if (status == AnimationStatus.completed) _countdown.reverse();
    });

    _countdown.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) _dismiss();
    });

    _ctrl.forward();
  }

  // 手動或倒數結束時退場：停止倒數並反轉進場動畫
  void _dismiss() {
    if (!mounted) return;
    _countdown.stop();
    _ctrl.reverse();
  }

  @override
  void dispose() {
    _currentDismissAction = null;
    _ctrl.dispose();
    _countdown.dispose();
    super.dispose();
  }

  (IconData, Color) _typeStyle(ColorScheme cs) => switch (widget.type) {
    SnackBarType.error => (Icons.error_rounded, cs.error),
    SnackBarType.warning => (
      Icons.warning_amber_rounded,
      Colors.orange.shade800,
    ),
    SnackBarType.info => (Icons.info_rounded, cs.secondary),
    SnackBarType.success => (Icons.check_circle_rounded, cs.primary),
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (icon, accent) = _typeStyle(cs);
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

    const radius = 10.0;

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
                onTap: _dismiss,
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.5),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 左側彩色色條
                            Container(width: 4, color: accent),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  12,
                                  16,
                                  12,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // 彩色圖示晶片
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: accent.withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        icon,
                                        color: accent,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: Text(
                                        widget.message,
                                        style: TextStyle(
                                          color: cs.onSurface,
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
                          ],
                        ),
                      ),
                      // 底緣自動關閉倒數進度條
                      AnimatedBuilder(
                        animation: _countdown,
                        builder: (_, _) => LinearProgressIndicator(
                          value: _countdown.value,
                          minHeight: 3,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation(
                            accent.withValues(alpha: 0.55),
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
