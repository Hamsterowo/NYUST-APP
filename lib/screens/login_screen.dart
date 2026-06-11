import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'terms_of_service_screen.dart';
import 'login_form.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTermsAgreement();
    });
  }

  Future<void> _checkTermsAgreement() async {
    final prefs = await SharedPreferences.getInstance();
    final info = await PackageInfo.fromPlatform();
    final currentVersion = info.version;

    final String lastAcceptedVersion =
        prefs.getString('accepted_terms_version') ?? '';

    if (lastAcceptedVersion != currentVersion) {
      if (mounted) {
        final bool? agreed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const TermsOfServiceScreen(showAgreementButtons: true),
          ),
        );

        if (agreed == true) {
          await prefs.setString('accepted_terms_version', currentVersion);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '登入 NYUST+',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: const SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(children: [LoginForm(), SizedBox(height: 32)]),
        ),
      ),
    );
  }
}
