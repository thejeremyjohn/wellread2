import os
import re
import sys
from flask import Flask
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from flask_jwt_extended import JWTManager
from datetime import timedelta
from dotenv import load_dotenv; load_dotenv()
from backend.db_util.custom_base_util import Base, BaseQuery, singular_camel_classname, plural_snakecase_collection
from backend.custom_request import Request

# import smart_open
import base64
from botocore.signers import CloudFrontSigner
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding


def mk_cloudfront_signer(key_id='', key_file_path=''):
    key_id = key_id or os.environ['CLOUDFRONT_KEY_ID']

    if key_file_path:
        # with smart_open.smart_open(key_file_path, 'rb') as f:
        #     pem_private_key = f.read()
        raise NotImplementedError('mk_cloudfront_signer >> key_file_path -> ...')
    else:
        pem_private_key = base64.b64decode(os.environ['CLOUDFRONT_KEY_B64'].encode())

    private_key = serialization.load_pem_private_key(
        pem_private_key,
        password=None,
        backend=default_backend()
    )

    def rsa_signer(message):
        return private_key.sign(message, padding.PKCS1v15(), hashes.SHA1())

    return CloudFrontSigner(key_id, rsa_signer)


app = Flask(__name__)
app.request_class = Request
app.config['JWT_SECRET_KEY'] = os.environ['JWT_SECRET_KEY']
app.config['JWT_ACCESS_TOKEN_EXPIRES'] = timedelta(days=1)  # default minutes=15
# app.config['JWT_REFRESH_TOKEN_EXPIRES'] = timedelta(days=30)
app.config['SQLALCHEMY_DATABASE_URI'] = ('postgresql+psycopg://'
                                         + os.environ['SQL_DB_USER']
                                         + ':' + os.environ['SQL_DB_PASSWORD']
                                         + '@' + os.environ['SQL_DB_HOST']
                                         + ':' + os.environ['SQL_DB_PORT']
                                         + '/' + os.environ['SQL_DB_NAME'])
app.config['S3_BUCKET'] = 'wellread2'
app.config['CLOUDFRONT_URL'] = 'https://d2wq77xunqif9i.cloudfront.net'
app.config['CLOUDFRONT_DISTRIBUTION_ID'] = 'E3LQF93MJV6OVM'
app.config['CLOUDFRONT_URL_GENERIC'] = 'https://d1nvc7nzk5ttp8.cloudfront.net'
app.config['CLOUDFRONT_DISTRIBUTION_ID_GENERIC'] = 'E2CMUYDH5LNP77'
app.config['CLOUDFRONT_SIGNER'] = mk_cloudfront_signer()

cors = CORS(app, resources={r"/*": {"origins": "*"}})  # NB for local development ONLY
db = SQLAlchemy(app,
                query_class=BaseQuery,
                model_class=Base,
                add_models_to_shell=True)
migrate = Migrate(app, db, directory='db_util/migrations')
jwt = JWTManager(app)

if not re.search('flask db (down|up)grade', ' '.join(sys.argv)):  # if not performing db migration
    from backend.db_util.models import *  # then it is safe load models of potentially unmapped tables
    from backend.routes import *  # as well as routes that may depend on them

with app.app_context():
    Base.prepare(
        autoload_with=db.engine,
        classname_for_table=singular_camel_classname,
        name_for_collection_relationship=plural_snakecase_collection,
    )


app.logger.info('server running...')
