import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wellread2frontend/flask_util/flask_methods.dart';
import 'package:wellread2frontend/widgets/async_widget.dart';

class VerifyPage extends StatefulWidget {
  const VerifyPage({super.key, required this.token});
  final String? token;

  @override
  State<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends State<VerifyPage> {
  late Future<bool?> _isVerified;

  @override
  void initState() {
    _isVerified = verify();
    super.initState();
  }

  Future<bool?> verify() async {
    final r = await flaskPost(flaskUri('/verify/${widget.token}'));
    if (r.isOk) return true;
    throw Exception(r.error);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AsyncWidget(
          future: _isVerified,
          builder: (context, isVerified) {
            Future.delayed(const Duration(seconds: 3), () {
              if (context.mounted) context.go('/login');
            });
            return Text(
              isVerified
                  ? 'Thank you for verifying !\n... redirecting to login page ...'
                  : '',
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
