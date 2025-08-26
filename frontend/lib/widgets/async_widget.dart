import 'package:flutter/material.dart';

class AsyncWidget extends StatelessWidget {
  const AsyncWidget({
    super.key,
    required this.future,
    required this.builder,
    this.progressIndicator,
  });

  final Future future;
  final Widget Function(BuildContext context, dynamic awaitedData) builder;
  final ProgressIndicator? progressIndicator;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return builder(context, snapshot.data!);
        } else if (snapshot.hasError) {
          return Text('${snapshot.error}');
        }
        return progressIndicator ?? Container();
      },
    );
  }
}
