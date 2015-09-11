#!flask/bin/python
from config import datadir
from db_create import setdb
from db_migrate import migdb
import os

appdir = os.path.join(datadir, 'app.db')
repodir = os.path.join(datadir, 'db_repository','versions', '001_migration.py')
if not (os.path.exists(appdir)):
	print 'Creating DB for first app run'
	setdb()
else:
	print 'DB already exists'
if not (os.path.exists(repodir)):
	migdb()
else:
	print 'Migration already complete'