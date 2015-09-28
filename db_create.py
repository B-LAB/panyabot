#!flask/bin/python
from migrate.versioning import api
from app import db, app
import os.path

def setdb():
	# This function creates an app database
	# and the migration data repository
	SQLALCHEMY_DATABASE_URI=app.config['SQLALCHEMY_DATABASE_URI']
	SQLALCHEMY_MIGRATE_REPO=app.config['SQLALCHEMY_MIGRATE_REPO']
	try:
		db.create_all()
	except:
		print 'Error creating app database'
	try:
		if not os.path.exists(SQLALCHEMY_MIGRATE_REPO):
		    api.create(SQLALCHEMY_MIGRATE_REPO, 'database repository')
		    api.version_control(SQLALCHEMY_DATABASE_URI, SQLALCHEMY_MIGRATE_REPO)
		else:
		    api.version_control(SQLALCHEMY_DATABASE_URI, SQLALCHEMY_MIGRATE_REPO, api.version(SQLALCHEMY_MIGRATE_REPO))
	except:
		print 'Error creating migration data repository'

def main():
	pass

if __name__ == "__main__":
	main()
