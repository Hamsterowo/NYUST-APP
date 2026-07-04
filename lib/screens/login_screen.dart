import 'package:flutter/material.dart';
import 'login_form.dart';

class LoginScreen extends StatelessWidget {
  final bool showIcon;
  const LoginScreen({super.key, this.showIcon = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              LoginForm(showIcon: showIcon),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
