from flask import render_template
from app import app

@app.route('/')
@app.route('/home')
def home():
	return render_template('home.html')