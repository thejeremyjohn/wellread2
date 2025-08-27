import base64
import boto3
import concurrent.futures
import json

from backend.app import app, db
from backend import util_functions
from backend.db_util.custom_base_util import DBModel
from flask import request
from flask_jwt_extended import create_access_token, create_refresh_token, current_user
from sqlalchemy.orm import validates, relationship
from sqlalchemy.sql.functions import func
from uuid import uuid1
from validate_email import validate_email
from werkzeug.security import generate_password_hash, check_password_hash
from werkzeug.datastructures import FileStorage


class CloudfrontMixin():
    @staticmethod
    def generate_presigned_url(s3_path_or_request,
                               cloudfront_url=app.config['CLOUDFRONT_URL_GENERIC'],
                               policy=None,
                               expires_delta={'hours': 6}):
        policy_or_dlt = {"policy": policy} if policy \
            else {'date_less_than': util_functions.some_time_ahead(**expires_delta)}

        return app.config['CLOUDFRONT_SIGNER'].generate_presigned_url(
            f"{cloudfront_url}/{s3_path_or_request}",
            **policy_or_dlt,
        )

    def get_url(self, s3_key, policy=None, params={}):  # of an image
        return CloudfrontMixin.generate_presigned_url(
            self.get_request_path(s3_key, params=params),
            policy=policy,
            cloudfront_url=app.config['CLOUDFRONT_URL']
        )

    def get_request_path(self, s3_key, params={}):
        ''' get request path for Cloudfront image handling '''

        width = params.get('width')
        height = params.get('height')
        fit = params.get('fit', 'cover')
        background = params.get('background', '{"r":0,"g":0,"b":0,"alpha":1}')

        image_request = json.dumps({
            'bucket': app.config['S3_BUCKET'],
            'key': s3_key,
            'edits': {
                'resize': {
                    'withoutEnlargement': True,
                    'width': int(width) if width else None,
                    'height': int(height) if height else None,
                    'fit': fit,
                    'background': json.loads(background)
                }
            }
        }, separators=(',', ':'))

        return base64.b64encode(image_request.encode()).decode()

    def invalidate_cached_versions(self, s3_key):
        cloudfront = boto3.client('cloudfront')

        def invalidate(path, distribution_id):
            res = cloudfront.create_invalidation(
                DistributionId=distribution_id,
                InvalidationBatch={
                    'Paths': {'Quantity': 1, 'Items': [path]},
                    'CallerReference': str(util_functions.datetime_now_utc().timestamp()),
                }
            )
            assert 200 <= res['ResponseMetadata']['HTTPStatusCode'] <= 299, \
                "something went wrong with Cloudfront CreateInvalidation"

        with concurrent.futures.ThreadPoolExecutor() as executor:
            executor.submit(
                invalidate,
                f"/{s3_key}",
                app.config['CLOUDFRONT_DISTRIBUTION_ID'],
            )
            executor.submit(
                invalidate,
                f"/{self.get_request_path(s3_key)[:150]}*",  # catches requests w/ different params
                app.config['CLOUDFRONT_DISTRIBUTION_ID_IMAGE_HANDLING'],
            )

    def get_mimetype_agnostic_url(self, s3_key,
                                  policy=None,
                                  cloudfront_url=app.config['CLOUDFRONT_URL_GENERIC'],
                                  params={}):  # TODO why passing params?
        return CloudfrontMixin.generate_presigned_url(
            s3_key,
            policy=policy,
            cloudfront_url=cloudfront_url,
        )

    def s3_head_object(self, s3_key):
        res = boto3.client('s3').head_object(
            Bucket=app.config['S3_BUCKET'],
            Key=s3_key,
        )
        assert 200 <= res['ResponseMetadata']['HTTPStatusCode'] <= 299, \
            "something went wrong with S3 HeadObject"
        return res

    def get_url_s3(self, s3_key, ttl=3600):
        return boto3.client('s3').generate_presigned_url(
            ClientMethod='get_object',
            Params={'Bucket': app.config['S3_BUCKET'],
                    'Key': s3_key,
                    },
            ExpiresIn=ttl,
        )

    def upload_to_s3(self, file: FileStorage, s3_key: str,
                     content_type=None, content_disposition='', metadata={}):
        res = boto3.client('s3').put_object(
            Body=file,
            Bucket=app.config['S3_BUCKET'],
            Key=s3_key,
            ContentType=content_type or file.content_type,
            **({'ContentDisposition': content_disposition} if content_disposition else {}),
            Metadata=metadata,
        )
        assert 200 <= res['ResponseMetadata']['HTTPStatusCode'] <= 299, \
            "something went wrong with S3 PutObject"

    def delete_from_s3(self, s3_key):
        res = boto3.client('s3').delete_object(
            Bucket=app.config['S3_BUCKET'],
            Key=s3_key,
        )
        assert 200 <= res['ResponseMetadata']['HTTPStatusCode'] <= 299, \
            "something went wrong with S3 DeleteObject"

    def copy_within_s3(self, source_s3_key, target_s3_key):
        boto3.client('s3').copy(
            {
                'Bucket': app.config['S3_BUCKET'],
                'Key': source_s3_key,
            },
            Bucket=app.config['S3_BUCKET'],
            Key=target_s3_key,
        )


