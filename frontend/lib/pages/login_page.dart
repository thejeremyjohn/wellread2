import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wellread2frontend/flask_util/flask_response.dart';
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
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Welcome',
                // style: TextStyle(
                //   fontFamily: 'Poppins',
                //   fontWeight: FontWeight.bold,
                //   fontSize: 26,
                //   color: Color(0xFF1C1C1C),
                // ),
              ),
              SizedBox(height: 6),
              Text(
                'Sign In to continue',
                // style: TextStyle(
                //   fontFamily: 'Poppins',
                //   fontWeight: FontWeight.normal,
                //   fontSize: 18,
                //   color: Color(0xFF1C1C1C),
                // ),
              ),
              SizedBox(height: 26),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                height: 49,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3B62FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Login',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 49,
                child: ElevatedButton(
                  onPressed: () async {
                    login('user1@email.com', 'password').then((
                      FlaskResponse r,
                    ) {
                      if (context.mounted) {
                        r.showSnackBar(
                          context,
                          customMessageOnSuccess: r.isOk
                              ? 'Logged in as <${r.data['user']['first_name']}>'
                              : '',
                        );
                        if (r.isOk) {
                          context.go('/books');
                        }
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Continue as guest',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // TODO forgot_password, signup
              // SizedBox(height: 26),
              // Center(
              //   child: Text(
              //     'Forgot Password?',
              //     textAlign: TextAlign.center,
              //     style: TextStyle(fontSize: 14, color: Color(0xFF87879D)),
              //   ),
              // ),
              // SizedBox(height: 10),
              // Center(
              //   child: Text(
              //     "Don't have an account? Sign Up",
              //     textAlign: TextAlign.center,
              //     style: TextStyle(
              //       fontFamily: 'Poppins',
              //       fontSize: 14,
              //       color: Color(0xFF87879D),
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
