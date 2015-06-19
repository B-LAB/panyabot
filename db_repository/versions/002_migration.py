from sqlalchemy import *
from migrate import *


from migrate.changeset import schema
pre_meta = MetaData()
post_meta = MetaData()
robot = Table('robot', post_meta,
    Column('id', Integer, primary_key=True, nullable=False),
    Column('alias', String(length=64)),
    Column('macid', String(length=48)),
    Column('totaltime', Integer),
    Column('lastuse', DateTime),
    Column('user_id', Integer),
)

session = Table('session', post_meta,
    Column('id', Integer, primary_key=True, nullable=False),
    Column('timestamp', DateTime),
    Column('progression', String),
    Column('duration', Integer),
    Column('robot_id', Integer),
)


def upgrade(migrate_engine):
    # Upgrade operations go here. Don't create your own engine; bind
    # migrate_engine to your metadata
    pre_meta.bind = migrate_engine
    post_meta.bind = migrate_engine
    post_meta.tables['robot'].create()
    post_meta.tables['session'].create()


def downgrade(migrate_engine):
    # Operations to reverse the above upgrade go here.
    pre_meta.bind = migrate_engine
    post_meta.bind = migrate_engine
    post_meta.tables['robot'].drop()
    post_meta.tables['session'].drop()
