import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/top_snack_bar.dart';
import 'dart:convert';
import 'package:package_info_plus/package_info_plus.dart';
import '../l10n/app_localizations.dart';

class LoginForm extends StatefulWidget {
  final bool showIcon;
  const LoginForm({super.key, this.showIcon = true});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _captchaController = TextEditingController();
  final _passwordFocusNode = FocusNode();

  String _versionStr = '';

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
      showTopSnackBar(context, AppLocalizations.of(context).loginUsernamePrompt, type: SnackBarType.warning);
      return;
    }
    final isDebug = username == 'debug' || username.toLowerCase() == 'test';

    if (!isDebug) {
      if (password.isEmpty) {
        showTopSnackBar(context, AppLocalizations.of(context).loginPasswordPrompt, type: SnackBarType.warning);
        return;
      }
      if (captcha.isEmpty) {
        showTopSnackBar(context, AppLocalizations.of(context).loginCaptchaPrompt, type: SnackBarType.warning);
        return;
      }
    }

    await auth.login(username, password, captcha);

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
                        labelText: AppLocalizations.of(context).loginCaptchaLabel,
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
                    tooltip: AppLocalizations.of(context).loginCaptchaRefreshTooltip,
                  ),
                ],
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
                    child: Text(AppLocalizations.of(context).loginButton, style: TextStyle(fontSize: 16)),
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
