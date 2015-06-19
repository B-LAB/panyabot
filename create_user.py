#!/usr/bin/env python2.7

from getpass import getpass
import sys

from flask import current_app
from app import app, bcrypt
from app.models import User, db

def main():
    """Main entry point for script."""
    with app.app_context():
        db.metadata.create_all(db.engine)
        if User.query.all():
            print 'A user already exists! Create another? (y/n):',
            create = raw_input()
            if create == 'n':
                return

        print 'Enter Firstname: ',
        firstname = raw_input()
        print 'Enter Lastname: ',
        lastname = raw_input()
        print 'Enter Nickname: ',
        nickname = raw_input()
        password = getpass()
        assert password == getpass('Password (again):')

        user = User(firstname=firstname, lastname=lastname, nickname=nickname, password=bcrypt.generate_password_hash(password))
        db.session.add(user)
        db.session.commit()
        print 'User added.'



if __name__ == '__main__':
    sys.exit(main())