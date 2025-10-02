import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wellread2frontend/constants.dart';
import 'package:wellread2frontend/flask_util/flask_methods.dart';
import 'package:wellread2frontend/flask_util/flask_response.dart';
import 'package:wellread2frontend/models/user.dart';
import 'package:wellread2frontend/providers/user_state.dart';
import 'package:wellread2frontend/widgets/async_widget.dart';
import 'package:wellread2frontend/widgets/password_field.dart';
import 'package:wellread2frontend/widgets/spacer_body.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.userId});
  final String userId;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<User> _futureUser;
  bool _isMe = false;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    _futureUser = userGet();
    super.initState();
  }

  Future<User> userGet() async {
    User me = context.read<UserState>().user;
    if (me.id.toString() == widget.userId) {
      _isMe = true;
      _firstNameController.text = me.firstName;
      _lastNameController.text = me.lastName;
      return me;
    }

    Uri endpoint = flaskUri('/users', queryParameters: {'id': widget.userId});
    final r = await flaskGet(endpoint);
    if (!r.isOk) throw Exception(r.error);

    return (r.data['users'] as List)
        .map((shelf) => User.fromJson(shelf as Map<String, dynamic>))
        .first;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _oldPasswordController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<FlaskResponse> userUpdate(Map<String, String> body) async {
    final r = await flaskPut(flaskUri('/user'), body: body);
    return r;
  }

  @override
  Widget build(BuildContext context) {
    return SpacerBody(
      child: AsyncWidget<User>(
        future: _futureUser,
        builder: (context, user) {
          // profile edit form
          if (_isMe) {
            return Column(
              spacing: kPadding,
              children: [
                Text(
                  'Change your name? Update your password?',
                  style: Theme.of(context).textTheme.bodyMedium!,
                ),
                FieldWithInlineSubmit(
                  controller: _firstNameController,
                  labelText: 'First Name',
                  onPressed: () {
                    userUpdate({'first_name': _firstNameController.text}).then((
                      r,
                    ) {
                      if (context.mounted) {
                        r.showSnackBar(
                          context,
                          customMessageOnSuccess: !r.isOk
                              ? ''
                              : 'updated firstName',
                        );
                        if (r.isOk) {
                          context.read<UserState>().setUserFromJson(
                            r.data['user'],
                          );
                        }
                      }
                    });
                  },
                ),
                FieldWithInlineSubmit(
                  controller: _lastNameController,
                  labelText: 'Last Name',
                  onPressed: () {
                    userUpdate({'last_name': _lastNameController.text}).then((
                      r,
                    ) {
                      if (context.mounted) {
                        r.showSnackBar(
                          context,
                          customMessageOnSuccess: !r.isOk
                              ? ''
                              : 'updated lastName',
                        );
                        if (r.isOk) {
                          context.read<UserState>().setUserFromJson(
                            r.data['user'],
                          );
                        }
                      }
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: kPadding * 0.5,
                  children: [
                    Expanded(
                      flex: 5,
                      child: PasswordField(
                        labelText: 'Old Password',
                        controller: _oldPasswordController,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(kTextTabBarHeight * 0.5),
                          bottomLeft: Radius.circular(kTextTabBarHeight * 0.5),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 7,
                      child: FieldWithInlineSubmit(
                        flexes: (5, 2),
                        controller: _passwordController,
                        labelText: 'New Password',
                        fieldBorderRadius: BorderRadius.zero,
                        onPressed: () {
                          userUpdate({
                            'old_password': _oldPasswordController.text,
                            'password': _passwordController.text,
                          }).then((r) {
                            if (context.mounted) {
                              r.showSnackBar(
                                context,
                                customMessageOnSuccess: !r.isOk
                                    ? ''
                                    : 'updated password',
                              );
                              if (r.isOk) {
                                context.read<UserState>().setUserFromJson(
                                  r.data['user'],
                                );
                              }
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          } else {
            // display other profile
            return Row(
              spacing: kPadding,
              children: <Widget>[
                Expanded(
                  flex: 1,
                  child: Column(
                    spacing: kPadding,
                    children: <Widget>[
                      CircleAvatar(
                        radius: 75,
                        backgroundColor: kGreen,
                        child: Icon(Icons.person, size: 100),
                      ),
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
                Expanded(
                  flex: 3,
                  child: ListView(
                    children: [
                      Text(
                        user.fullName,
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
              ],
            );
          }
        },
      ),
    );
  }
}

class FieldWithInlineSubmit extends StatelessWidget {
  const FieldWithInlineSubmit({
    super.key,
    required this.controller,
    required this.labelText,
    this.fieldBorderRadius,
    required this.onPressed,
    this.flexes = const (5, 1),
  });

  final TextEditingController controller;
  final String? labelText;
  final BorderRadius? fieldBorderRadius;
  final void Function()? onPressed;

  /// as field and submit button are wrapped in expanded
  /// `flexes` is a tuple of their flex values
  final (int, int) flexes;

  @override
  Widget build(BuildContext context) {
    var (fieldFlex, submitFlex) = flexes;
    return Row(
      spacing: kPadding * 0.5,
      children: [
        Expanded(
          flex: fieldFlex,
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: labelText,
              border: OutlineInputBorder(
                borderRadius:
                    fieldBorderRadius ??
                    BorderRadius.only(
                      topLeft: Radius.circular(kTextTabBarHeight * 0.5),
                      bottomLeft: Radius.circular(kTextTabBarHeight * 0.5),
                    ),
              ),
            ),
            onSubmitted: (_) => onPressed == null ? null : onPressed!(),
          ),
        ),
        Expanded(
          flex: submitFlex,
          child: SizedBox(
            height: kTextTabBarHeight,
            child: InlineFieldSubmitButton(onPressed: onPressed),
          ),
        ),
      ],
    );
  }
}

class InlineFieldSubmitButton extends StatelessWidget {
  const InlineFieldSubmitButton({super.key, required this.onPressed});
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        side: BorderSide(color: kGreen),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(kTextTabBarHeight * 0.5),
            bottomRight: Radius.circular(kTextTabBarHeight * 0.5),
          ),
        ),
      ),
      onPressed: onPressed,
      child: Text('SUBMIT'),
    );
  }
}
