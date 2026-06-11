import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/top_snack_bar.dart';
import 'dart:convert';
import 'yuntech_privacy_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _captchaController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  final bool _rememberMe = true;

  bool _hasReadPrivacy = false;
  bool _isCheckedPrivacy = false;
  String _versionStr = '';

  void _showMustReadSnackBar() {
    showTopSnackBar(context, '請先點選閱讀條款內容後，再進行勾選。', type: SnackBarType.warning);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().fetchCaptcha();
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
      showTopSnackBar(context, '請輸入學號', type: SnackBarType.warning);
      return;
    }
    final isDebug = username == 'debug' || username.toLowerCase() == 'test';

    if (!isDebug) {
      if (password.isEmpty) {
        showTopSnackBar(context, '請輸入密碼', type: SnackBarType.warning);
        return;
      }
      if (captcha.isEmpty) {
        showTopSnackBar(context, '請輸入驗證碼', type: SnackBarType.warning);
        return;
      }
    }

    await auth.login(username, password, captcha, _rememberMe);

    if (auth.error != null) {
      if (mounted) {
        showTopSnackBar(context, auth.error!, isError: true);
      }
    } else {

      TextInput.finishAutofillContext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final bool canLogin = _isCheckedPrivacy;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: AutofillGroup(
          child: Column(
            children: [
              Icon(Icons.school, size: 64, color: colorScheme.primary),
              SizedBox(height: 16),
              Text(
                '登入雲科單一入口服務網',
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
                  labelText: '學號',
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
                  labelText: '密碼',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                  filled: true,
                ),
                obscureText: true,
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
                        labelText: '驗證碼',
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
                        border: Border.all(color: Colors.grey),
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
                    tooltip: '重新整理驗證碼',
                  ),
                ],
              ),
              SizedBox(height: 16),

              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: _isCheckedPrivacy,
                      onChanged: (val) {
                        if (!_hasReadPrivacy) {
                          _showMustReadSnackBar();
                          return;
                        }
                        setState(() {
                          _isCheckedPrivacy = val ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const YuntechPrivacyScreen(
                                showAgreementButtons: true,
                              ),
                            ),
                          ).then((agreed) {
                            if (agreed == true) {
                              setState(() {
                                _hasReadPrivacy = true;
                                _isCheckedPrivacy = true;
                              });
                            }
                          });
                        },
                        child: Text(
                          '我已閱讀並同意「YunTech 單一入口隱私權政策」',
                          style: textTheme.bodyMedium?.copyWith(
                            color: _hasReadPrivacy
                                ? colorScheme.onSurface
                                : colorScheme.primary,
                            decoration: _hasReadPrivacy
                                ? null
                                : TextDecoration.underline,
                            fontWeight: _hasReadPrivacy
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.arrow_forward_ios,
                        color: colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const YuntechPrivacyScreen(
                              showAgreementButtons: true,
                            ),
                          ),
                        ).then((agreed) {
                          if (agreed == true) {
                            setState(() {
                              _hasReadPrivacy = true;
                              _isCheckedPrivacy = true;
                            });
                          }
                        });
                      },
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
                    onPressed: canLogin ? () => _submit(auth) : null,
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('登入', style: TextStyle(fontSize: 16)),
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
