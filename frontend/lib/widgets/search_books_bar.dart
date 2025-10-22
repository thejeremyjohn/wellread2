import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wellread2frontend/constants.dart';
import 'package:wellread2frontend/flask_util/flask_methods.dart';
import 'package:wellread2frontend/models/book.dart';

class SearchBooksBar extends StatelessWidget {
  const SearchBooksBar({super.key});

  Future<List<Book>> booksGet(String title) async {
    Uri endpoint = flaskUri('/books', queryParameters: {'title': title});
    final r = await flaskGet(endpoint);
    if (!r.isOk) throw Exception(r.error);
    return (r.data['books'] as List)
        .map((book) => Book.fromJson(book as Map<String, dynamic>))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kTextTabBarHeight,
      child: SearchAnchor(
        builder: (context, controller) {
          return SearchBar(
            padding: const WidgetStatePropertyAll<EdgeInsets?>(
              EdgeInsets.symmetric(horizontal: kPadding),
            ),
            backgroundColor: const WidgetStatePropertyAll<Color?>(
              Colors.transparent,
            ),
            shadowColor: const WidgetStatePropertyAll<Color?>(
              Colors.transparent,
            ),
            shape: WidgetStatePropertyAll<OutlinedBorder?>(
              RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            controller: controller,
            onChanged: (_) => controller.openView(),
            trailing: const <Widget>[Icon(Icons.search)],
          );
        },
        suggestionsBuilder: (context, controller) => controller.text.isEmpty
            ? Future.value([])
            : booksGet(controller.text).then(
                (books) => books.map<ListTile>(
                  (book) => ListTile(
                    leading: book.coverThumb,
                    title: Text(book.title),
                    subtitle: Text(book.author),
                    onTap: () {
                      controller.closeView('');
                      context.go('/book/${book.id}');
                    },
                  ),
                ),
              ),
      ),
    );
  }
}
