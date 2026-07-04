import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../providers/navigation_provider.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/terms_of_service_screen.dart';

class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper>
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
      await _checkTermsAgreement(auth);
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

  Future<void> _checkTermsAgreement(AuthProvider auth) async {
    final lang = Localizations.localeOf(context).languageCode;
    final prefs = await SharedPreferences.getInstance();
    final lastAcceptedDate = prefs.getString('accepted_terms_date') ?? '';

    Map<String, dynamic>? initialTerms;
    bool shouldShow = false;

    if (lastAcceptedDate.isEmpty) {
      shouldShow = true;
    } else {
      try {
        final terms = await auth.api
            .getTermsOfService(lang: lang)
            .timeout(const Duration(seconds: 3));
        if (terms['status'] == 'success') {
          final lastUpdated = terms['data']?['lastUpdated'] ?? '';
          if (lastUpdated != lastAcceptedDate) {
            shouldShow = true;
            initialTerms = terms;
          }
        }
      } catch (_) {
        shouldShow = false;
      }
    }

    if (shouldShow && mounted) {
      if (lastAcceptedDate.isNotEmpty) {
        await TermsOfServiceScreen.showUpdateAlert(context);
      }

      if (!mounted) return;

      final agreedDate = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => TermsOfServiceScreen(
            showAgreementButtons: true,
            initialTerms: initialTerms,
          ),
        ),
      );
      if (agreedDate != null && agreedDate.isNotEmpty) {
        await prefs.setString('accepted_terms_date', agreedDate);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
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
            context.read<NavigationProvider>().setIndex(0);
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
