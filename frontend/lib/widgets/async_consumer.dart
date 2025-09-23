import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AsyncConsumer<T> extends StatelessWidget {
  const AsyncConsumer({
    super.key,
    required this.future,
    required this.builder,
    this.progressIndicator,
  });

  /// the value of this future is un-important / un-used
  /// however the idea is that this future resolves
  ///  as soon as `Consumer<T>` is ready
  final Future future;

  /// builder for `Consumer<T>`
  final Widget Function(BuildContext context, T value, Widget? child) builder;

  /// OPINION: null `ProgressIndicator` is best for quick loading on Web
  final ProgressIndicator? progressIndicator;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Consumer<T>(builder: builder);
        } else if (snapshot.hasError) {
          return Text('${snapshot.error}');
        }
        return progressIndicator ?? Container();
      },
    );
  }
}
