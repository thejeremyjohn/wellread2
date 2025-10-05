from flask import jsonify, request
from flask_jwt_extended import jwt_required, current_user
from backend import util_functions
from backend.app import app, db, Bookshelf, BookBookshelf


@app.route('/bookshelf', methods=['POST'])
@jwt_required()
def bookshelf_create():
    (params := request.params).pop('can_delete', None)  # disallow setting can_delete
    bookshelf = Bookshelf(user=current_user, **params, can_delete=True)
    db.session.add(bookshelf)
    db.session.commit()

    bookshelf = bookshelf.attrs_(add_props=request.add_props, expand=request.expand)
    return jsonify({
        'status': 'ok', 'error': None,
        'bookshelf': bookshelf,
    })


@app.route('/bookshelves', methods=['GET'])
@jwt_required()
def bookshelves_get():
    bookshelves = Bookshelf.query

    id = request.args.get('id', type=int)
    if id != None:
        bookshelves = bookshelves \
            .filter(Bookshelf.id == id)

    book_id = request.args.get('book_id', type=int)
    if book_id != None:
        bookshelves = bookshelves \
            .join(BookBookshelf) \
            .filter(BookBookshelf.book_id == book_id)

    user_id = request.args.get('user_id', type=int)
    if user_id != None:
        bookshelves = bookshelves \
            .filter(Bookshelf.user_id == user_id)

    assert (id or book_id or user_id), \
        "expected query by any/all of `id`, `book_id`, `user_id`"

    total_count = bookshelves.count()
    bookshelves = bookshelves.order_by_request_args()
    page, bookshelves = bookshelves.paginate_by_request_args()
    bookshelves = [r.attrs_(add_props=request.add_props, expand=request.expand)
                   for r in bookshelves]

    return jsonify({
        'status': 'ok', 'error': None,
        'bookshelves': bookshelves,
        'total_count': total_count,
        'page': page,
    })


@app.route('/bookshelf/<bookshelf_id>', methods=['PUT'])
@jwt_required()
def bookshelf_update(bookshelf_id: int):
    bookshelf = Bookshelf.query.get(bookshelf_id)
    assert bookshelf and bookshelf.user_id == current_user.id, \
        f"bookshelf not found with {bookshelf_id=}, user_id={current_user.id}"
    assert bookshelf.can_delete, "cannot modify an essential shelf"

    (params := request.params).pop('can_delete', None)  # disallow setting can_delete
    for key, value in params.items():
        setattr(bookshelf, key, value)
    db.session.commit()

    return jsonify({
        'status': 'ok', 'error': None,
        'bookshelf': bookshelf.attrs,
    })


@app.route('/bookshelf/<int:bookshelf_id>/book/<int:book_id>', methods=['POST', 'DELETE'])
@jwt_required()
def bookshelf_add_or_remove_book(bookshelf_id: int, book_id: int):
    bookshelf: Bookshelf = Bookshelf.query.get(bookshelf_id)
    assert bookshelf and bookshelf.user_id == current_user.id, \
        f"bookshelf not found with {bookshelf_id=}, user_id={current_user.id}"

    if request.method == 'POST':  # def bookshelf_add_book
        bookshelf.add_book(book_id)
    else:  # 'DELETE': def bookshelf_remove_book
        delete_tags = request.args.get('delete_tags',
                                       False, type=util_functions.string_to_bool)
        bookshelf.remove_book(book_id, delete_tags=delete_tags)
    db.session.commit()

    return jsonify({
        'status': 'ok', 'error': None,
        'bookshelf': bookshelf.attrs,
    })


@app.route('/bookshelf/<bookshelf_id>', methods=['DELETE'])
@jwt_required()
def bookshelf_delete(bookshelf_id: int):
    bookshelf = Bookshelf.query.get(bookshelf_id)
    assert bookshelf and bookshelf.user_id == current_user.id, \
        f"bookshelf not found with {bookshelf_id=}, user_id={current_user.id}"
    assert bookshelf.can_delete, "cannot delete an essential shelf"

    db.session.delete(bookshelf)
    db.session.commit()

    return jsonify({
        'status': 'ok', 'error': None,
        'bookshelf': bookshelf.attrs,
    })
