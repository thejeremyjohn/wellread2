import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:wellread2frontend/constants.dart';
import 'package:wellread2frontend/models/book.dart';
import 'package:wellread2frontend/models/bookshelf.dart';
import 'package:wellread2frontend/models/review.dart';
import 'package:wellread2frontend/providers/book_page_state.dart';
import 'package:wellread2frontend/providers/user_state.dart';
import 'package:wellread2frontend/widgets/async_consumer.dart';
import 'package:wellread2frontend/widgets/async_widget.dart';
import 'package:wellread2frontend/widgets/clickable.dart';
import 'package:wellread2frontend/widgets/column_dialog.dart';
import 'package:wellread2frontend/widgets/link_text.dart';
import 'package:wellread2frontend/widgets/spacer_body.dart';
import 'package:wellread2frontend/widgets/underline.dart';

class BookPage extends StatefulWidget {
  const BookPage({super.key, required this.bookId});
  final String bookId;

  @override
  State<BookPage> createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> {
  late Future<Book> _futureBook;
  late Future<List<Review>> _futureReviews;
  late Future<List<Bookshelf>> _futureBookshelves;
  final _addTagsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    String userId = context.read<UserState>().user.id.toString();
    _futureBook = context.read<BookPageState>().bookGet(widget.bookId);
    _futureBookshelves = context.read<BookPageState>().bookshelvesGet(userId);
    _futureReviews = context.read<BookPageState>().reviewsGet({
      'book_id': widget.bookId,
    });
  }

