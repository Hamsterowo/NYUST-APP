// Riverpod 3.x：ChangeNotifierProvider / StateProvider 已移到 legacy。
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'auth_provider.dart';
import 'data_provider.dart';
import '../services/connectivity_service.dart';

/// Stage 5：DI 由 `provider` 套件全面改吃 Riverpod。
///
/// AuthProvider / DataProvider 內部仍是 ChangeNotifier（登入狀態機不動），
/// 透過 Riverpod 的 ChangeNotifierProvider 暴露；未來可再細拆成 Notifier。

/// 全域唯一的 AuthProvider。
final authProvider = ChangeNotifierProvider<AuthProvider>((ref) {
  return AuthProvider();
});

/// 全域唯一的 DataProvider，架在 AuthProvider 之上。
///
/// 用 `ref.read`（而非 watch）取得 AuthProvider 實例：兩者都是單例、
/// 生命週期與 App 同壽，DataProvider 只需建立一次，不該因 auth 通知而重建。
final dataProvider = ChangeNotifierProvider<DataProvider>((ref) {
  final auth = ref.read(authProvider);
  return DataProvider(auth.api, auth);
});

/// 底部分頁索引（取代 NavigationProvider）。
final navIndexProvider = StateProvider<int>((ref) => 0);

/// 目前是否在線上（`true` = 有網路介面）。用於離線橫幅等 UX。
///
/// 初值先給 `true`，避免 App 一啟動、串流尚未回報前就閃現離線橫幅。
final isOnlineProvider = StreamProvider<bool>((ref) {
  return ConnectivityService.instance.onStatusChange;
});
