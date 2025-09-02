"""pending_user_verifications

Revision ID: ca9c627ac236
Revises: 3d9d6210f53a
Create Date: 2025-09-02 12:08:00.800274

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'ca9c627ac236'
down_revision = '3d9d6210f53a'
branch_labels = None
depends_on = None


def upgrade():
    op.get_bind().execute(sa.text('''
        CREATE TABLE pending_user_verifications (
            token TEXT PRIMARY KEY,
            user_id INTEGER REFERENCES users(id) ON DELETE CASCADE NOT NULL
        );
        ALTER TABLE pending_user_verifications ADD COLUMN created TIMESTAMPTZ DEFAULT now();
        ALTER TABLE pending_user_verifications ADD COLUMN modified TIMESTAMPTZ DEFAULT now();
        CREATE TRIGGER update_pending_user_verifications_modified BEFORE UPDATE ON pending_user_verifications
        FOR EACH ROW EXECUTE PROCEDURE update_modified_column();
    '''))


def downgrade():
    op.get_bind().execute(sa.text('''
        DROP TABLE pending_user_verifications;
    '''))
