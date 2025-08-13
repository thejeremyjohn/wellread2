from flask import Request


class Request(Request):
    def params_(self, nullable=True):
        params = self.is_json and self.json or self.form
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
