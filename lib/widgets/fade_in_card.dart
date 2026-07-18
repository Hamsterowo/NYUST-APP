import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

/// 課程方塊的「進場淡入」包裝：以隨機的小延遲錯開，讓一整批方塊淡入時
/// 有一點自然的隨機感。[generation] 改變時會重新播放一次淡入。
class FadeInCard extends StatefulWidget {
  final Widget child;
  final int generation;
  const FadeInCard({super.key, required this.child, required this.generation});

  @override
  State<FadeInCard> createState() => _FadeInCardState();
}

class _FadeInCardState extends State<FadeInCard> {
  bool _visible = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(FadeInCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.generation != widget.generation) {
      setState(() => _visible = false);
      _schedule();
    }
  }

  void _schedule() {
    _timer?.cancel();
    // 0–200ms 的隨機延遲：一點點就好，但足以有錯落感。
    final delayMs = Random().nextInt(200);
    _timer = Timer(Duration(milliseconds: delayMs), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 隱藏（重播前的重置）要瞬間完成，只有「淡入」才用動畫時間，
    // 否則重播時會先從 1.0 縮到 0.94 再長回來（看起來像先縮小再變大）。
    final duration = _visible
        ? const Duration(milliseconds: 200)
        : Duration.zero;
    return AnimatedScale(
      scale: _visible ? 1.0 : 0.94,
      duration: duration,
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: _visible ? 1.0 : 0.0,
        duration: duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
