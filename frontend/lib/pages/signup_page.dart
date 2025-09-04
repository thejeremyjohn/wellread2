import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wellread2frontend/constants.dart';
import 'package:wellread2frontend/flask_util/flask_methods.dart';
import 'package:wellread2frontend/flask_util/flask_response.dart';
import 'package:wellread2frontend/flask_util/login_logout.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignupResponseOk = false;

  // @override
  // void initState() {
  //   _firstNameController.text = 'jeremy';
  //   _lastNameController.text = 'john';
  //   _emailController.text = 'thejeremyjohn@gmail.com';
  //   _passwordController.text = 'password';
  //   super.initState();
  // }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> submitSignup(
    BuildContext context,
    String firstName,
    String lastName,
    String email,
    String password,
  ) async {
    final endpoint = flaskUri('/signup');
    final body = {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'password': password,
    };
    FlaskResponse r = await flaskPost(endpoint, body: body);
    setState(() => _isSignupResponseOk = r.isOk);

    if (context.mounted) {
      r.showSnackBar(
        context,
        customMessageOnSuccess: r.isOk ? 'Signup successful!' : '',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Builder(
          builder: (context) {
            if (!_isSignupResponseOk) {
              // signup form
              return Padding(
                padding: const EdgeInsets.all(kPadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Well met, newcomer!',
                      style: Theme.of(context).textTheme.bodyLarge!,
                    ),
                    SizedBox(height: kPadding * 0.5),
                    Text(
                      'Create an account why don\'t ye?',
                      style: Theme.of(context).textTheme.bodyMedium!,
                    ),
                    SizedBox(height: kPadding),
                    TextField(
                      controller: _firstNameController,
                      decoration: InputDecoration(
                        labelText: 'First Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            kTextTabBarHeight * 0.5,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: kPadding),
                    TextField(
                      controller: _lastNameController,
                      decoration: InputDecoration(
                        labelText: 'Last Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            kTextTabBarHeight * 0.5,
                          ),
                        ),
                      ),
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
                      onSubmitted: (_) => submitSignup(
                        context,
                        _firstNameController.text,
                        _lastNameController.text,
                        _emailController.text,
                        _passwordController.text,
                      ),
                    ),
                    SizedBox(height: kPadding),
                    SizedBox(
                      width: double.infinity,
                      height: kTextTabBarHeight,
                      child: ElevatedButton(
                        onPressed: () => submitSignup(
                          context,
                          _firstNameController.text,
                          _lastNameController.text,
                          _emailController.text,
                          _passwordController.text,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade800,
                        ),
                        child: Text(
                          'Sign up!',
                          style: Theme.of(context).textTheme.bodyLarge!
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    SizedBox(height: kPadding),
                    SizedBox(
                      width: double.infinity,
                      child: Text.rich(
                        TextSpan(
                          text: 'Already have an account? ',
                          children: [
                            TextSpan(
                              text: 'Sign in',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => context.go('/login'),
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
                        onPressed: () => submitLogin(
                          context,
                          'guest1@email.com',
                          'password',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kGreen,
                        ),
                        child: Text(
                          'Continue as guest',
                          style: Theme.of(context).textTheme.bodyLarge!
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            // successful signup message and verification call to action
            return Text(
              'Thanks!\nTo finish signup, click the verification link we\'ve just emailed to you.\n( Check your spam folder if you don\'t see it right away. )',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                fontFamily: 'LibreBaskerville',
                fontWeight: FontWeight.w600,
              ),
            );
          },
        ),
      ),
    );
  }
}
