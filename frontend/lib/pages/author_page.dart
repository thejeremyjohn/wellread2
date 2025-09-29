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
                                style: TextStyle(color: Colors.white),
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
                    Text(
                      'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Integer dolor leo, luctus et felis cursus, gravida mollis nisi. Morbi ut sagittis odio, sit amet dapibus ante. Ut iaculis nibh id turpis eleifend tempor. Nullam diam libero, aliquet suscipit pharetra suscipit, pulvinar vitae enim. Pellentesque id bibendum velit. Morbi orci velit, efficitur sed scelerisque quis, pulvinar eu nunc. Quisque at dui tellus. Sed diam odio, viverra non elit eget, faucibus cursus risus. Ut laoreet eros ex, sed eleifend neque gravida eu. Praesent a rhoncus nisi. Pellentesque ut mauris ipsum. Quisque blandit mauris in tortor condimentum vulputate. Donec auctor turpis pharetra orci semper cursus.',
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
