import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wellread2frontend/constants.dart';
import 'package:wellread2frontend/flask_util/flask_methods.dart';

class ForgotPwPage extends StatefulWidget {
  const ForgotPwPage({super.key, required this.email, required this.token});
  final String? email;
  final String? token;

  @override
  State<ForgotPwPage> createState() => _ForgotPwPageState();
}

class _ForgotPwPageState extends State<ForgotPwPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isObscureText = true;
  bool _isForgotPasswordResponseOk = false;
  bool _isVerifyResponseOk = false;
  bool _isUserUpdateResponseOk = false;

  @override
  void initState() {
    _emailController.text = widget.email ?? '';
    if (widget.token != null) verify();
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> forgotPassword(BuildContext context) async {
    Map body = {'email': _emailController.text};
    final r = await flaskPost(flaskUri('/forgot_password'), body: body);
    setState(() => _isForgotPasswordResponseOk = r.isOk);
    if (context.mounted) {
      r.showSnackBar(
        context,
        customMessageOnSuccess: r.isOk
            ? 'reset-password email sent to ${_emailController.text}'
            : '',
      );
    }
  }

  Future<void> verify() async {
    final r = await flaskPost(flaskUri('/verify/${widget.token}'));
    if (r.isOk) {
      setState(() => _isVerifyResponseOk = true);
      await storage.write(key: 'accessToken', value: r.data['access_token']);
      await storage.write(key: 'refreshToken', value: r.data['refresh_token']);
    }
    BuildContext? context = kRootNavKey.currentContext;
    if (context != null && context.mounted) {
      r.showSnackBar(context);
      if (r.isOk) return;
      context.go('/login');
    }
  }

  Future<void> setPassword(BuildContext context) async {
    Map body = {'password': _passwordController.text};
    final r = await flaskPut(flaskUri('/user'), body: body);
    setState(() => _isUserUpdateResponseOk = r.isOk);
    if (context.mounted) {
      r.showSnackBar(
        context,
        customMessageOnSuccess: r.isOk ? 'Password changed!' : '',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Builder(
          builder: (context) {
            if (widget.email != null) {
              if (!_isForgotPasswordResponseOk) {
                // forgot_password form
                return Padding(
                  padding: const EdgeInsets.all(kPadding),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'It\'s not so bad...',
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
                        onSubmitted: (_) => forgotPassword(context),
                      ),
                      SizedBox(height: kPadding),
                      SizedBox(
                        width: double.infinity,
                        height: kTextTabBarHeight,
                        child: ElevatedButton(
                          onPressed: () => forgotPassword(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kGreen,
                          ),
                          child: Text(
                            'Send me a reset-password link',
                            style: Theme.of(context).textTheme.bodyLarge!
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // successful forgot_password message and verification call to action
              return Text(
                'We\'ve emailed you a reset-password link.\n( Check your spam folder if you don\'t see it right away. )',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  fontFamily: 'LibreBaskerville',
                  fontWeight: FontWeight.w600,
                ),
              );
            }

            if (widget.token != null && _isVerifyResponseOk) {
              if (!_isUserUpdateResponseOk) {
                // verified -> reset-password form
                return Padding(
                  padding: const EdgeInsets.all(kPadding),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'What\'s your new password going to be?',
                        style: Theme.of(context).textTheme.bodyMedium!,
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
                          suffixIcon: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: kPadding * 0.5,
                            ),
                            child: IconButton(
                              icon: Icon(
                                _isObscureText
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () {
                                setState(
                                  () => _isObscureText = !_isObscureText,
                                );
                              },
                            ),
                          ),
                        ),
                        obscureText: _isObscureText,
                        onSubmitted: (_) => setPassword(context),
                      ),
                      SizedBox(height: kPadding),
                      SizedBox(
                        width: double.infinity,
                        height: kTextTabBarHeight,
                        child: ElevatedButton(
                          onPressed: () => setPassword(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kGreen,
                          ),
                          child: Text(
                            'Set password',
                            style: Theme.of(context).textTheme.bodyLarge!
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
            }

            // verified and password changed -> invite to goto /books
            return Text.rich(
              TextSpan(
                text: 'Ok! You\'re signed in by the way. 👉 ',
                children: [
                  TextSpan(
                    text: '/books',
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                      fontFamily: 'LibreBaskerville',
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => context.go('/books'),
                  ),
                ],
              ),
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                fontFamily: 'LibreBaskerville',
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            );
          },
        ),
      ),
    );
  }
}
