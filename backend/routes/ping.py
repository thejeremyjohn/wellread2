from flask import jsonify
from flask_jwt_extended import get_jwt_identity, jwt_required
from backend.app import app


@app.route('/', methods=['GET'])
@app.route('/ping', methods=['GET'])
def ping():
    return jsonify({
        'status': 'ok', 'error': None,
        'ping': 'pong',
    })


@app.route('/protected_ping', methods=['GET'])
@jwt_required()
def protected_ping():
    return jsonify({
        'status': 'ok', 'error': None,
        'ping': 'pong',
        'get_jwt_identity': get_jwt_identity(),
    })
