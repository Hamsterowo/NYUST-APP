import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/splash_wrapper.dart';
import '../screens/grades_screen.dart';
import '../screens/graduation_screen.dart';

/// go_router 的根 Navigator key，供背景通知等 App 外部進入點導航使用。
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Stage 5：宣告式路由。
///
/// `/` 交給 SplashWrapper（維持原本的 splash 動畫，並依登入狀態顯示登入/首頁），
/// `/grades`、`/graduation` 為可深連結的整頁（通知點擊、App 內導航共用）。
/// 其餘詳情頁（課程、WebView、Bug 回報、服務條款）維持 Navigator.push，
/// 與 go_router 相容、不需逐一登記為路由。
final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashWrapper()),
    GoRoute(path: '/grades', builder: (context, state) => GradesScreen()),
    GoRoute(
      path: '/graduation',
      builder: (context, state) => GraduationContent(),
    ),
  ],
);
