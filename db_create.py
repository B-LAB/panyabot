#!flask/bin/python
from migrate.versioning import api
from app import db, app
import os.path

def setdb():
	# This function creates an app database and the migration data repository
	
	# these two variables are required by the sqlalchemy library and point to
	# the save directories in which the db and migration repository will be
	# stored.
	SQLALCHEMY_DATABASE_URI=app.config['SQLALCHEMY_DATABASE_URI']
	SQLALCHEMY_MIGRATE_REPO=app.config['SQLALCHEMY_MIGRATE_REPO']
	
	# db creation comes first
	try:
		db.create_all()
	except:
		print 'Error creating app database'
	
	# followed by the migration repository
	try:
		if not os.path.exists(SQLALCHEMY_MIGRATE_REPO):
		    api.create(SQLALCHEMY_MIGRATE_REPO, 'database repository')
		    api.version_control(SQLALCHEMY_DATABASE_URI, SQLALCHEMY_MIGRATE_REPO)
		else:
		    api.version_control(SQLALCHEMY_DATABASE_URI, SQLALCHEMY_MIGRATE_REPO, api.version(SQLALCHEMY_MIGRATE_REPO))
	except:
		print 'Error creating migration data repository'

def main():
	# this function call will be removed in production code
	setdb()

if __name__ == "__main__":
	main()
