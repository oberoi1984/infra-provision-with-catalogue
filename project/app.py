from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
import mysql.connector

app = Flask(__name__)
CORS(app)

# Database connection config
db_config = {
    'host': 'localhost',
    'user': 'catalogue_user',
    'password': 'Catalogue@123',
    'database': 'catalogue'
}


@app.route('/')
def index():
    # Serve the HTML Form (optional)
    return send_file('/root/project/templates/index.html')


@app.route('/submit', methods=['POST'])
def submit_request():
    if request.is_json:
        # JSON submission (CURL / API clients)
        data = request.json
    else:
        # Form submission (Web form)
        data = {
            'region': request.form.get('REGION'),
            'instance_type': request.form.get('INSTANCE_TYPE'),
            'ami_id': request.form.get('AMI_ID'),
            'instance_count': request.form.get('INSTANCE_COUNT'),
            'security_group': request.form.get('SECURITY_GROUP'),
            'key_pair': request.form.get('KEY_PAIR'),
            'subnet_id': request.form.get('SUBNET_ID'),
            'owner': request.form.get('OWNER'),
            'project': request.form.get('PROJECT'),
            'environment': request.form.get('ENVIRONMENT')
        }

    # Save to database
    connection = mysql.connector.connect(**db_config)
    cursor = connection.cursor()

    query = """
    INSERT INTO infra_requests 
    (region, instance_type, ami_id, instance_count, security_group, key_pair, subnet_id, owner, project, environment)
    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
    """
    values = (
        data['region'], data['instance_type'], data['ami_id'], data['instance_count'],
        data['security_group'], data['key_pair'], data['subnet_id'],
        data['owner'], data['project'], data['environment']
    )
    cursor.execute(query, values)
    connection.commit()

    cursor.close()
    connection.close()

    return jsonify({"message": "Request submitted successfully!"})


@app.route('/reset-db', methods=['POST'])
def reset_db():
    connection = mysql.connector.connect(**db_config)
    cursor = connection.cursor()

    cursor.execute("TRUNCATE TABLE infra_requests")
    connection.commit()

    cursor.close()
    connection.close()

    return jsonify({"message": "Database reset successfully!"})


@app.route('/fetch-requests', methods=['GET'])
def fetch_requests():
    connection = mysql.connector.connect(**db_config)
    cursor = connection.cursor(dictionary=True)

    cursor.execute("SELECT * FROM infra_requests")
    rows = cursor.fetchall()

    cursor.close()
    connection.close()

    return jsonify(rows)


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True, use_reloader=False)
