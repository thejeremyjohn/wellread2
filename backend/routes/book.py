from flask import jsonify, request
from flask_jwt_extended import jwt_required
from backend.app import app, db, Book


@app.route('/book', methods=['POST'])
@jwt_required()
def book_create():
    book = Book(**request.params)
    db.session.add(book)
    db.session.commit()

    return jsonify({
        'status': 'ok', 'error': None,
        'book': book.attrs,
    })


@app.route('/books', methods=['GET'])
@jwt_required()
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

    id = request.args.get('id', type=int)
    if id != None:
        books = books \
            .filter(Book.id == id)

    total_count = books.count()
    books = books.order_by_request_args()
    page, books = books.paginate_by_request_args()
    books = [_.attrs_(add_props=request.add_props, expand=request.expand)
             for _ in books]

    return jsonify({
        'status': 'ok', 'error': None,
        'books': books,
        'total_count': total_count,
        'page': page,
    })


@app.route('/book/<book_id>', methods=['PUT'])
@jwt_required()
def book_update(book_id: int):
    book = Book.query.get(book_id)

    for key, value in request.params.items():
        setattr(book, key, value)
    db.session.commit()

    return jsonify({
        'status': 'ok', 'error': None,
        'book': book.attrs,
    })


@app.route('/book/<book_id>', methods=['DELETE'])
@jwt_required()
def book_delete(book_id: int):
    book = Book.query.get(book_id)

    if book.images:
        for book_image in book.images:
            book_image.delete_from_s3()
    db.session.delete(book)
    db.session.commit()

    return jsonify({
        'status': 'ok', 'error': None,
        'book': book.attrs,
    })
