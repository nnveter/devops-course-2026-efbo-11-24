import os

import psycopg2
from flask import Flask

app = Flask(__name__)


@app.route('/health')
def health():
    return 'ok\n'


@app.route('/')
def index():
    with psycopg2.connect(host=os.environ['DB_HOST'], dbname=os.environ['POSTGRES_DB'],
                          user=os.environ['POSTGRES_USER'], password=os.environ['POSTGRES_PASSWORD']) as conn:
        with conn.cursor() as cursor:
            cursor.execute('CREATE TABLE IF NOT EXISTS visits (id SERIAL PRIMARY KEY, visited_at TIMESTAMP DEFAULT now())')
            cursor.execute('INSERT INTO visits DEFAULT VALUES')
            cursor.execute('SELECT count(*) FROM visits')
            count = cursor.fetchone()[0]
    return f'Hello from Docker, Salnikov! Visits: {count}\n'
