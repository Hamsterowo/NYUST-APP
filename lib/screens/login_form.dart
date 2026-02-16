import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'dart:convert'; // for Base64

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _captchaController = TextEditingController();
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().fetchCaptcha();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
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
            if (auth.error != null)
              Container(
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  auth.error!,
                  style: TextStyle(color: colorScheme.onErrorContainer),
                ),
              ),
            TextField(
              controller: _usernameController,
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
                    height: 56, // Match TextField height
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
            SizedBox(height: 8),
            CheckboxListTile(
              title: Text("保持登入"),
              value: _rememberMe,
              onChanged: (val) => setState(() => _rememberMe = val!),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            SizedBox(height: 24),
            if (auth.isLoading)
              CircularProgressIndicator()
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    await auth.login(
                      _usernameController.text,
                      _passwordController.text,
                      _captchaController.text,
                      _rememberMe,
                    );
                  },
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('登入', style: TextStyle(fontSize: 16)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
