import base64
# import boto3
import concurrent.futures
import json
# import util

from app import app
from custom_base_util import DBModel
from flask import request
# from flask_jwt_extended import create_access_token, create_refresh_token
from sqlalchemy.orm import validates
from uuid import uuid1
from validate_email import validate_email
from werkzeug.security import generate_password_hash, check_password_hash


# TODO
# class CloudfrontMixin():
#     @staticmethod
#     def generate_presigned_url(s3_path_or_request,
#                                cloudfront_url=app.config['CLOUDFRONT_URL'],
#                                policy=None,
#                                expires_delta={'hours': 6}):
#         policy_or_dlt = {"policy": policy} if policy \
#             else {'date_less_than': util.some_time_ahead(**expires_delta)}

#         return app.config['CLOUDFRONT_SIGNER'].generate_presigned_url(
#             f"{cloudfront_url}/{s3_path_or_request}",
#             **policy_or_dlt,
#         )

#     def get_url(self, s3_key, policy=None, params={}):  # of an image
#         return CloudfrontMixin.generate_presigned_url(
#             self.get_request_path(s3_key, params=params),
#             policy=policy,
#             cloudfront_url=app.config['CLOUDFRONT_URL']
#         )

#     def get_mimetype_agnostic_url(self, s3_key,
#                                   policy=None,
#                                   cloudfront_url=app.config['CLOUDFRONT_URL_GENERIC']):
#         return CloudfrontMixin.generate_presigned_url(
#             s3_key,
#             policy=policy,
#             cloudfront_url=cloudfront_url,
#         )

#     def get_request_path(self, s3_key, params={}):
#         ''' get request path for Cloudfront image handling '''

#         width = params.get('width')
#         height = params.get('height')
#         fit = params.get('fit', 'cover')
#         background = params.get('background', '{"r":0,"g":0,"b":0,"alpha":1}')

#         image_request = json.dumps({
#             'bucket': app.config['S3_BUCKET'],
#             'key': s3_key,
#             'edits': {
#                 'resize': {
#                     'withoutEnlargement': True,
#                     'width': int(width) if width else None,
#                     'height': int(height) if height else None,
#                     'fit': fit,
#                     'background': json.loads(background)
#                 }
#             }
#         }, separators=(',', ':'))

#         return base64.b64encode(image_request.encode()).decode()

#     def invalidate_cached_versions(self, s3_key):
#         cloudfront = boto3.client('cloudfront')

#         def invalidate(path, distribution_id):
#             res = cloudfront.create_invalidation(
#                 DistributionId=distribution_id,
#                 InvalidationBatch={
#                     'Paths': {'Quantity': 1, 'Items': [path]},
#                     'CallerReference': str(util.datetime_now_utc().timestamp()),
#                 }
#             )
#             assert 200 <= res['ResponseMetadata']['HTTPStatusCode'] <= 299, \
#                 "something went wrong with Cloudfront CreateInvalidation"

#         with concurrent.futures.ThreadPoolExecutor() as executor:
#             executor.submit(
#                 invalidate,
#                 f"/{s3_key}",
#                 app.config['CLOUDFRONT_DISTRIBUTION_ID'],
#             )
#             executor.submit(
#                 invalidate,
#                 f"/{self.get_request_path(s3_key)[:150]}*",  # catches requests w/ different params
#                 app.config['CLOUDFRONT_DISTRIBUTION_ID_IMAGE_HANDLING'],
#             )

#     def s3_head_object(self, s3_key):
#         res = boto3.client('s3').head_object(
#             Bucket=app.config['S3_BUCKET'],
#             Key=s3_key,
#         )
#         assert 200 <= res['ResponseMetadata']['HTTPStatusCode'] <= 299, \
#             "something went wrong with S3 HeadObject"
#         return res

#     def get_url_s3(self, s3_key, ttl=3600):
#         return boto3.client('s3').generate_presigned_url(
#             ClientMethod='get_object',
#             Params={'Bucket': app.config['S3_BUCKET'],
#                     'Key': s3_key,
#                     },
#             ExpiresIn=ttl,
#         )

#     def upload_to_s3(self, file, s3_key, content_type=None, metadata={}):
#         res = boto3.client('s3').put_object(
#             Body=file,
#             Bucket=app.config['S3_BUCKET'],
#             Key=s3_key,
#             ContentType=content_type or file.content_type,
#             Metadata=metadata,
#         )
#         assert 200 <= res['ResponseMetadata']['HTTPStatusCode'] <= 299, \
#             "something went wrong with S3 PutObject"

#     def delete_from_s3(self, s3_key):
#         res = boto3.client('s3').delete_object(
#             Bucket=app.config['S3_BUCKET'],
#             Key=s3_key,
#         )
#         assert 200 <= res['ResponseMetadata']['HTTPStatusCode'] <= 299, \
#             "something went wrong with S3 DeleteObject"

#     def copy_within_s3(self, source_s3_key, target_s3_key):
#         boto3.client('s3').copy(
#             {
#                 'Bucket': app.config['S3_BUCKET'],
#                 'Key': source_s3_key,
#             },
#             Bucket=app.config['S3_BUCKET'],
#             Key=target_s3_key,
#         )


class Book(DBModel):
    __tablename__ = 'books'

    def images():
        def fget(self):
            return self.book_images

        def fset(self, value: list):
            for index, book_image in enumerate(value):
                book_image.index = index
            self.book_images = value
        return locals()
    images = property(**images())


class User(DBModel):
    __tablename__ = 'users'

    def attrs_(self, *args, **kwargs):
        attrs = super().attrs_(*args, **kwargs)
        attrs.pop('password_hash', None)
        return attrs
    attrs = property(attrs_)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

    @classmethod
    def find_by_credentials(cls, email, password):
        user = (
            User.query
            .filter(User.email.ilike(email.strip()))
            .one_or_none()
        )
        return user if (user and user.check_password(password)) else None

    @validates('email')
    def validate_email(self, key, value):
        value = value.strip()
        assert validate_email(value), "invalid 'email'"
        return value

    def password():
        def fget(self):
            pass

        def fset(self, value):
            assert len(value) >= 6, "password must be at least 6 characters"
            self.password_hash = generate_password_hash(value)
        return locals()
    password = property(**password())

    # TODO
    # def create_access_token(self, **kwargs):
    #     return create_access_token(identity=self.id, **kwargs)

    # def create_refresh_token(self, **kwargs):
    #     return create_refresh_token(identity=self.id, **kwargs)
