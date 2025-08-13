import os
from flask import jsonify, request
from flask_jwt_extended import jwt_required
from werkzeug.datastructures import FileStorage
from backend import util_functions
from backend.app import app, db, Book, BookImage


def assert_image(file: FileStorage):
    assert file.content_type.startswith('image'), \
        f"expected a file content_type like 'image/<subtype>', got '{file.content_type}'"


@app.route('/book/<book_id>/image', methods=['POST'])
@jwt_required()
def book_image_create(book_id: int):
    assert request.files, "expected multipart form with file"
    file = request.files.values().__next__()
    assert_image(file)

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
        book_image = book.images.filter(BookImage.uuid == uuid).first()
        assert book_image, f"invalid 'uuid' {uuid}"
        book_image.index = index
    db.session.commit()

    return jsonify({
        'status': 'ok', 'error': None,
    })


# @app.route('/book_image/<image_uuid>/delete', methods=['DELETE'])
# @jwt_required()
# def image_delete(image_uuid):
#     book_image = current_user.images.filter_by(uuid=image_uuid).first()
#     assert book_image, f"invalid or unauthorized 'image_uuid' {image_uuid}"

#     book_image.delete()
#     db.session.commit()

#     return jsonify({
#         'status': 'ok', 'error': None,
#         'book_image': book_image.attrs,
#     })
