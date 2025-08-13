from flask import jsonify, request
from flask_jwt_extended import jwt_required, current_user
from backend.app import app, db, Book

from sqlalchemy.orm.attributes import flag_modified
from werkzeug.datastructures import FileStorage


@app.route('/book', methods=['POST'])
def book_create():
    book = Book(**request.params)
    db.session.add(book)
    db.session.commit()

    return jsonify({
        'status': 'ok', 'error': None,
        'book': book.attrs,
    })


@app.route('/books', methods=['GET'])
def books_get():
    books = Book.query

    author = request.args.get('author')
    if author != None:
        books = books \
            .filter(Book.author == author)

    title = request.args.get('title')
    if title != None:
        books = books \
            .filter(Book.title == title)

    id = request.args.get('id')
    if id != None:
        books = books \
            .filter(Book.id == id)

    total_count = books.count()
    books = books.order_by_request_args()
    page, books = books.paginate_by_request_args()
    books = [_.attrs for _ in books]

    return jsonify({
        'status': 'ok', 'error': None,
        'books': books,
        'total_count': total_count,
        'page': page,
    })


@app.route('/book/<book_id>', methods=['PUT'])
def book_update(book_id):
    book = Book.query.get_or_404(book_id, f"book_id={book_id}")

    for key, value in request.params.items():
        setattr(book, key, value)
    db.session.commit()

    return jsonify({
        'status': 'ok', 'error': None,
        'book': book.attrs,
    })


@app.route('/book/<book_id>', methods=['DELETE'])
def book_delete(book_id):
    book = Book.query.get_or_404(book_id, f"book_id={book_id}")

    if book.images:
        for book_image in book.images:
            book_image.delete_from_s3()
    db.session.delete(book)
    db.session.commit()

    return jsonify({
        'status': 'ok', 'error': None,
        'book': book.attrs,
    })
