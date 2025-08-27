"""rating not null

Revision ID: 3d9d6210f53a
Revises: c99270f4b105
Create Date: 2025-08-27 14:30:30.396625

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '3d9d6210f53a'
down_revision = 'c99270f4b105'
branch_labels = None
depends_on = None


def upgrade():
    op.get_bind().execute(sa.text('''
        ALTER TABLE reviews RENAME COLUMN review TO content;
        ALTER TABLE reviews ALTER COLUMN rating SET NOT NULL;
    '''))


def downgrade():
    op.get_bind().execute(sa.text('''
        ALTER TABLE reviews RENAME COLUMN content TO review;
        ALTER TABLE reviews ALTER COLUMN rating DROP NOT NULL;
    '''))
