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
    if (lastAcceptedDate == kPrivacyPolicyVersion || !mounted) return;

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

    if (_splashDone) {
      return auth.isLoggedIn ? const HomeScreen() : LoginScreen();
    }

    if (_goingToLogin == null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: Icon(Icons.school, size: 120, color: colorScheme.primary),
        ),
      );
    }

    final destination = _goingToLogin!
        ? LoginScreen(showIcon: false)
        : const HomeScreen();

    return Stack(
      children: [
        destination,
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
