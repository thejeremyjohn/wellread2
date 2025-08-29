''' USAGE: (from [project_root]/backend) python db_util/seed.py
'''
from faker import Faker
import sys; sys.path.append('../')
from backend.app import app, db, User, Book, Bookshelf, BookBookshelf, Review

fake = Faker()


user1 = User(first_name='guest1', last_name='guesterson',
             email='guest1@email.com', password='password')
user2 = User(first_name='guest2', last_name='guesterson',
             email='guest2@email.com', password='password')
user3 = User(first_name='guest3', last_name='guesterson',
             email='guest3@email.com', password='password')
users = [user1, user2, user3]


def random_user() -> User:
    return User(
        first_name=fake.first_name(),
        last_name=fake.last_name(),
        email=fake.profile(fields=['mail'])['mail'],
        password=fake.password()
    )


def random_bookshelves() -> list[Bookshelf]:
    ''' generate between 0 and 10 bookshelves/tags with adjective names '''
    return [
        Bookshelf(name=name, can_delete=True) for name in
        fake.words(nb=fake.random.randint(0, 10), part_of_speech='adjective', unique=True)
    ]


for _ in range(fake.random.randint(10, 100)):
    users.append(random_user())
for user in users:
    user.bookshelves.extend(random_bookshelves())

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
books = [book1, book2, book3]

for _ in range(fake.random.randint(30, 100)):
    books.append(
        Book(
            title=fake.sentence(nb_words=fake.random.randint(1, 5)).rstrip('.').title(),
            author=fake.name(),
            description=fake.paragraph(nb_sentences=fake.random.randint(1, 5),
                                       variable_nb_sentences=True)
        )
    )

books_bookshelves = []
reviews = []
for user in users:
    for book in books:
        essentials = [None] + [s for s in user.bookshelves if not s.can_delete]
        bookshelf = fake.random.choice(essentials)
        if bookshelf:
            books_bookshelves.append(
                BookBookshelf(book=book, bookshelf=bookshelf)
            )
            if bookshelf.name == 'read':
                reviews.append(
                    Review(book=book, user=user,
                           rating=fake.random.randint(1, 5),
                           content=fake.random.choice(
                               [None, fake.paragraph(variable_nb_sentences=True)]
                           ))
                )
            tags = [None] + [s for s in user.bookshelves if s.can_delete]
            for tag in fake.random.sample(tags, k=fake.random.randint(1, len(tags))):
                if tag:
                    books_bookshelves.append(
                        BookBookshelf(book=book, bookshelf=tag)
                    )


with app.app_context():
    db.session.add_all(users)
    db.session.add_all(books)
    db.session.add_all(books_bookshelves)
    db.session.add_all(reviews)
    db.session.commit()
