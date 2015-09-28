#!flask/bin/python
from config import DATA
from db_create import setdb
from db_migrate import migdb
import os

appdir = os.path.join(DATA, 'app.db')
repodir = os.path.join(DATA, 'db_repository','versions', '001_migration.py')
if not (os.path.exists(appdir)):
	print 'Creating DB for the first time!'
	setdb()
else:
	print 'DB already exists. Skipping creation.'
if not (os.path.exists(repodir)):
	migdb()
else:
	print 'Migration data repository already exists. Skipping creation.'