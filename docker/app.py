from flask import Flask, jsonify
from prometheus_client import make_wsgi_app, Counter
from prometheus_client import Gauge
from prometheus_client import CollectorRegistry
from prometheus_client import exposition
from redis import Redis
import psycopg2

# Set Postgresql variable
PG_HOST = os.getenv('PG_HOST')
PG_PORT = int(os.getenv('PG_PORT', '5432'))
PG_DB = os.getenv('PG_DB')
PG_USER = os.getenv('PG_USER')
PG_PWD = os.getenv('PG_PWD')

# Set Redis variable
REDIS_HOST = os.getenv('REDIS_HOST')
REDIS_PORT = int(os.getenv('REDIS_PORT', '6379'))
REDIS_PWD = os.getenv('REDIS_PWD')

app = Flask(__name__)

# Metrics
users_count = Gauge('app_users_count', 'Number of users', registry=CollectorRegistry())

# Database connection
db_conn = psycopg2.connect(host=PG_HOST, port=PG_PORT, database=PG_DB, user=PG_USER, password=PG_PWD)
db_cursor = db_conn.cursor()

# Redis connection
redis_client = Redis(host=REDIS_HOST, port=REDIS_PORT, password=REDIS_PWD)

@app.route('/users')
def get_users():
    # Check cache
    cache_key = 'users'
    val = redis_client.get(cache_key)
    if val is not None:
        # Return data from cache if available
        users = json.loads(val)
        return jsonify(users)

    # Query the database
    db_cursor.execute('SELECT * FROM users')
    rows = db_cursor.fetchall()

    users = [{'id': row[0], 'name': row[1]} for row in rows]

    # Save data to cache
    redis_client.set(cache_key, json.dumps(users))

    # Update metric
    users_count.set(len(users))

    return jsonify(users)

@app.route('/users/<int:user_id>')
def get_user(user_id):
    # Query the database
    db_cursor.execute('SELECT * FROM users WHERE id = %s', (user_id,))
    row = db_cursor.fetchone()

    if row is None:
        return jsonify({'message': 'User not found'}), 404

    user = {'id': row[0], 'name': row[1]}

    return jsonify(user)

@app.route('/healthcheck')
def health_check():
    return 'OK'

@app.route('/metrics')
def metrics():
    registry = CollectorRegistry()
    registry.register(users_count)
    data = exposition.generate_latest(registry)
    return data, 200, {'Content-Type': exposition.CONTENT_TYPE_LATEST}

if __name__ == '__main__':
    app.wsgi_app = make_wsgi_app()
    app.run(port=8000)
