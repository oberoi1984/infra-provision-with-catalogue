import pymysql
import subprocess
import os
import time

# Database connection details
DB_HOST = 'localhost'
DB_USER = 'catalogue_user'
DB_PASSWORD = 'Catalogue@123'
DB_NAME = 'catalogue'

# Connect to MariaDB
connection = pymysql.connect(
    host=DB_HOST,
    user=DB_USER,
    password=DB_PASSWORD,
    database=DB_NAME
)

def fetch_pending_request():
    with connection.cursor() as cursor:
        cursor.execute("SELECT * FROM infra_requests ORDER BY requested_at DESC LIMIT 1")
        request = cursor.fetchone()
        return request

def generate_tfvars(request):
    tfvars_content = f"""
region = "{request[1]}"
instance_type = "{request[2]}"
ami_id = "{request[3]}"
instance_count = {request[4]}
security_group = "{request[5]}"
key_pair = "{request[6]}"
subnet_id = "{request[7]}"
owner = "{request[8]}"
project = "{request[9]}"
environment = "{request[10]}"
"""
    with open("terraform.tfvars", "w") as file:
        file.write(tfvars_content.strip())

def run_terraform():
    subprocess.run(["terraform", "init"], check=True)
    subprocess.run(["terraform", "plan", "-var-file=terraform.tfvars"], check=True)
    subprocess.run(["terraform", "apply", "-auto-approve", "-var-file=terraform.tfvars"], check=True)

def update_request_status(request_id, status):
    with connection.cursor() as cursor:
        cursor.execute("ALTER TABLE infra_requests ADD COLUMN IF NOT EXISTS status VARCHAR(20)")
        cursor.execute("UPDATE infra_requests SET status = %s WHERE id = %s", (status, request_id))
        connection.commit()

def main():
    request = fetch_pending_request()
    if not request:
        print("No pending requests found.")
        return

    print(f"Processing request ID: {request[0]}")
    generate_tfvars(request)

    try:
        run_terraform()
        update_request_status(request[0], "Completed")
        print(f"✅ Request {request[0]} completed successfully.")
    except subprocess.CalledProcessError as e:
        print(f"❌ Terraform failed for request {request[0]}")
        update_request_status(request[0], "Failed")

if __name__ == "__main__":
    main()

