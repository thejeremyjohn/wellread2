from flask import jsonify, request
from flask_jwt_extended import jwt_required, current_user
from backend.app import app, db, Review


@app.route('/review', methods=['POST'])
@jwt_required()
def review_create():
    review = Review(user=current_user, **request.params)
    db.session.add(review)
    db.session.commit()

    return jsonify({
        'status': 'ok', 'error': None,
        'review': review.attrs,
    })


@app.route('/reviews', methods=['GET'])
@jwt_required()
def reviews_get():
    reviews = Review.query

    book_id = request.args.get('book_id', type=int)
    if book_id != None:
        reviews = reviews \
            .filter(Review.book_id == book_id)

    user_id = request.args.get('user_id', type=int)
    if user_id != None:
        reviews = reviews \
            .filter(Review.user_id == user_id)

    total_count = reviews.count()
    reviews = reviews.order_by_request_args()
    page, reviews = reviews.paginate_by_request_args()
    reviews = [_.attrs for _ in reviews]

    return jsonify({
        'status': 'ok', 'error': None,
        'reviews': reviews,
        'total_count': total_count,
        'page': page,
    })


@app.route('/review', methods=['PUT'])
@jwt_required()
def review_update():
    review = Review.query.get((
        book_id := request.params.get('book_id', type=int),
        user_id := current_user.id))
    assert review, f"review not found with {book_id=}, {user_id=}"

    for key, value in request.params.items():
        setattr(review, key, value)
    db.session.commit()

    return jsonify({
        'status': 'ok', 'error': None,
        'review': review.attrs,
    })


@app.route('/review', methods=['DELETE'])
@jwt_required()
def review_delete():
    review = Review.query.get((
        book_id := request.params.get('book_id', type=int),
        user_id := current_user.id))
    assert review, f"review not found with {book_id=}, {user_id=}"

    db.session.delete(review)
    db.session.commit()

    return jsonify({
        'status': 'ok', 'error': None,
        'review': review.attrs,
    })
