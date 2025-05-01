import os
import json
import requests
import boto3
import logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

S3_BUCKET_NAME = os.environ.get('S3_BUCKET_NAME', 'lambda-4428y6uo8f')
SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN','arn:aws:sns:eu-central-1:343243956668:health-check-notifications')
FAILURE_THRESHOLD = int(os.environ.get('FAILURE_THRESHOLD', 3))

sns_client = boto3.client('sns')
s3_client = boto3.client('s3')

def get_endpoints():
        response = s3_client.get_object(
            Bucket=S3_BUCKET_NAME,
            Key='endpoints.txt'
        )
        content = response['Body'].read().decode('utf-8')
        return [endpoint.strip() for endpoint in content.split('\n') if endpoint.strip()]

def read_count():
    response = s3_client.get_object(
        Bucket=S3_BUCKET_NAME,
        Key='counts.json'
    )
    content = response['Body'].read().decode('utf-8')
    return json.loads(content)


def write_count(count):
    s3_client.put_object(
        Bucket=S3_BUCKET_NAME,
        Key='counts.json',
        Body=json.dumps(count),
        ContentType='application/json'
    )

def lambda_handler(event, context):
    endpoints = get_endpoints()    
    count = read_count()
    
    for endpoint in endpoints:
        if endpoint not in count:
            count[endpoint] = 0

    for endpoint in endpoints:
        try:
            response = requests.get(endpoint)
            status_code = response.status_code
            health_check(endpoint, status_code)
            
            if 400 <= status_code < 600:
                count[endpoint] += 1
                if count[endpoint] >= FAILURE_THRESHOLD:
                    send_notification(endpoint)
            else:
                count[endpoint] = 0

        except requests.exceptions.RequestException as e:
            health_check(endpoint, e)
            count[endpoint] += 1
            if count[endpoint] == FAILURE_THRESHOLD:
                send_notification(endpoint)

    write_count(count)
    
    return {
        'statusCode': 200,
        'body': 'Health check OK'
    }

def health_check(endpoint, status):
    print(f"Health check for {endpoint}: {status}")

def send_notification(endpoint):
    message = f"Alert: {endpoint} failed {FAILURE_THRESHOLD} health checks."
    sns_client.publish(
        TopicArn=SNS_TOPIC_ARN,
        Message=message,
        Subject='Health check Alert'
    )
