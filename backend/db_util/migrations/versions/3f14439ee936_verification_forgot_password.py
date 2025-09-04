"""verification.forgot_password

Revision ID: 3f14439ee936
Revises: ca9c627ac236
Create Date: 2025-09-03 17:58:37.794295

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '3f14439ee936'
down_revision = 'ca9c627ac236'
branch_labels = None
depends_on = None


def upgrade():
    op.get_bind().execute(sa.text('''
        ALTER TABLE pending_user_verifications
            ADD COLUMN forgot_password BOOL DEFAULT false;
    '''))


def downgrade():
    op.get_bind().execute(sa.text('''
        ALTER TABLE pending_user_verifications
            DROP COLUMN forgot_password;
    '''))
