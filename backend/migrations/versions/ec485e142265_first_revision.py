"""first revision

Revision ID: ec485e142265
Revises: 
Create Date: 2025-07-19 12:17:29.489655

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'ec485e142265'
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    op.get_bind().execute(sa.text('''
        CREATE OR REPLACE FUNCTION update_modified_column()
        RETURNS TRIGGER AS $$
        BEGIN
            NEW.modified = now();
            RETURN NEW;
        END;
        $$ language 'plpgsql';

        CREATE TABLE users (
            id int NOT NULL PRIMARY KEY,
            first_name TEXT NOT NULL,
            last_name TEXT,
            email TEXT NOT NULL UNIQUE,
            password_hash TEXT NOT NULL
        );
        ALTER TABLE users
            ADD COLUMN created TIMESTAMPTZ DEFAULT now(),
            ADD COLUMN modified TIMESTAMPTZ DEFAULT now();
        CREATE TRIGGER update_users_modified BEFORE UPDATE ON users
            FOR EACH ROW EXECUTE PROCEDURE update_modified_column();
        CREATE SEQUENCE users_id_seq OWNED BY users.id;
        ALTER TABLE users ALTER COLUMN id SET DEFAULT nextval('users_id_seq');
        UPDATE users SET id = nextval('users_id_seq');

        CREATE TABLE books (
            id int NOT NULL PRIMARY KEY,
            author TEXT NOT NULL,
            title TEXT NOT NULL,
            description TEXT
        );
        ALTER TABLE books
            ADD COLUMN created TIMESTAMPTZ DEFAULT now(),
            ADD COLUMN modified TIMESTAMPTZ DEFAULT now();
        CREATE TRIGGER update_books_modified BEFORE UPDATE ON books
            FOR EACH ROW EXECUTE PROCEDURE update_modified_column();
        CREATE SEQUENCE books_id_seq OWNED BY books.id;
        ALTER TABLE books ALTER COLUMN id SET DEFAULT nextval('books_id_seq');
        UPDATE books SET id = nextval('users_id_seq');
                                  
        CREATE TABLE book_images (
            uuid UUID NOT NULL PRIMARY KEY,
            book_id INTEGER REFERENCES books(id) ON DELETE CASCADE NOT NULL,
            index INTEGER
        );
        ALTER TABLE book_images
            ADD COLUMN created TIMESTAMPTZ DEFAULT now(),
            ADD COLUMN modified TIMESTAMPTZ DEFAULT now();
        CREATE TRIGGER update_book_images_modified BEFORE UPDATE ON book_images
            FOR EACH ROW EXECUTE PROCEDURE update_modified_column();

        CREATE TABLE bookshelves (
            id int NOT NULL PRIMARY KEY,
            user_id INTEGER REFERENCES users(id) ON DELETE CASCADE NOT NULL,
            name TEXT NOT NULL,
            can_delete BOOLEAN DEFAULT false
        );
        ALTER TABLE bookshelves
            ADD COLUMN created TIMESTAMPTZ DEFAULT now(),
            ADD COLUMN modified TIMESTAMPTZ DEFAULT now();
        CREATE TRIGGER update_bookshelves_modified BEFORE UPDATE ON bookshelves
            FOR EACH ROW EXECUTE PROCEDURE update_modified_column();
        CREATE SEQUENCE bookshelves_id_seq OWNED BY bookshelves.id;
        ALTER TABLE bookshelves ALTER COLUMN id SET DEFAULT nextval('bookshelves_id_seq');
        UPDATE bookshelves SET id = nextval('bookshelves_id_seq');
                                  
        CREATE TABLE books_bookshelves (
            book_id INTEGER REFERENCES books(id) ON DELETE CASCADE NOT NULL,
            bookshelf_id INTEGER REFERENCES bookshelves(id) ON DELETE CASCADE NOT NULL,
            PRIMARY KEY (book_id, bookshelf_id)
        );
        ALTER TABLE books_bookshelves
            ADD COLUMN created TIMESTAMPTZ DEFAULT now(),
            ADD COLUMN modified TIMESTAMPTZ DEFAULT now();
        CREATE TRIGGER update_books_bookshelves_modified BEFORE UPDATE ON books_bookshelves
            FOR EACH ROW EXECUTE PROCEDURE update_modified_column();
                                  
        CREATE TABLE reviews (
            book_id INTEGER REFERENCES books(id) ON DELETE CASCADE NOT NULL,
            user_id INTEGER REFERENCES users(id) ON DELETE CASCADE NOT NULL,
            PRIMARY KEY (book_id, user_id),
            rating INTEGER CHECK (rating >= 1 AND rating <= 5),
            review TEXT
        );
        ALTER TABLE reviews
            ADD COLUMN created TIMESTAMPTZ DEFAULT now(),
            ADD COLUMN modified TIMESTAMPTZ DEFAULT now();
        CREATE TRIGGER update_reviews_modified BEFORE UPDATE ON reviews
            FOR EACH ROW EXECUTE PROCEDURE update_modified_column();
    '''))


def downgrade():
    op.get_bind().execute(sa.text('''
        DROP TABLE users CASCADE;
        DROP TRIGGER IF EXISTS update_users_modified ON users;
        DROP TABLE books CASCADE;
        DROP TRIGGER IF EXISTS update_books_modified ON books;
        DROP TABLE book_images CASCADE;
        DROP TRIGGER IF EXISTS update_book_images_modified ON book_images;
        DROP TABLE bookshelves CASCADE;
        DROP TRIGGER IF EXISTS update_bookshelves_modified ON bookshelves;
        DROP TABLE books_bookshelves CASCADE;
        DROP TRIGGER IF EXISTS update_books_bookshelves_modified ON books_bookshelves;
        DROP TABLE reviews CASCADE;
        DROP TRIGGER IF EXISTS update_reviews_modified ON reviews;
    '''))