  @override
  void dispose() {
    _addTagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget shelfButtonDialogs = AsyncWidget(
      future: _futureBook,
      builder: (context, _) => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ButtonStyle(backgroundColor: WidgetStateProperty.all(kGreen)),
          onPressed: () => showDialog<String>(
            context: context,
            builder: (BuildContext context) => AsyncConsumer<BookPageState>(
              future: _futureBookshelves,
              builder: (context, bps, _) {
                return ColumnDialog(
                  children: <Widget>[
                    Text('Choose a shelf for this book'),
                    ...bps.shelves.map(
                      (shelf) => SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              bps.shelfChangeMembership(widget.bookId, shelf),
                          label: Text(shelf.name),
                          icon: bps.book.myShelf == shelf
                              ? Icon(Icons.check)
                              : null,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: bps.book.myShelf == null
                            ? null
                            : () => showDialog(
                                context: context,
                                builder: (BuildContext context) =>
                                    Consumer<BookPageState>(
                                      builder: (context, bps, _) {
                                        return ColumnDialog(
                                          children: <Widget>[
                                            Text(
                                              'Are you sure you want to remove this book from your shelves?',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge!
                                                  .copyWith(
                                                    fontFamily: fontFamilyAlt,
                                                  ),
                                            ),
                                            const Text(
                                              'Removing this book will clear associated ratings, reviews, and tags.',
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceAround,
                                              children: <Widget>[
                                                ElevatedButton(
                                                  onPressed: () =>
                                                      context.pop(),
                                                  child: const Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    bps.unshelf();
                                                    context.pop();
                                                    context.pop();
                                                  },
                                                  child: const Text('Remove'),
                                                ),
                                              ],
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                              ),
                        style: ElevatedButton.styleFrom(iconColor: Colors.red),
                        label: const Text('Remove from my shelf'),
                        icon: Icon(Icons.remove_circle_outline),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: bps.book.myShelf == null
                            ? null
                            : () {
                                void onSubmitAddTag() {
                                  if (_addTagsController.text.isNotEmpty) {
                                    bps.tagCreate(_addTagsController.text).then(
                                      (r) {
                                        if (r.isOk) {
                                          _addTagsController.clear();
                                        } else if (context.mounted) {
                                          r.showSnackBar(context);
                                        }
                                      },
                                    );
                                  }
                                }

                                showDialog(
                                  context: context,
                                  builder: (context) => Consumer<BookPageState>(
                                    builder: (context, bps, _) {
                                      return ColumnDialog(
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            spacing: kPadding,
                                            children: <Widget>[
                                              SizedBox(
                                                width: 200,
                                                height: kTextTabBarHeight,
                                                child: TextField(
                                                  controller:
                                                      _addTagsController,
                                                  decoration: InputDecoration(
                                                    labelText: 'Add tags',
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            kTextTabBarHeight *
                                                                0.5,
                                                          ),
                                                    ),
                                                  ),
                                                  onSubmitted: (_) =>
                                                      onSubmitAddTag(),
                                                ),
                                              ),
                                              SizedBox(
                                                height: kTextTabBarHeight,
                                                child: ElevatedButton(
                                                  onPressed: onSubmitAddTag,
                                                  child: const Text(
                                                    'Add',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          ConstrainedBox(
                                            constraints: BoxConstraints(
                                              minHeight: 300,
                                              maxHeight: 600,
                                            ),
                                            child: SingleChildScrollView(
                                              child: Wrap(
                                                spacing: kPadding * 0.8,
                                                runSpacing: kPadding * 0.8,
                                                children: bps.tags.map((tag) {
                                                  bool isTagged = bps
                                                      .book
                                                      .myTags
                                                      .contains(tag);
                                                  return ConstrainedBox(
                                                    constraints: BoxConstraints(
                                                      maxWidth: 130,
                                                    ),
                                                    child: ElevatedButton(
                                                      onPressed: () =>
                                                          bps.toggleTag(
                                                            tag,
                                                            isTagged,
                                                          ),
                                                      style:
                                                          ElevatedButton.styleFrom(
                                                            backgroundColor:
                                                                isTagged
                                                                ? kGreen
                                                                : null,
                                                            padding:
                                                                EdgeInsets.all(
                                                                  kPadding *
                                                                      0.8,
                                                                ),
                                                          ),
                                                      child: Tooltip(
                                                        message:
                                                            'toggle ${tag.name}',
                                                        child: Text(
                                                          tag.name,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          maxLines: 1,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                );
                              },
                        child: Text('Continue to tags'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          child: Text(
            context.select((BookPageState b) => b.book.myShelf?.name) ??
                'unshelved',
          ),
        ),
      ),
    );

    Widget coverAndShelf = AsyncConsumer<BookPageState>(
      future: _futureBook,
      builder: (context, bps, _) => Column(
        children: [
          bps.book.cover,
          SizedBox(height: kPadding),
          shelfButtonDialogs,
          SizedBox(height: kPadding),
          RatingBar.builder(
            initialRating: bps.book.myRating!,
            minRating: 1,
            itemSize: Theme.of(context).textTheme.headlineLarge!.fontSize!,
            itemBuilder: (context, idx) => MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Icon(Icons.star, color: Colors.amber),
            ),
            onRatingUpdate: (rating) {
              if (rating != bps.book.myRating) {
                bps.reviewCreateOrUpdate(widget.bookId, rating: rating.toInt());
              }
            },
          ),
          Text('Rate this book'),
          bps.book.myRating != 0
              ? LinkText(
                  'Review this book',
                  style: TextStyle(color: kGreen, fontWeight: FontWeight.bold),
                  onClick: () => context.go('/book/${widget.bookId}/review'),
                )
              : Container(),
        ],
      ),
    );

    Widget bookDetails = AsyncConsumer<BookPageState>(
      future: _futureBook,
      builder: (context, bps, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            bps.book.title,
            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
              fontFamily: fontFamilyAlt,
              fontWeight: FontWeight.w600,
            ),
          ),
          LinkText(
            bps.book.author,
            style: TextStyle(
              fontFamily: fontFamilyAlt,
              fontWeight: FontWeight.w400, // normal
            ),
            onClick: () => context.go('/author', extra: bps.book.author),
          ),
          SizedBox(height: kPadding),
          Row(
            children: [
              RatingBar.builder(
                initialRating: bps.book.avgRating!,
                itemSize: Theme.of(context).textTheme.headlineLarge!.fontSize!,
                itemBuilder: (context, idx) =>
                    Icon(Icons.star, color: Colors.amber),
                onRatingUpdate: (rating) {},
                ignoreGestures: true,
              ),
              SizedBox(width: kPadding),
              Text(
                bps.book.avgRatingString!,
                style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  fontFamily: fontFamilyAlt,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: kPadding),
              Text(
                '${bps.book.nReviews!} reviews · ${bps.book.nRatings!} ratings',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall!.copyWith(color: Colors.grey),
              ),
            ],
          ),
          SizedBox(height: kPadding),
          Text(bps.book.description ?? ''),
          SizedBox(height: kPadding),
        ],
      ),
    );

    Widget communityReviews = AsyncConsumer<BookPageState>(
      future: _futureReviews,
      builder: (context, bps, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: kPadding,
        children: [
          Text(
            'Community Reviews:',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              fontFamily: fontFamilyAlt,
              fontWeight: FontWeight.w600,
            ),
          ),
          ...List.generate(bps.reviews.length, (index) {
            Review review = bps.reviews[index];
            return index != bps.reviews.length - 5
                ? ReviewWidget(review: review)
                : VisibilityDetector(
                    key: Key('nearBottomReview'),
                    onVisibilityChanged: (v) {
                      if (v.visibleFraction > 0) bps.reviewsGetMore();
                    },
                    child: ReviewWidget(review: review),
                  );
          }),
        ],
      ),
    );

    return SpacerBody(
      child: Row(
        spacing: kPadding,
        children: <Widget>[
          Expanded(flex: 1, child: coverAndShelf),
          Expanded(
            flex: 3,
            child: ListView(children: [bookDetails, communityReviews]),
          ),
        ],
      ),
    );
  }
}

class ReviewWidget extends StatelessWidget {
  const ReviewWidget({super.key, required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: kPadding,
      children: [
        Expanded(
          flex: 1,
          child: Clickable(
            onClick: () => context.go('/profile/${review.user!.id}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: kGreen,
                  child: Icon(Icons.person),
                ),
                Text(review.user!.fullName),
                Text(
                  '${review.user!.nReviews!} reviews',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall!.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RatingBar.builder(
                initialRating: review.rating.toDouble(),
                itemSize: Theme.of(context).textTheme.bodyLarge!.fontSize!,
                itemBuilder: (context, idx) =>
                    Icon(Icons.star, color: Colors.amber),
                onRatingUpdate: (rating) {},
                ignoreGestures: true,
              ),
              Text(review.content ?? '', softWrap: true, maxLines: 5),
              Wrap(
                spacing: kPadding * 0.75,
                children: [
                  for (Bookshelf tag in review.tags!)
                    Clickable(
                      onClick: () {
                        context.go(
                          '/books?userId=${review.userId}&bookshelfId=${tag.id}',
                        );
                      },
                      child: Underline(
                        underlineColor: kGreen,
                        text: Text(
                          tag.name,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
