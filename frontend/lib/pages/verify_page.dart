import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wellread2frontend/constants.dart';
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
    if (!r.isOk) throw Exception(r.error);

    await storage.write(key: 'accessToken', value: r.data['access_token']);
    await storage.write(key: 'refreshToken', value: r.data['refresh_token']);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AsyncWidget<bool?>(
          future: _isVerified,
          builder: (context, isVerified) {
            Future.delayed(const Duration(seconds: 3), () {
              if (context.mounted) context.go('/books');
            });
            return Text(
              isVerified!
                  ? 'Thank you for verifying !\n( signing you in now... )'
                  : '',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                fontFamily: fontFamilyAlt,
                fontWeight: FontWeight.w600,
              ),
            );
          },
        ),
      ),
    );
  }
}
