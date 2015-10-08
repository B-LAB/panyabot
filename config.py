import os
basedir = os.path.abspath(os.path.dirname(__file__))
rootdir, panyafolder = os.path.split(basedir)
datadir = os.path.join(rootdir, 'data')

# check if the data directory exists, if not create it.
if not (os.path.exists(datadir)):
	os.mkdir(datadir)
else:
	print 'Data directory exists. Skipping creation.'

# Cross-site-request-forgery prevention to secure app.
# Secret key is used to create a cryptographic token
# used to validate a form.
# Debug flag is set to true telling Jinja to enable stack
# trace errors during development. For deployed apps set to
# false.
# app module variables are only indexed if they are in CAPS,
# hence DIR and BASE.
WTF_CSRF_ENABLED = True
SECRET_KEY = 'hbjdkja-32enkn-31k3byi'
DEBUG = True
DATA = datadir
BASE = basedir

# SQLALCHEMY_DATABASE_URI used by Flask-SQLAlchemy and points
# to the database file. You can set DATABASE_URL in your app's
# host system environment variables if you'd like to use
# a database server, otherwise an sqlite db will be created.
# SQLALCHEMY_MIGRATE_REPO used by slqalchemy-migrate and points
# to where migrate data files will be stored.
if os.environ.get('DATABASE_URL') is None:
    SQLALCHEMY_DATABASE_URI = ('sqlite:///' + os.path.join(DATA, 'app.db') +
                               '?check_same_thread=False')
else:
    SQLALCHEMY_DATABASE_URI = os.environ['DATABASE_URL']
SQLALCHEMY_MIGRATE_REPO = os.path.join(DATA, 'db_repository')

# administrator list
ADMINS = ['you@example.com']