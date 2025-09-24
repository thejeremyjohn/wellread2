import 'package:flutter/material.dart';
import 'package:wellread2frontend/constants.dart';

class AuthorPage extends StatelessWidget {
  const AuthorPage({super.key, this.name});
  final String? name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 1, child: Container()), // page side spacer
            Expanded(
              flex: 1,
              child: Container(
                margin: EdgeInsets.all(kPadding),
                child: Column(
                  spacing: kPadding,
                  children: <Widget>[
                    Image.asset('images/no-author.png'),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'You have clicked the Follow button! Congratulations!',
                              ),
                              backgroundColor: kGreen,
                            ),
                          );
                        },
                        child: Text('Follow'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Container(
                margin: EdgeInsets.all(kPadding),
                child: ListView(
                  children: [
                    Text(
                      name ?? '[Author Name]',
                      style: Theme.of(context).textTheme.headlineSmall!
                          .copyWith(
                            fontFamily: fontFamilyAlt,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Divider(height: kPadding),
                    Text('He/She/They sure had a way with words.'),
                    SizedBox(height: kPadding),
                    SizedBox(height: kPadding),
                    SizedBox(height: kPadding),
                    SizedBox(height: kPadding),
                    Row(
                      spacing: kPadding,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(Icons.question_mark),
                        Icon(Icons.hardware),
                        Text('under construction'),
                        Icon(Icons.hardware),
                        Icon(Icons.question_mark),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(flex: 1, child: Container()), // page side spacer
          ],
        ),
      ),
    );
  }
}
