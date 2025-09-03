import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wellread2frontend/constants.dart';
import 'package:wellread2frontend/flask_util/login_logout.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(kPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Welcome', style: Theme.of(context).textTheme.bodyLarge!),
              SizedBox(height: kPadding * 0.5),
              Text(
                'Sign In to continue',
                style: Theme.of(context).textTheme.bodyMedium!,
              ),
              SizedBox(height: kPadding),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      kTextTabBarHeight * 0.5,
                    ),
                  ),
                ),
                // onSubmitted: (_) => FocusScope.of(context).nextFocus(), // TODO
              ),
              SizedBox(height: kPadding),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      kTextTabBarHeight * 0.5,
                    ),
                  ),
                ),
                obscureText: true,
                onSubmitted: (_) => submitLogin(
                  context,
                  _emailController.text,
                  _passwordController.text,
                ),
              ),
              SizedBox(height: kPadding * 0.5),
              SizedBox(
                width: double.infinity,
                child: Text.rich(
                  TextSpan(
                    text: 'Forgot Password?',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        print('forgot password');
                      },
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              SizedBox(height: kPadding),
              SizedBox(
                width: double.infinity,
                height: kTextTabBarHeight,
                child: ElevatedButton(
                  onPressed: () => submitLogin(
                    context,
                    _emailController.text,
                    _passwordController.text,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                  ),
                  child: Text(
                    'Login',
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: kPadding),
              SizedBox(
                width: double.infinity,
                child: Text.rich(
                  TextSpan(
                    text: 'Don\'t have an account? ',
                    children: [
                      TextSpan(
                        text: 'Sign up',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => context.go('/signup'),
                      ),
                      TextSpan(text: ' or 👇'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: kPadding * 0.5),
              SizedBox(
                width: double.infinity,
                height: kTextTabBarHeight,
                child: ElevatedButton(
                  onPressed: () =>
                      submitLogin(context, 'guest1@email.com', 'password'),
                  style: ElevatedButton.styleFrom(backgroundColor: kGreen),
                  child: Text(
                    'Continue as guest',
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void submitLogin(BuildContext context, String email, String password) async {
  login(email, password).then((r) {
    if (context.mounted) {
      r.showSnackBar(
        context,
        customMessageOnSuccess: r.isOk
            ? 'Logged in as <${r.data['user']['first_name']}>'
            : '',
      );
      if (r.isOk) context.go('/books');
    }
  });
}
