import inflect
import re
import sqlparse
from flask import request
from flask_sqlalchemy.query import Query
from sqlalchemy import asc, desc
from sqlalchemy.inspection import inspect
from sqlalchemy.orm import validates
from sqlalchemy.sql.functions import func
from sqlalchemy.dialects import postgresql
from sqlalchemy.ext.automap import AutomapBase, automap_base
from backend import util_functions

Base: AutomapBase = automap_base()


class DBModel(Base):
    __abstract__ = True

    def __init__(self, *args, **kwargs):
        assert not kwargs.get('id'), "'id' cannot be manually set"
        # assert not kwargs.get('uuid'), "'uuid' cannot be manually set" # TODO reapply
        super().__init__(*args, **kwargs)

    def attrs_(self, expand=[], adhoc_expandables={}, add_props=[]):
        attrs = {c.name: getattr(self, c.name) for c in self.__table__.columns}  # json serializable
        expandables = self.get_expandables(adhoc_expandables=adhoc_expandables)

        for expansions in [e.split('.') for e in expand if e]:
            assert len(expansions) <= 4, "expansions have a max depth of 4 levels"
            e = expansions.pop(0)
            assert e in expandables, f"{e} is not a valid expandable for {self.__tablename__}"

            attrs.pop(expandables[e], None)  # remove this foreign key property, e.g. user_id
            thing = self.__getattribute__(e)  # get the thing that was ref'd by that fkey, e.g. user
            attrs[e] = thing.attrs_(expand=['.'.join(expansions)]) if thing else None

        for prop in add_props:
            if prop:
                try:
                    attrs[prop] = self.__getattribute__(prop)
                except AttributeError:
                    if '.' in prop:  # a nested add_prop like "review.book"
                        prop = prop.split('.')
                        assert len(prop) == 2, "nested add_props have a max depth of 2 levels"
                        a, b = prop
                        if isinstance(attrs[a], dict):
                            attrs[a][b] = self.__getattribute__(a).__getattribute__(b)
                    else:
                        raise
        return attrs
    attrs = property(attrs_)

    @validates('id', 'uuid')
    def validate_id_or_uuid(self, key, value):
        if request:  # ensure validation does not apply in flask shell
            old_value = getattr(self, key)
            assert old_value in {None, value}, f"'{key}' cannot be updated"
        return value

    def get_expandables(self, adhoc_expandables={}):
        expandables = dict()
        for column in self.__table__.get_children():
            if column.foreign_keys:
                try:
                    thing, id = column.description.rsplit('_', 1)  # e.g. "experience", "uuid"
                except ValueError:  # not enough values to unpack (expected 2, got 1)
                    continue  # skip
                if getattr(type(self), thing, None):  # if the model has this InstrumentedAttribute
                    expandables[thing] = column.description
        return {**expandables, **adhoc_expandables}

    @classmethod
    def upsert(self, lookups: dict, _echo=False, **updates) -> tuple:
        '''
        Insert a record which may already exist. If it does, update it.

        Example usage:
            j, = Asset.upsert({'uuid': x}, description=y, name=z)
            _, _ = UserAsset.upsert({'user_id': i 'asset_id': j}, stripe_invoice_id=k)
        '''
        upsert_stmt = (postgresql.insert(self.__table__)
                       .values(**lookups, **updates)
                       .on_conflict_do_update(index_elements=lookups.keys(), set_=updates)
                       .returning(*inspect(self).primary_key))
        if _echo:
            print(upsert_stmt.compile(dialect=postgresql.dialect()))
        return self.query.session.execute(upsert_stmt).fetchone()


class BaseQuery(Query):
    def random(self):
        return self.order_by(func.random()).first()

    @property
    def sql(self):
        statement = self.statement.compile(
            compile_kwargs={'literal_binds': True},
            dialect=postgresql.dialect(),
        )
        return sqlparse.format(str(statement), reindent=True)

    def order_by_request_args(self):
        order_by = request.args.get('order_by', 'created')
        reverse = request.args.get('reverse', False, type=util_functions.string_to_bool)
        asc_or_desc = desc if reverse else asc  # ascending or descending
        first_entity = self.column_descriptions[0]['entity']  # e.g. Asset
        property = getattr(first_entity, order_by)  # e.g. Asset.created

        return self.order_by(asc_or_desc(property))

    def paginate_by_request_args(self):
        # TODO
        # items_per_page = request.args.get('per_page', app.config['ITEMS_PER_PAGE'], type=int)
        # items_per_page = min(items_per_page, app.config['ITEMS_MAX_PER_PAGE'])
        items_per_page = request.args.get('per_page', 20, type=int)
        items_per_page = min(items_per_page, 100)
        max_page = self.paginate(page=1, per_page=items_per_page).pages or 1
        page = request.args.get('page', max_page, type=int)
        items = self.paginate(page=page, per_page=items_per_page, error_out=False).items

        return page, items


inflection = inflect.engine()  # XXX slow


def singular_camel_classname(base, tablename, table):
    ''' (tablename) books_bookshelves -> (classname) BookBookshelf '''
    return ''.join(inflection.singular_noun(w) or w
                   for w in tablename.title().split('_'))


# TODO test on long underscored string
def plural_snakecase_collection(base, local_cls, referred_cls, constraint):
    ''' (classname) Review -> (collectionname) reviews '''
    return inflection.plural(re.sub(
        r"[A-Z]",
        lambda m: "_%s" % m.group(0).lower(),
        referred_cls.__name__,
    )[1:])
