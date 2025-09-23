import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:wellread2frontend/constants.dart';
import 'package:wellread2frontend/models/book.dart';
import 'package:wellread2frontend/models/bookshelf.dart';
import 'package:wellread2frontend/models/review.dart';
import 'package:wellread2frontend/providers/book_page_state.dart';
import 'package:wellread2frontend/providers/user_state.dart';
import 'package:wellread2frontend/widgets/async_consumer.dart';
import 'package:wellread2frontend/widgets/link_text.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key, required this.bookId});
  final String bookId;

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  late Future<Book> _futureBook;
  late Future<List<Review>> _futureReviews;
  late Future<List<Bookshelf>> _futureBookshelves;

  final _contentController = TextEditingController();
  final _tagDropdownController = TextEditingController();

  final int _minContentLines = 5;
  int _contentLines = 5;
  final int _maxContentLines = 50;

  @override
  void initState() {
    super.initState();
    _futureBook = context.read<BookPageState>().bookGet(widget.bookId);

    String userId = context.read<UserState>().user.id.toString();
    _futureReviews = context
        .read<BookPageState>()
        .reviewsGet({'book_id': widget.bookId, 'user_id': userId})
        .then((reviews) {
          _contentController.text = reviews.first.content ?? '';
          return reviews;
        });
    _futureBookshelves = context.read<BookPageState>().bookshelvesGet(userId);
  }

  @override
  void dispose() {
    _contentController.dispose();
    _tagDropdownController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(kPadding),
          child: AsyncConsumer<BookPageState>(
            future: Future.wait([_futureBook, _futureReviews]),
            builder: (context, bps, _) {
              TextStyle breadcrumbStyle = Theme.of(context)
                  .textTheme
                  .titleMedium!
                  .copyWith(
                    fontFamily: 'LibreBaskerville',
                    fontWeight: FontWeight.w600,
                  );

              return Column(
                spacing: kPadding,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text.rich(
                    style: breadcrumbStyle,
                    TextSpan(
                      children: [
                        WidgetSpan(
                          child: LinkText(
                            bps.book.title,
                            style: breadcrumbStyle,
                            onClick: () => context.go('/book/${widget.bookId}'),
                          ),
                        ),
                        WidgetSpan(child: Text(' > ', style: breadcrumbStyle)),
                        WidgetSpan(
                          child: LinkText(
                            'Review',
                            style: breadcrumbStyle,
                            onClick: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'You have clicked Review, but-- so-- Congratulations!',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: kGreen,
                                ),
                              );
                            },
                            // TODO display review in read-mode
                          ),
                        ),
                        WidgetSpan(child: Text(' > ', style: breadcrumbStyle)),
                        WidgetSpan(child: Text('Edit', style: breadcrumbStyle)),
                      ],
                    ),
                  ),
                  Column(
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: kPadding,
                        children: <Widget>[
                          bps.book.coverThumb,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              LinkText(
                                bps.book.title,
                                style: Theme.of(context).textTheme.titleLarge!
                                    .copyWith(
                                      fontFamily: 'LibreBaskerville',
                                      fontWeight: FontWeight.w600,
                                    ),
                                onClick: () =>
                                    context.go('/book/${bps.book.id}'),
                              ),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    WidgetSpan(
                                      child: Text(
                                        'by ',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium!,
                                      ),
                                    ),
                                    WidgetSpan(
                                      child: LinkText(
                                        bps.book.author,
                                        style: breadcrumbStyle,
                                        onClick: () => context.go(
                                          '/author',
                                          extra: bps.book.author,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Divider(height: 0),
                    ],
                  ),
                  Row(
                    spacing: kPadding * 0.5,
                    children: [
                      Text('My rating:'),
                      RatingBar.builder(
                        initialRating: bps.reviews.first.rating.toDouble(),
                        minRating: 1,
                        itemSize: Theme.of(
                          context,
                        ).textTheme.bodyLarge!.fontSize!,
                        itemBuilder: (context, idx) =>
                            Icon(Icons.star, color: Colors.amber),
                        onRatingUpdate: (rating) {
                          if (rating != bps.reviews.first.rating) {
                            bps.reviewCreateOrUpdate(
                              widget.bookId,
                              rating: rating.toInt(),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  AsyncConsumer<BookPageState>(
                    future: _futureBookshelves,
                    builder: (context, bps, _) {
                      List<InlineSpan> bookshelvesAndTags = [];
                      for (Bookshelf shelf in bps.book.myShelves!) {
                        bookshelvesAndTags.add(
                          WidgetSpan(
                            child: LinkText(
                              shelf.name,
                              onClick: () {
                                final user = context.read<UserState>().user;
                                context.go(
                                  '/books?userId=${user.id}&bookshelfId=${shelf.id}',
                                );
                              },
                            ),
                          ),
                        );
                        bookshelvesAndTags.add(WidgetSpan(child: Text(', ')));
                      }
                      bookshelvesAndTags.removeLast();

                      return Row(
                        spacing: kPadding,
                        children: [
                          Text('Shelves:'),
                          DropdownMenu<(Bookshelf, bool)>(
                            initialSelection: (bps.book.myShelf!, true),
                            dropdownMenuEntries: bps.shelves.map((shelf) {
                              bool isTagged = bps.book.myShelf == shelf;
                              return DropdownMenuEntry<(Bookshelf, bool)>(
                                leadingIcon: Icon(
                                  isTagged
                                      ? Icons.radio_button_checked_outlined
                                      : Icons.radio_button_off_outlined,
                                ),
                                value: (shelf, isTagged),
                                label: shelf.name,
                              );
                            }).toList(),
                            onSelected: (t) {
                              if (t != null) {
                                var (shelf, _) = t;
                                bps.shelfChangeMembership(
                                  bps.book.id.toString(),
                                  shelf,
                                );
                              }
                            },
                          ),
                          Text('Tags:'),
                          DropdownMenu<(Bookshelf, bool)>(
                            menuHeight: 600,
                            controller: _tagDropdownController,
                            closeBehavior: DropdownMenuCloseBehavior.none,
                            dropdownMenuEntries: bps.tags.map((tag) {
                              bool isTagged = bps.book.myTags.contains(tag);
                              return DropdownMenuEntry<(Bookshelf, bool)>(
                                leadingIcon: Icon(
                                  isTagged
                                      ? Icons.check_box_outlined
                                      : Icons.check_box_outline_blank,
                                ),
                                value: (tag, isTagged),
                                label: tag.name,
                              );
                            }).toList(),
                            onSelected: (t) {
                              if (t != null) {
                                var (tag, isTagged) = t;
                                bps.toggleTag(tag, isTagged);
                                _tagDropdownController.clear();
                              }
                            },
                          ),
                          Expanded(
                            child: Text.rich(
                              TextSpan(children: bookshelvesAndTags),
                              softWrap: true,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  Divider(height: kPadding),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('What did you think?'),
                      Text.rich(
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall!.copyWith(color: Colors.grey),
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Shrink text field',
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  _contentLines = max(
                                    _contentLines - 5,
                                    _minContentLines,
                                  );
                                  setState(() {});
                                },
                            ),
                            TextSpan(text: ' | '),
                            TextSpan(
                              text: 'Enlarge text field',
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  _contentLines = min(
                                    _contentLines + 5,
                                    _maxContentLines,
                                  );
                                  setState(() {});
                                },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  TextFormField(
                    keyboardType: TextInputType.multiline,
                    controller: _contentController,
                    maxLines: _contentLines,
                    decoration: InputDecoration(border: OutlineInputBorder()),
                  ),
                  Text('[checkbox] Hide entire review because of spoilers'),
                  Divider(height: kPadding),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          bps.reviewCreateOrUpdate(
                            widget.bookId,
                            rating: bps.book.myRating!.toInt(),
                            content: _contentController.text,
                          );
                          context.go('/book/${widget.bookId}');
                        },
                        child: Text('Save'),
                      ),
                      Text('[checkbox] Add to my update feed'),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
