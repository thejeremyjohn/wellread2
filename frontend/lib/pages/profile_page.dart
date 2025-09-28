import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wellread2frontend/constants.dart';
import 'package:wellread2frontend/flask_util/flask_methods.dart';
import 'package:wellread2frontend/flask_util/flask_response.dart';
import 'package:wellread2frontend/models/user.dart';
import 'package:wellread2frontend/providers/user_state.dart';
import 'package:wellread2frontend/widgets/password_field.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.userId});
  final String userId;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isMe = false;

  @override
  void initState() {
    User me = context.read<UserState>().user;
    if (me.id.toString() == widget.userId) {
      _isMe = true;
      _firstNameController.text = me.firstName;
      _lastNameController.text = me.lastName;
      _emailController.text = me.email;
    }
    super.initState();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _oldPasswordController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<FlaskResponse> userUpdate(Map<String, String> body) async {
    return await flaskPut(flaskUri('/user'), body: body);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (_isMe) {
              // profile edit form
              return Padding(
                padding: const EdgeInsets.all(kPadding),
                child: SizedBox(
                  width: constraints.maxWidth * 0.8 + kPadding,
                  child: Column(
                    spacing: kPadding,
                    // mainAxisAlignment: MainAxisAlignment.center,
                    // crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Change your name? Update your password?',
                        style: Theme.of(context).textTheme.bodyMedium!,
                      ),
                      FieldWithInlineSubmit(
                        controller: _firstNameController,
                        labelText: 'First Name',
                        onPressed: () {
                          userUpdate({
                            'first_name': _firstNameController.text,
                          }).then((r) {
                            if (context.mounted) {
                              r.showSnackBar(
                                context,
                                customMessageOnSuccess: !r.isOk
                                    ? ''
                                    : 'updated firstName',
                              );
                            }
                          });
                        },
                      ),
                      FieldWithInlineSubmit(
                        controller: _lastNameController,
                        labelText: 'Last Name',
                        onPressed: () {
                          userUpdate({
                            'last_name': _lastNameController.text,
                          }).then((r) {
                            if (context.mounted) {
                              r.showSnackBar(
                                context,
                                customMessageOnSuccess: !r.isOk
                                    ? ''
                                    : 'updated lastName',
                              );
                            }
                          });
                        },
                      ),
                      // FieldWithInlineSubmit(
                      //   controller: _emailController,
                      //   labelText: 'Email',
                      // onPressed: () {
                      //   userUpdate(context, {
                      //     'email': _emailController.text,
                      //   });
                      // },
                      // ),
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
                                topLeft: Radius.circular(
                                  kTextTabBarHeight * 0.5,
                                ),
                                bottomLeft: Radius.circular(
                                  kTextTabBarHeight * 0.5,
                                ),
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
                                  }
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }

            // TODO other profile view
            return Text(
              '??? other profile ???',
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
