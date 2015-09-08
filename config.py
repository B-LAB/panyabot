import os
basedir = os.path.abspath(os.path.dirname(__file__))
rootdir, panyafolder = os.path.split(basedir)
datadir = os.path.join(rootdir, 'data')

if not (os.path.exists(datadir)):
	os.mkdir(datadir)

CSRF_ENABLED = True
DEBUG = True

SECRET_KEY = 'you-will-never-guess'

if os.environ.get('DATABASE_URL') is None:
    SQLALCHEMY_DATABASE_URI = ('sqlite:///' + os.path.join(datadir, 'app.db') +
                               '?check_same_thread=False')
else:
    SQLALCHEMY_DATABASE_URI = os.environ['DATABASE_URL']
SQLALCHEMY_MIGRATE_REPO = os.path.join(datadir, 'db_repository')

# administrator list
ADMINS = ['you@example.com']