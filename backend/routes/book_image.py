import os
from flask import jsonify, request
from flask_jwt_extended import jwt_required
from backend import util_functions
from backend.app import app, db, Book, BookImage


@app.route('/book/<book_id>/image', methods=['POST'])
@jwt_required()
def book_image_create(book_id: int):
    assert request.files, "expected multipart form with file"
    file = request.files.values().__next__()
    util_functions.assert_image(file)

    book_image_ = BookImage(
        file_extension=os.path.splitext(file.filename)[-1],
        book_id=book_id,
    )
    book_image_.upload_to_s3(file)
    db.session.add(book_image_)
    db.session.commit()

    return jsonify({
        'status': 'ok', 'error': None,
        'book_image': book_image_.attrs,
    })


@app.route('/book/<book_id>/images', methods=['PUT'])
@jwt_required()
def book_images_reorder(book_id: int):
    uuids = util_functions.ensure_list(
        request.params['uuids'],
        key_name='uuids',
    )
    book = Book.query.get(book_id)

    assert len(uuids) == book.images.count(), \
        "length of uuids must match count of book's images"

    for index, uuid in enumerate(uuids):
        book_image: BookImage = book.images.filter(BookImage.uuid == uuid).first()
        assert book_image, f"invalid 'uuid' {uuid}"
        book_image.index = index
    db.session.commit()

    return jsonify({
        'status': 'ok', 'error': None,
    })


@app.route('/book/<book_id>/images', methods=['DELETE'])
@jwt_required()
def book_images_delete(book_id: int):
    uuids = util_functions.ensure_list(
        request.params['uuids'],
        key_name='uuids',
    )
    book = Book.query.get(book_id)

    for uuid in uuids:
        book_image: BookImage = book.images.filter(BookImage.uuid == uuid).first()
        assert book_image, f"invalid 'uuid' {uuid}"
        book_image.delete_from_s3()
        db.session.delete(book_image)
    db.session.commit()

    return jsonify({
        'status': 'ok', 'error': None,
    })
