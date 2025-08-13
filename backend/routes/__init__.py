from flask import jsonify
from backend.app import app, jwt, User
from sqlalchemy.exc import SQLAlchemyError
# from botocore.exceptions import ClientError
from werkzeug.exceptions import BadRequest, Forbidden, NotFound, MethodNotAllowed


@app.errorhandler(Exception)
def handle_exception(e):
    app.log_exception(e)
    res = jsonify({'status': 'error', 'error': str(e)})
    if isinstance(e, (BadRequest, KeyError, AssertionError, ValueError)):
        res.status_code = 400
        return res
    elif isinstance(e, SQLAlchemyError):
        e = str(e.__dict__.get('orig') or e)
        res = jsonify({'status': 'error', 'error': e})
        res.status_code = 400
        return res
    # elif isinstance(e, ClientError):
    #     res = jsonify({'status': 'error', 'error': e.response['Error']['Message']})
    #     res.status_code = 400
    #     return res
    elif isinstance(e, Forbidden):
        res.status_code = 403
        return res
    elif isinstance(e, NotFound):
        res.status_code = 404
        return res
    elif isinstance(e, MethodNotAllowed):
        res.status_code = 405
        return res
    else:  # isinstance(e, Exception)
        res.status_code = 500
        return res


@jwt.user_identity_loader
def user_identity_loader(identity):
    return identity


@jwt.user_lookup_loader
def user_lookup_loader(_jwt_header, jwt_data):
    identity = jwt_data["sub"]

    try:
        identity = int(identity)
    except (TypeError, ValueError):  # handles dict and string identities respectively
        return identity

    return User.query.get(identity)


@jwt.user_lookup_error_loader
def user_lookup_error_loader(_jwt_header, jwt_data):
    identity = jwt_data["sub"]

    try:
        identity = int(identity)
    except (TypeError, ValueError):  # handles dict and string identities respectively
        return None

    user = User.query.get(identity)

    if not user:
        error = "unrecognized user"
    else:
        error = "user_loader_callback_loader encountered something unexpected"

    res = jsonify({'status': 'error', 'error': error})
    res.status_code = 401
    return res


@jwt.unauthorized_loader
def unauthorized_loader(_error):
    res = jsonify({'status': 'error', 'error': 'missing token'})
    res.status_code = 401
    return res


@jwt.invalid_token_loader
def invalid_token_loader(_error):
    app.logger.debug(_error)
    res = jsonify({'status': 'error', 'error': 'invalid token'})
    res.status_code = 401
    return res


@jwt.expired_token_loader
def expired_token_loader(_jwt_header, _jwt_data):
    res = jsonify({'status': 'error', 'error': 'token expired'})
    res.status_code = 440
    return res


''' import python module siblings of this file '''
import importlib
from pathlib import Path
for f in Path(__file__).parent.glob("*.py"):
    module_name = f.stem
    if not module_name.startswith("_") and module_name not in globals():
        importlib.import_module(f".{module_name}", __package__)
