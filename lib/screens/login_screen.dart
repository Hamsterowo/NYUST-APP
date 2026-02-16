import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'dart:convert'; // for Base64

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _captchaController = TextEditingController();
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    // Fetch initial captcha
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isLoggedIn) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        auth.fetchCaptcha();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: Text('NYUST Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (auth.error != null)
              Text(auth.error!, style: TextStyle(color: Colors.red)),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: '學號'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: '密碼'),
              obscureText: true,
            ),
            SizedBox(height: 10),
            Row(
              children: [
                if (auth.captchaUrl != null)
                  // Assuming captchaUrl is a base64 string or data URI
                  Image.memory(
                    base64Decode(auth.captchaUrl!.split(',').last),
                    height: 50,
                  ),
                SizedBox(width: 10),
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: () => auth.fetchCaptcha(),
                ),
                Expanded(
                  child: TextField(
                    controller: _captchaController,
                    decoration: InputDecoration(labelText: '驗證碼'),
                  ),
                ),
              ],
            ),
            CheckboxListTile(
              title: Text("記住我 (7天)"),
              value: _rememberMe,
              onChanged: (val) => setState(() => _rememberMe = val!),
            ),
            SizedBox(height: 20),
            if (auth.isLoading)
              CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: () async {
                  bool success = await auth.login(
                    _usernameController.text,
                    _passwordController.text,
                    _captchaController.text,
                    _rememberMe,
                  );
                  if (success && mounted) {
                    Navigator.pushReplacementNamed(context, '/home');
                  }
                },
                child: Text('登入'),
              ),
          ],
        ),
      ),
    );
  }
}
