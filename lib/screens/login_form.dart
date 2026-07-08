import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/providers.dart';
import '../utils/top_snack_bar.dart';
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
  final _passwordFocusNode = FocusNode();

  String _versionStr = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthProvider auth) async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty) {
      showTopSnackBar(
        context,
        AppLocalizations.of(context).loginUsernamePrompt,
        type: SnackBarType.warning,
      );
      return;
    }
    final isDebug = username == 'debug' || username.toLowerCase() == 'test';

    if (!isDebug) {
      if (password.isEmpty) {
        showTopSnackBar(
          context,
          AppLocalizations.of(context).loginPasswordPrompt,
          type: SnackBarType.warning,
        );
        return;
      }
    }

    await auth.loginViaApp(username, password);

    if (auth.error != null) {
      if (mounted) {
        final errorMsg = auth.error == 'loginFailed'
            ? AppLocalizations.of(context).loginFailed
            : auth.error == 'loginNoNetwork'
            ? AppLocalizations.of(context).loginNoNetwork
            : auth.error!;
        showTopSnackBar(context, errorMsg, isError: true);
      }
    } else {
      TextInput.finishAutofillContext();
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
                  filled: true,
                ),
                obscureText: true,
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
