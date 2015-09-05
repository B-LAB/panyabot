#!flask/bin/python
from migrate.versioning import api
from app import db, app
from config import datadir
import os.path

SQLALCHEMY_DATABASE_URI=app.config['SQLALCHEMY_DATABASE_URI']
SQLALCHEMY_MIGRATE_REPO=app.config['SQLALCHEMY_MIGRATE_REPO']

db.create_all()
try:
	if not os.path.exists(SQLALCHEMY_MIGRATE_REPO):
	    api.create(SQLALCHEMY_MIGRATE_REPO, 'database repository')
	    api.version_control(SQLALCHEMY_DATABASE_URI, SQLALCHEMY_MIGRATE_REPO)
	else:
	    api.version_control(SQLALCHEMY_DATABASE_URI, SQLALCHEMY_MIGRATE_REPO, api.version(SQLALCHEMY_MIGRATE_REPO))
except:
	print 'Database already exists'
