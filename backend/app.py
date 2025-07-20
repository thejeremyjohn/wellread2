import os
import re
import sys
from flask import Flask, Request, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
# from flask_jwt_extended import JWTManager # TODO
from dotenv import load_dotenv; load_dotenv()
from werkzeug.exceptions import BadRequest, MethodNotAllowed, NotFound
from custom_base_util import Base, BaseQuery, singular_camel_classname, plural_snakecase_collection


class Request(Request):
    def params_(self, nullable=True):
        params = self.is_json and self.json or self.form
        if not nullable:
            assert params, f"expected json or form data, got {params}"
        return params
    params = property(params_)


app = Flask(__name__)
app.request_class = Request
app.config['SQLALCHEMY_DATABASE_URI'] = ('postgresql+psycopg://'
                                         + os.environ['SQL_DB_USER']
                                         + ':' + os.environ['SQL_DB_PASSWORD']
                                         + '@' + os.environ['SQL_DB_HOST']
                                         + ':' + os.environ['SQL_DB_PORT']
                                         + '/' + os.environ['SQL_DB_NAME'])
db = SQLAlchemy(app,
                query_class=BaseQuery,
                model_class=Base,
                add_models_to_shell=True)
migrate = Migrate(app, db)
# jwt = JWTManager(app) # TODO

# TODO import routes

if not re.search('flask db (down|up)grade', ' '.join(sys.argv)):  # if not performing db migration
    from models import *  # then it is safe load models of potentially unmapped tables

with app.app_context():
    Base.prepare(
        autoload_with=db.engine,
        classname_for_table=singular_camel_classname,
        name_for_collection_relationship=plural_snakecase_collection,
    )


@app.errorhandler(Exception)
def handle_exception(e):
    app.log_exception(e)
    res = jsonify({'message': str(e)})
    if isinstance(e, (BadRequest, KeyError, AssertionError, ValueError)):
        res.status_code = 400
        return res
    elif isinstance(e, NotFound):
        res.status_code = 404
        return res
    elif isinstance(e, MethodNotAllowed):
        res.status_code = 405
        return res
    else:  # isinstance(err, Exception)
        res.status_code = 500
        return res


app.logger.info('server running...')
