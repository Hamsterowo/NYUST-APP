import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../providers/providers.dart';
import '../data/privacy_policy.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/privacy_policy_screen.dart';

class SplashWrapper extends ConsumerStatefulWidget {
  const SplashWrapper({super.key});

  @override
  ConsumerState<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends ConsumerState<SplashWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  bool _splashDone = false;
  bool _animationTriggered = false;
  bool? _goingToLogin;
  bool? _wasLoggedIn;
  bool _isLogout = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _splashDone = true);
        // 等著開場結束才肯出現的提示（例如英文語系提示）靠這個訊號放行。
        ref.read(splashDoneProvider.notifier).state = true;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onAuthReady(AuthProvider auth) async {
    if (_animationTriggered) return;
    _animationTriggered = true;

    final isLogout = _isLogout;
    _isLogout = false;

    if (!isLogout) {
      await _checkTermsAgreement();
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (!mounted) return;

    setState(() {
      _goingToLogin = !auth.isLoggedIn;
    });

    await Future.delayed(const Duration(milliseconds: 50));

    if (!mounted) return;

    _controller.forward();
  }

  Future<void> _checkTermsAgreement() async {
    final prefs = await SharedPreferences.getInstance();
    final lastAcceptedDate = prefs.getString('accepted_terms_date') ?? '';

    // 本地政策版本比對：未同意過、或政策版本已更新時，顯示同意閘門。
    final currentVersion = await loadPrivacyPolicyVersion();
    if (lastAcceptedDate == currentVersion || !mounted) return;

    if (lastAcceptedDate.isNotEmpty) {
      await PrivacyPolicyScreen.showUpdateAlert(context);
    }

    if (!mounted) return;

    final agreedDate = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const PrivacyPolicyScreen(showAgreementButtons: true),
      ),
    );
    if (agreedDate != null && agreedDate.isNotEmpty) {
      await prefs.setString('accepted_terms_date', agreedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (_wasLoggedIn == true && !auth.isLoggedIn) {
      _splashDone = false;
      _animationTriggered = false;
      _goingToLogin = null;
      _controller.reset();
      _isLogout = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          try {
            ref.read(navIndexProvider.notifier).state = 0;
            // 登出會把開場動畫倒帶重播，訊號也得跟著收回，否則下次進主畫面時
            // 它還停在上一輪的 true。
            ref.read(splashDoneProvider.notifier).state = false;
          } catch (_) {}
        }
      });
    }
    _wasLoggedIn = auth.isLoggedIn;

    if (auth.isInitialized && !_animationTriggered) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onAuthReady(auth);
      });
    }

    if (_goingToLogin == null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: Icon(Icons.school, size: 120, color: colorScheme.primary),
        ),
      );
    }

    // 動畫進行中先用啟動當下的快照，結束後才跟隨即時的登入狀態
    // （這樣登入成功後才會換到 HomeScreen）。
    final goingToLogin = _splashDone ? !auth.isLoggedIn : _goingToLogin!;

    // 登入頁的圖示在動畫期間隱藏、結束後出現——維持原本的視覺。
    final destination = goingToLogin
        ? LoginScreen(showIcon: _splashDone)
        : const HomeScreen();

    // 動畫前後一律回傳同樣形狀的 Stack，只有覆蓋層會消失。
    // 若像以往那樣在動畫結束時改回「直接回傳 destination」，根節點型別就會
    // 從 Stack 變成 LoginScreen，Flutter 會拆掉整棵子樹重建 —— 登入頁因此被
    // 掛載兩次，initState 也就抓了兩次驗證碼（兩次都會清 cookie，互相把對方的
    // session 洗掉，導致第一次登入失敗）。
    return Stack(
      children: [
        destination,
        if (!_splashDone)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => _buildOverlay(context, colorScheme),
          ),
      ],
    );
  }

  Widget _buildOverlay(BuildContext context, ColorScheme colorScheme) {
    final screenSize = MediaQuery.of(context).size;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final t = Curves.easeInOutCubic.transform(_controller.value);

    final bgOpacity = (1.0 - t).clamp(0.0, 1.0);

    if (_goingToLogin!) {
      const startSize = 120.0;
      const endSize = 64.0;

      final startCenterY = screenSize.height / 2;
      final endCenterY = statusBarHeight + kToolbarHeight + 24 + 32;

      final currentSize = lerpDouble(startSize, endSize, t)!;
      final currentCenterY = lerpDouble(startCenterY, endCenterY, t)!;
      final currentLeft = screenSize.width / 2 - currentSize / 2;
      final currentTop = currentCenterY - currentSize / 2;

      const iconOpacity = 1.0;

      return IgnorePointer(
        ignoring: t > 0.5,
        child: Stack(
          children: [
            if (bgOpacity > 0.01)
              Positioned.fill(
                child: Container(
                  color: colorScheme.surface.withValues(alpha: bgOpacity),
                ),
              ),
            Positioned(
              left: currentLeft,
              top: currentTop,
              child: Icon(
                Icons.school,
                size: currentSize,
                color: colorScheme.primary.withValues(alpha: iconOpacity),
              ),
            ),
          ],
        ),
      );
    } else {
      final iconOpacity = (1.0 - t).clamp(0.0, 1.0);

      return IgnorePointer(
        ignoring: t > 0.5,
        child: Stack(
          children: [
            if (bgOpacity > 0.01)
              Positioned.fill(
                child: Container(
                  color: colorScheme.surface.withValues(alpha: bgOpacity),
                ),
              ),
            if (iconOpacity > 0.01)
              Positioned(
                left: screenSize.width / 2 - 60,
                top: screenSize.height / 2 - 60,
                child: Icon(
                  Icons.school,
                  size: 120,
                  color: colorScheme.primary.withValues(alpha: iconOpacity),
                ),
              ),
          ],
        ),
      );
    }
  }
}
