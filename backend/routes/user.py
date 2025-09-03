from flask import request, jsonify
from flask_jwt_extended import jwt_required, current_user
from backend.app import app, db, User, PendingUserVerification


@app.route('/signup', methods=['POST'])
def signup():
    user = User(**request.params)
    db.session.add(user)
    db.session.commit()

    _send_verification_email(user)

    # raise Exception('oh no')
    return jsonify({
        'status': 'ok', 'error': None,
        'user': user.attrs_(add_props=request.add_props, expand=request.expand),
    })


def _send_verification_email(user: User):
    pending_user_verification = PendingUserVerification(user=user)
    db.session.add(pending_user_verification)
    db.session.commit()

    pending_user_verification.user.receive_email(
        'Verify your email w/ wellread',
        text_body=f'''
            Glad you could join us. Click the link below to verify:
            http://localhost:8000/verify?token={pending_user_verification.token}
        '''.strip()
    )


@app.route('/verify/<token>', methods=['GET', 'POST'])
def verify(token: str):
    pending_user_verification = PendingUserVerification.query.get(token)
    assert pending_user_verification, 'invalid verification token'

    user = pending_user_verification.user
    access_token = user.create_access_token()
    refresh_token = user.create_refresh_token()

    for pending in (PendingUserVerification.query
                    .filter_by(user_id=pending_user_verification.user_id)):
        db.session.delete(pending)
    db.session.commit()

    return jsonify({
        'status': 'ok', 'error': None,
        'access_token': access_token,
        'refresh_token': refresh_token,
        'user': user.attrs_(add_props=request.add_props, expand=request.expand),
    })


@app.route('/login', methods=['POST'])
def login():
    user = User.find_by_credentials(**request.params)
    assert user, 'invalid email or password'

    if user.verified:
        access_token = user.create_access_token()
        refresh_token = user.create_refresh_token()
    else:
        access_token, refresh_token = None, None
        _send_verification_email(user)

    return jsonify({
        'status': 'ok', 'error': None,
        'access_token': access_token,
        'refresh_token': refresh_token,
        'user': user.attrs_(add_props=request.add_props, expand=request.expand),
    })


@app.route('/login_refresh', methods=['POST', 'GET'])
@jwt_required(refresh=True)
def login_refresh():
    access_token = None
    if current_user.verified:
        access_token = current_user.create_access_token()

    return jsonify({
        'status': 'ok', 'error': None,
        'access_token': access_token,
        'user': current_user.attrs_(add_props=request.add_props, expand=request.expand),
    })
