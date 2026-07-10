import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../l10n/app_localizations.dart';

/// 二步驟驗證（TOTP）輸入畫面。
///
/// 由登入流程在偵測到帳號啟用 2FA 時 push 出來。驗證成功會以 `true` pop；
/// 驗證碼錯誤（學校作廢 session）或使用者取消則以 `false` pop，交由登入頁
/// 顯示訊息並重新取得驗證碼。
class TotpScreen extends ConsumerStatefulWidget {
  const TotpScreen({super.key});

  @override
  ConsumerState<TotpScreen> createState() => _TotpScreenState();
}

class _TotpScreenState extends ConsumerState<TotpScreen> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length != 6) return;

    final auth = ref.read(authProvider);
    final ok = await auth.submitTotp(code);
    if (!mounted) return;
    Navigator.of(context).pop(ok);
  }

  Future<void> _cancel() async {
    await ref.read(authProvider).cancelMfa();
    if (!mounted) return;
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final auth = ref.watch(authProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.totpTitle)),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Icon(
                  Icons.verified_user_outlined,
                  size: 64,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.totpPrompt,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _codeController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  style: const TextStyle(fontSize: 28, letterSpacing: 12),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  onChanged: (v) {
                    if (v.length == 6) _verify();
                  },
                  onSubmitted: (_) => _verify(),
                  decoration: InputDecoration(
                    labelText: l10n.totpCodeLabel,
                    border: const OutlineInputBorder(),
                    filled: true,
                    counterText: '',
                    hintText: '000000',
                  ),
                ),
                const SizedBox(height: 24),
                if (auth.isLoading)
                  const CircularProgressIndicator()
                else ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _verify,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        l10n.totpVerifyButton,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(onPressed: _cancel, child: Text(l10n.totpCancel)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
