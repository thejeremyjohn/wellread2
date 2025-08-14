import json
import pytz
from datetime import datetime, timedelta
from werkzeug.datastructures import FileStorage


def string_to_bool(string, default=None) -> bool:
    if string in {'true', '1', True}:
        return True
    elif string in {'false', '0', False}:
        return False
    else:
        if default == None:
            raise ValueError(f"expected true|1|false|0, got {string}")
        return default


def datetime_now_utc():
    return datetime.now(pytz.utc)


def some_time_ago(**delta):
    return datetime_now_utc() - timedelta(**delta)


def some_time_ahead(**delta):
    return datetime_now_utc() + timedelta(**delta)


# TODO improve
def ensure_list(list_or_string, key_name, non_empty=True, item_type='string', delimiter=None):
    if isinstance(list_or_string, str) and list_or_string != None:
        try:
            list_or_string = json.loads(list_or_string)
        except:
            list_or_string = list_or_string.split(delimiter)
    list_ = list_or_string or []

    if isinstance(list_, int):
        list_ = [list_]

    assert isinstance(list_, list) and (bool(list_) if non_empty else True), (
        f"expected '{key_name}' to be{' non-empty' if non_empty else ''} "
        f"array of {item_type}(s) "
        f"OR a {'space' if delimiter == None else delimiter}-delimited list, "
        f"got {list_}"
    )

    return list_


def assert_image(file: FileStorage):
    assert file.content_type.startswith('image'), \
        f"expected a file content_type like 'image/<subtype>', got '{file.content_type}'"
