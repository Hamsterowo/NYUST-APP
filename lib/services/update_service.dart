import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

import '../l10n/app_localizations.dart';

/// 透過 Google Play In-App Update 檢查並提示更新。
///
/// 僅在「Android + 從 Google Play 安裝」時運作；其他平台（iOS／桌面／Web）
/// 或非 Play 安裝來源（側載、debug 版）一律靜默略過、不報錯，絕不影響主流程。
///
/// 採 **flexible** 模式：背景下載、不打斷使用者；下載完成後提示重新啟動安裝。
/// 若使用者在下載中／下載完成後關閉 app，已下載的更新會保留，於下次啟動或
/// 回到前景時由 [resumeCheck] 再次偵測並提示。
class UpdateService {
  UpdateService._();

  static bool _busy = false;

  static bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// 進入主畫面後呼叫：偵測是否有新版並提示 flexible 更新。
  static Future<void> checkForUpdate(BuildContext context) async {
    if (!_supported || _busy) return;
    _busy = true;
    try {
      final info = await InAppUpdate.checkForUpdate();

      // 先前已下載好、尚未安裝 → 直接提示重新啟動安裝。
      if (info.installStatus == InstallStatus.downloaded) {
        if (context.mounted) _promptCompleteInstall(context);
        return;
      }

      final canFlexible =
          info.updateAvailability == UpdateAvailability.updateAvailable &&
          info.flexibleUpdateAllowed;
      if (!canFlexible) return;

      // 直接啟動 flexible 更新：Play 會顯示內建的更新確認底單（即「立即更新／
      // 稍後」提示）。背景下載，此 Future 於下載完成時 resolve（下載中關閉
      // app 則交由 resumeCheck 於下次接手）。
      final result = await InAppUpdate.startFlexibleUpdate();
      if (result == AppUpdateResult.success && context.mounted) {
        _promptCompleteInstall(context);
      }
    } catch (_) {
      // 非 Play 安裝來源 / 檢查失敗 → 靜默略過。
    } finally {
      _busy = false;
    }
  }

  /// app 回到前景時呼叫：若有已下載但尚未安裝的更新，再次提示重新啟動。
  static Future<void> resumeCheck(BuildContext context) async {
    if (!_supported || _busy) return;
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.installStatus == InstallStatus.downloaded && context.mounted) {
        _promptCompleteInstall(context);
      }
    } catch (_) {
      // 靜默略過。
    }
  }

  static void _promptCompleteInstall(BuildContext context) {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..clearMaterialBanners()
      ..showMaterialBanner(
        MaterialBanner(
          leading: const Icon(Icons.system_update),
          content: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${l.updateReadyTitle}\n',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: l.updateReadyBody),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => messenger.hideCurrentMaterialBanner(),
              child: Text(l.updateLater),
            ),
            TextButton(
              onPressed: () async {
                messenger.hideCurrentMaterialBanner();
                try {
                  await InAppUpdate.completeFlexibleUpdate();
                } catch (_) {
                  // 安裝失敗 → 靜默略過，使用者可下次再試。
                }
              },
              child: Text(l.updateRestart),
            ),
          ],
        ),
      );
  }
}
