from flask import request, jsonify
from flask_jwt_extended import jwt_required, current_user
from backend.app import app, db, User, Bookshelf


@app.route('/signup', methods=['POST'])
def signup():
    user = User(**request.params)
    user.bookshelves = [
        Bookshelf(name='want to read', can_delete=False),
        Bookshelf(name='currently reading', can_delete=False),
        Bookshelf(name='read', can_delete=False),
    ]
    db.session.add(user)
    db.session.commit()

    return jsonify({
        'status': 'ok', 'error': None,
        'user': user.attrs_(add_props=request.add_props, expand=request.expand),
    })


@app.route('/login', methods=['POST'])
def login():
    access_token, refresh_token = None, None

    user = User.find_by_credentials(**request.params)
    assert user, 'invalid email or password'

    access_token = user.create_access_token()
    refresh_token = user.create_refresh_token()

    return jsonify({
        'status': 'ok', 'error': None,
        'access_token': access_token,
        'refresh_token': refresh_token,
        'user': user.attrs_(add_props=request.add_props, expand=request.expand),
    })


@app.route('/login_refresh', methods=['POST', 'GET'])
@jwt_required(refresh=True)
def login_refresh():
    access_token = current_user.create_access_token()

    return jsonify({
        'status': 'ok', 'error': None,
        'access_token': access_token,
        'user': current_user.attrs_(add_props=request.add_props, expand=request.expand),
    })
