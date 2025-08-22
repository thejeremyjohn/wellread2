from flask import Request
from werkzeug.datastructures.structures import TypeConversionDict


class CustomDict(TypeConversionDict):
    def __getitem__(self, key):
        try:
            return super().__getitem__(key)
        except KeyError:
            raise CustomKeyError(f"missing '{key}'")


class CustomKeyError(KeyError, Exception):
    def __str__(self, *args):
        return Exception.__str__(self, *args)


class CustomRequest(Request):
    def params_(self, nullable=True) -> CustomDict:
        params = CustomDict(self.is_json and self.json or self.form or {})
        if not nullable:
            assert params, f"expected json or form data, got {params}"
        return params
    params = property(params_)

    def add_props_(self, default=''):
        return self.args.get('add_props', default).split(',')
    add_props = property(add_props_)

    def expand_(self, default=''):
        return self.args.get('expand', default).split(',')
    expand = property(expand_)
