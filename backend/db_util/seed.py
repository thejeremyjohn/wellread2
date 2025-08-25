''' USAGE: (from [project_root]/backend) python db_util/seed.py
'''
import sys; sys.path.append('../')
from backend.app import app, db, User, Book, Bookshelf, BookBookshelf, Review

user1 = User(first_name='guest1', last_name='guesterson',
             email='guest1@email.com', password='password')
user2 = User(first_name='guest2', last_name='guesterson',
             email='guest2@email.com', password='password')
user3 = User(first_name='guest3', last_name='guesterson',
             email='guest3@email.com', password='password')

user1.bookshelves = [
    Bookshelf(name='want to read', can_delete=False),
    Bookshelf(name='currently reading', can_delete=False),
    Bookshelf(name='read', can_delete=False),
]
user2.bookshelves = [
    Bookshelf(name='want to read', can_delete=False),
    Bookshelf(name='currently reading', can_delete=False),
    Bookshelf(name='read', can_delete=False),
]
user3.bookshelves = [
    Bookshelf(name='want to read', can_delete=False),
    Bookshelf(name='currently reading', can_delete=False),
    Bookshelf(name='read', can_delete=False),
]

book1 = Book(
    title='Book: The 1st',
    author='Flying Spaghetti Monster',
    description='The first book that ever was. The grammar, the sentence structure--it\'s damn inventive is what it is!',
)
book2 = Book(
    title='If I Dit it',
    author='Christopher Columbus',
    description='I says to myself, I says, \'HEY, who doesnt like a nice warm blanket?\' Alright, keep your nose clean. Take a hike.'
)
book3 = Book(
    title='12 Rules For-- Whoops Turns Out I\'m Completely Bat DooDoo',
    author='Peter Jordensen',
    description='It isn\'t easy being green. Bloody hell! And it isn\'t obvious that being addicted to benzos will do that to ya. But, there you go.'
)

book_bookshelves = [
    BookBookshelf(book=book1, bookshelf=user1.bookshelves[0]),
    BookBookshelf(book=book1, bookshelf=user1.bookshelves[1]),
    BookBookshelf(book=book1, bookshelf=user1.bookshelves[2]),
    BookBookshelf(book=book2, bookshelf=user2.bookshelves[0]),
    BookBookshelf(book=book2, bookshelf=user2.bookshelves[1]),
    BookBookshelf(book=book2, bookshelf=user2.bookshelves[2]),
    BookBookshelf(book=book3, bookshelf=user3.bookshelves[0]),
    BookBookshelf(book=book3, bookshelf=user3.bookshelves[1]),
    BookBookshelf(book=book3, bookshelf=user3.bookshelves[2]),
]

reviews = [
    Review(book=book1, user=user1, rating=5,
           review='This book is the best book ever written. I love it!'),
    Review(book=book1, user=user2, rating=4,
           review='A fascinating read, but not without its flaws.'),
    Review(book=book1, user=user3, rating=3,
           review='It had some interesting ideas, but the execution was lacking.'),
    Review(book=book2, user=user1, rating=2,
           review='I expected more from this author. It was a bit disappointing.'),
    Review(book=book2, user=user2, rating=1,
           review='Did not enjoy this book at all. Would not recommend.'),
    Review(book=book2, user=user3, rating=4,
           review='A decent read, but not my favorite. Still worth checking out.'),
    Review(book=book3, user=user1, rating=5,
           review='An absolute masterpiece! A must-read for everyone.'),
    Review(book=book3, user=user2, rating=4,
           review='A thrilling conclusion to the series. Highly recommend!'),
    Review(book=book3, user=user3, rating=3,
           review='It was okay, but I expected more from the final book in the series.'),
]

with app.app_context():
    db.session.add_all([user1, user2, user3])
    db.session.add_all([book1, book2, book3])
    db.session.add_all(book_bookshelves)
    db.session.add_all(reviews)
    db.session.commit()
