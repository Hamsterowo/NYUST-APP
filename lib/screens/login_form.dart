import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'totp_screen.dart';
import '../providers/providers.dart';
import '../services/mock/mock_data.dart';
import '../utils/top_snack_bar.dart';
import 'dart:convert';
import 'package:package_info_plus/package_info_plus.dart';
import '../l10n/app_localizations.dart';

class LoginForm extends ConsumerStatefulWidget {
  final bool showIcon;
  const LoginForm({super.key, this.showIcon = true});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _captchaController = TextEditingController();
  final _passwordFocusNode = FocusNode();

  String _versionStr = '';
  bool _rememberPassword = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider).fetchCaptcha();
      _loadVersion();
    });
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      setState(() {
        _versionStr = info.version;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _captchaController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthProvider auth) async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final captcha = _captchaController.text.trim();

    if (username.isEmpty) {
      showTopSnackBar(
        context,
        AppLocalizations.of(context).loginUsernamePrompt,
        type: SnackBarType.warning,
      );
      return;
    }
    final isDebug = MockData.isDemoAccount(username);

    if (!isDebug) {
      if (password.isEmpty) {
        showTopSnackBar(
          context,
          AppLocalizations.of(context).loginPasswordPrompt,
          type: SnackBarType.warning,
        );
        return;
      }
      if (captcha.isEmpty) {
        showTopSnackBar(
          context,
          AppLocalizations.of(context).loginCaptchaPrompt,
          type: SnackBarType.warning,
        );
        return;
      }
    }

    await auth.login(
      username,
      password,
      captcha,
      rememberPassword: _rememberPassword,
    );

    // 帳號啟用二步驟驗證：跳出 TOTP 輸入畫面，收集 6 碼驗證碼後完成登入。
    if (auth.mfaRequired && mounted) {
      _captchaController.clear();
      final ok = await Navigator.of(
        context,
      ).push<bool>(MaterialPageRoute(builder: (_) => const TotpScreen()));
      if (ok == true) {
        TextInput.finishAutofillContext();
        return;
      }
      // 驗證失敗或取消：session 已作廢，AuthProvider 已重取驗證碼並設好錯誤訊息。
      if (auth.error != null && mounted) {
        showTopSnackBar(context, _errorMessage(auth), isError: true);
      }
      return;
    }

    if (auth.error != null) {
      if (mounted) {
        showTopSnackBar(context, _errorMessage(auth), isError: true);
        _captchaController.clear();
      }
    } else {
      TextInput.finishAutofillContext();
    }
  }

  /// 把 [AuthProvider.error] 的錯誤代碼轉成使用者可讀的訊息。
  /// 憑證被拒(loginFailed)時優先顯示學校頁面解析出的原文(errorDetail)；
  /// 絕不顯示原始例外字串。
  String _errorMessage(AuthProvider auth) {
    final l10n = AppLocalizations.of(context);
    switch (auth.error) {
      case 'totpFailed':
        return l10n.totpFailed;
      case 'loginNoNetwork':
        return l10n.loginNoNetwork;
      case 'ssoUnavailable':
        return l10n.loginServiceUnavailable;
      case 'loginFailed':
        final detail = auth.errorDetail;
        return (detail != null && detail.isNotEmpty)
            ? detail
            : l10n.loginFailed;
      default:
        return l10n.loginFailed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: AutofillGroup(
          child: Column(
            children: [
              Opacity(
                opacity: widget.showIcon ? 1.0 : 0.0,
                child: Icon(Icons.school, size: 64, color: colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).loginHeading,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              TextField(
                controller: _usernameController,
                autofillHints: const [AutofillHints.username],
                textInputAction: TextInputAction.next,
                onSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_passwordFocusNode),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).loginUsernameLabel,
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                  filled: true,
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(auth),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).loginPasswordLabel,
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    tooltip: _obscurePassword
                        ? AppLocalizations.of(context).loginShowPassword
                        : AppLocalizations.of(context).loginHidePassword,
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  filled: true,
                ),
                obscureText: _obscurePassword,
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _captchaController,
                      textCapitalization: TextCapitalization.characters,
                      onChanged: (value) {
                        if (value != value.toUpperCase()) {
                          _captchaController.value = _captchaController.value
                              .copyWith(
                                text: value.toUpperCase(),
                                selection: TextSelection.collapsed(
                                  offset: value.length,
                                ),
                              );
                        }
                      },
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(
                          context,
                        ).loginCaptchaLabel,
                        border: OutlineInputBorder(),
                        filled: true,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  if (auth.captchaUrl != null)
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        border: Border.all(color: colorScheme.outline),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Image.memory(
                        base64Decode(auth.captchaUrl!.split(',').last),
                        fit: BoxFit.contain,
                      ),
                    ),
                  IconButton(
                    icon: Icon(Icons.refresh),
                    onPressed: () => auth.fetchCaptcha(),
                    tooltip: AppLocalizations.of(
                      context,
                    ).loginCaptchaRefreshTooltip,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _rememberPassword,
                onChanged: (v) =>
                    setState(() => _rememberPassword = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(AppLocalizations.of(context).loginRememberPassword),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).loginRememberPasswordHint,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${AppLocalizations.of(context).loginRememberPasswordScope}'
                      '${AppLocalizations.of(context).infoYunReportTitle}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context).loginRememberPasswordWarning,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (auth.isLoading)
                const CircularProgressIndicator()
              else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => _submit(auth),
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      AppLocalizations.of(context).loginButton,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              if (_versionStr.isNotEmpty)
                Text(
                  'v$_versionStr',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
