import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/providers.dart';
import '../utils/top_snack_bar.dart';
import '../widgets/custom_app_bar.dart';

/// 變更 SSO 密碼的頁面：現在的密碼 / 新密碼 / 確認新密碼。
/// 成功後由 [AuthProvider.changePassword] 以新密碼靜默重登 App 端點。
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _oldController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // 學校規則：僅可含 A-Z、a-z、0-9 及 @!$%&*，不得含空白。
  static final RegExp _passwordPattern = RegExp(r'^[A-Za-z0-9@!$%&*]+$');

  @override
  void dispose() {
    _oldController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final oldPw = _oldController.text;
    final newPw = _newController.text;
    final confirmPw = _confirmController.text;

    if (oldPw.isEmpty || newPw.isEmpty || confirmPw.isEmpty) {
      showTopSnackBar(
        context,
        l10n.changePasswordEmpty,
        type: SnackBarType.warning,
      );
      return;
    }
    if (newPw != confirmPw) {
      showTopSnackBar(
        context,
        l10n.changePasswordMismatch,
        type: SnackBarType.warning,
      );
      return;
    }
    if (!_passwordPattern.hasMatch(newPw)) {
      showTopSnackBar(
        context,
        l10n.changePasswordInvalidChars,
        type: SnackBarType.warning,
      );
      return;
    }

    final auth = ref.read(authProvider);
    final ok = await auth.changePassword(oldPw, newPw);
    if (!mounted) return;

    if (ok) {
      TextInput.finishAutofillContext();
      showTopSnackBar(
        context,
        l10n.changePasswordSuccess,
        type: SnackBarType.success,
      );
      Navigator.of(context).pop();
    } else {
      final err = auth.error;
      final msg = err == 'loginNoNetwork'
          ? l10n.loginNoNetwork
          : (err == null || err == 'changePasswordFailed')
          ? l10n.changePasswordFailed
          : err; // 學校回傳的實際錯誤訊息（例如舊密碼錯誤）
      showTopSnackBar(context, msg, isError: true);
    }
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    TextInputAction textInputAction = TextInputAction.next,
    VoidCallback? onSubmitted,
  }) {
    final l10n = AppLocalizations.of(context);
    return TextField(
      controller: controller,
      obscureText: obscure,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted == null ? null : (_) => onSubmitted(),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.lock_outline),
        filled: true,
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          ),
          tooltip: obscure ? l10n.loginShowPassword : l10n.loginHidePassword,
          onPressed: onToggle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: CustomAppBar(title: l10n.changePasswordTitle),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _passwordField(
                  controller: _oldController,
                  label: l10n.changePasswordOldLabel,
                  obscure: _obscureOld,
                  onToggle: () => setState(() => _obscureOld = !_obscureOld),
                ),
                const SizedBox(height: 16),
                _passwordField(
                  controller: _newController,
                  label: l10n.changePasswordNewLabel,
                  obscure: _obscureNew,
                  onToggle: () => setState(() => _obscureNew = !_obscureNew),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    l10n.changePasswordRule,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _passwordField(
                  controller: _confirmController,
                  label: l10n.changePasswordConfirmLabel,
                  obscure: _obscureConfirm,
                  onToggle: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  textInputAction: TextInputAction.done,
                  onSubmitted: _submit,
                ),
                const SizedBox(height: 20),

                // 提示：一併變更 M365 / Google Workspace，並自動重新登入。
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: colorScheme.onTertiaryContainer,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.changePasswordHint,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onTertiaryContainer,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                if (auth.isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      l10n.changePasswordButton,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
