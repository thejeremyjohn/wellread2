''' USAGE: (from [project_root]/backend) python db_util/seed.py
'''
from faker import Faker
import sys; sys.path.append('../')
from backend.app import app, db, User, Book, Bookshelf, BookBookshelf, Review, BookImage

fake = Faker()
Faker.seed('wellread')


user1 = User(first_name='guest1', last_name='guesterson',
             email='guest1@email.com', password='password')
users = [user1]


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

books = []
for _ in range(fake.random.randint(170, 300)):
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

from book_image_uuids_for_seed import goodreads_ids_by_uuid
# assigning random image uuids to books
# (the images pre-uploaded to s3 are not part of this repo)
fake.random.shuffle(uuids := list(goodreads_ids_by_uuid.keys()))
book_images = [BookImage(book=books[i], uuid=uuid, file_extension='.jpg', index=0)
               for i, uuid in enumerate(uuids)]

with app.app_context():
    db.session.add_all(users)
    db.session.add_all(books)
    db.session.add_all(books_bookshelves)
    db.session.add_all(reviews)
    db.session.add_all(book_images)
    db.session.commit()
