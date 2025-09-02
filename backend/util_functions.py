import boto3
import json
import os
import pytz
from datetime import datetime, timedelta
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.application import MIMEApplication
from html2text import html2text
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


def send_raw_email(to_addresses, subject, html_body='', text_body='', headers={}, attachments=[],
                   from_address='', subject_prefix='', subject_suffix='',
                   bcc_addresses=[], configuration_set_name='', tags={}):

    msg = MIMEMultipart('mixed')
    msg['Subject'] = f"{subject_prefix}{subject}{subject_suffix}"
    msg['From'] = from_address
    msg['To'] = ', '.join(to_addresses)
    if bcc_addresses:
        msg['Bcc'] = ', '.join(bcc_addresses)

    msg_body = MIMEMultipart('alternative')
    text_body = text_body or html2text(html_body)
    msg_body.attach(MIMEText(text_body, 'plain'))
    if html_body:
        msg_body.attach(MIMEText(html_body, 'html'))
    msg.attach(msg_body)

    for key, value in headers.items():
        msg.add_header(str(key), str(value))

    for file in attachments:
        if isinstance(file, FileStorage):
            file.seek(0)
            att = MIMEApplication(file.read())
            filename = os.path.basename(file.filename)
        else:
            with open(file, 'rb') as f:
                att = MIMEApplication(f.read())
                filename = os.path.basename(file)
        att.add_header('Content-Disposition', 'attachment', filename=filename)
        msg.attach(att)

    res = boto3.client('ses').send_raw_email(
        Source=msg['From'],
        Destinations=to_addresses + bcc_addresses,
        RawMessage={'Data': msg.as_string()},
        ConfigurationSetName=configuration_set_name,
        Tags=[{'Name': name, 'Value': value} for name, value in tags.items()],
    )
    assert 200 <= res['ResponseMetadata']['HTTPStatusCode'] <= 299, \
        "something went wrong with SES SendRawEmail"

    return res