class Book(DBModel):
    __tablename__ = 'books'

    def attrs_(self, expand=[], add_props=[]):
        attrs = super().attrs_(expand=expand, add_props=add_props)
        images = [image.attrs for image in self.images]
        return {
            **attrs,
            'images': images,
        }
    attrs = property(attrs_)

    def images():
        def fget(self):
            return (
                BookImage.query
                .join(Book)
                .filter(Book.id == self.id)
                .order_by(BookImage.index)
            )

        def fset(self, value: list):
            for index, book_image in enumerate(value):
                book_image.index = index
            self.book_images = value
        return locals()
    images = property(**images())

    @property
    def reviews_(self):  # for add_props
        return [r.attrs for r in self.reviews]

    @property
    def n_reviews(self):  # for add_props
        return (Review.query
                .filter(Review.book_id == self.id,
                        Review.content != None)
                .count())

    @property
    def n_ratings(self):  # for add_props
        return (Review.query
                .filter(Review.book_id == self.id)
                .count())

    @property
    def avg_rating(self):  # for add_props
        return (Review.query
                .filter(Review.book_id == self.id)
                .with_entities(zero_if_null(
                    db.func.avg(Review.rating).cast(db.DOUBLE_PRECISION)
                )).scalar())

    @property
    def my_review(self):  # for add_props
        ''' current_user's review of this book '''
        if not request:
            raise Exception('cannot get `my_rating` outside of request context')
        review = (Review.query
                  .filter(Review.book_id == self.id,
                          Review.user_id == current_user.id)
                  .one_or_none())
        return review.attrs if review else None

    @property
    def my_rating(self):  # for add_props
        ''' current_user's review.rating of this book '''
        if not request:
            raise Exception('cannot get `my_rating` outside of request context')
        review = self.my_review
        return review['rating'] if review else 0

    _shelves = relationship(
        'Bookshelf',
        secondary='books_bookshelves',
        lazy='dynamic',
        overlaps='book,book_bookshelves,bookshelf',  # to silence SAWarning
        back_populates='_books',
    )

    @property
    def shelves(self):  # for add_props
        return [b.attrs for b in self._shelves]

    @property
    def my_shelves(self):  # for add_props
        ''' current_user's shelves of this book '''
        if not request:
            raise Exception('cannot get `my_shelves` outside of request context')
        return [b.attrs for b in self._shelves.filter(Bookshelf.user_id == current_user.id)]


class BookImage(DBModel, CloudfrontMixin):
    __tablename__ = 'book_images'

    def __init__(self, *args, **kwargs):
        self.uuid = kwargs.get('uuid', str(uuid1()))
        super().__init__(*args, **kwargs)

    def attrs_(self):
        return {
            'uuid': self.uuid,
            'url': self.get_url(params={'width': 512}),
        }
    attrs = property(attrs_)

    @property
    def s3_key(self):
        return f"{self.uuid}{self.file_extension}"

    def upload_to_s3(self, *args, **kwargs):
        return super().upload_to_s3(*args, **kwargs, s3_key=self.s3_key)

    def delete_from_s3(self, *args, **kwargs):
        return super().delete_from_s3(*args, **kwargs, s3_key=self.s3_key)

    def get_url(self, *args, **kwargs):
        return super().get_url(*args, **kwargs, s3_key=self.s3_key)

    def get_mimetype_agnostic_url(self, *args, **kwargs):
        return super().get_mimetype_agnostic_url(*args, **kwargs, s3_key=self.s3_key)


class BookBookshelf(DBModel):
    __tablename__ = 'books_bookshelves'


class Bookshelf(DBModel):
    __tablename__ = 'bookshelves'

    ESSENTIALS = ['want to read', 'currently reading', 'read']

    def attrs_(self, expand=[], add_props=[]):
        attrs = super().attrs_(expand=expand, add_props=add_props)
        attrs.pop('can_delete')  # cannot set -> no need to show
        return attrs
    attrs = property(attrs_)

    _books = relationship(
        'Book',
        secondary='books_bookshelves',
        lazy='dynamic',
        overlaps='book,book_bookshelves,bookshelf',  # to silence SAWarning
        back_populates='_shelves',
    )

    @property
    def books(self):  # for add_props
        return [b.attrs for b in self._books]

    @property
    def n_books(self):  # for add_props
        return self._books.count()


class Review(DBModel):
    __tablename__ = 'reviews'

    def attrs_(self, expand=[], add_props=[]):
        return super().attrs_(expand=expand, add_props=add_props)
    attrs = property(attrs_)

    @property
    def shelves(self):  # for add_props
        bookshelves = (
            Bookshelf.query
            .join(BookBookshelf)
            .join(Review, db.and_(Review.book_id == BookBookshelf.book_id,
                                  Review.user_id == Bookshelf.user_id))
            .filter(Review.book_id == self.book_id, Review.user_id == self.user_id,
                    Bookshelf.name.notin_(Bookshelf.ESSENTIALS))
        )
        return [b.attrs for b in bookshelves]

    @property
    def tags(self):  # for add_props
        return self.shelves

    @property
    def user_(self):  # for add_props
        ''' special-case alternative to expand=user '''
        u: User = self.user
        return {
            **u.attrs,
            'n_reviews': u.n_reviews,
        }


class User(DBModel):
    __tablename__ = 'users'

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.bookshelves = [Bookshelf(name=name, can_delete=False)
                            for name in Bookshelf.ESSENTIALS]

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

    def create_access_token(self, **kwargs):
        return create_access_token(identity=str(self.id), **kwargs)

    def create_refresh_token(self, **kwargs):
        return create_refresh_token(identity=str(self.id), **kwargs)

    @property
    def bookshelves_(self):   # for add_props
        return [b.attrs for b in self.bookshelves]

    @property
    def n_reviews(self):  # for add_props
        return (Review.query
                .filter(Review.user_id == self.id,
                        Review.content != None)
                .count())


def zero_if_null(n):
    return db.case((n == None, 0), else_=n)
