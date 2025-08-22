"""bookshelf unique name and user

Revision ID: c99270f4b105
Revises: ec485e142265
Create Date: 2025-08-22 13:03:36.468253

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'c99270f4b105'
down_revision = 'ec485e142265'
branch_labels = None
depends_on = None


def upgrade():
    op.get_bind().execute(sa.text('''
        ALTER TABLE bookshelves
            ADD UNIQUE (name, user_id);
    '''))


def downgrade():
    op.get_bind().execute(sa.text('''
        ALTER TABLE bookshelves
            DROP CONSTRAINT bookshelves_name_user_id_key;
    '''))
