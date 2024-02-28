import boto3
import requests
from contextlib import closing
from datetime import datetime

s3 = boto3.client('s3')
bucket_name = 'p4-devops-input-bucket-2'  # Your specific bucket name

def lambda_handler(event, context):
    # Get today's date in DD-MM-YYYY format
    today_date = datetime.now().strftime('%d-%m-%Y')
    
    urls = [
        'https://www.onetcenter.org/dl_files/database/db_28_2_excel/Knowledge.xlsx',
        'https://www.onetcenter.org/dl_files/database/db_28_2_excel/Skills.xlsx',
        'https://www.onetcenter.org/dl_files/database/db_28_2_excel/Abilities.xlsx'
    ]

    print("ingest-lambda...")

    for url in urls:
        file_name = url.split('/')[-1]
        # Update the S3 key to include the date folder
        s3_key = f"{today_date}/{file_name}"
        
        with closing(requests.get(url, stream=True)) as r:
            # Check if the request was successful
            if r.status_code == 200:
                # Upload the file to S3
                s3.upload_fileobj(r.raw, bucket_name, s3_key)
                print(f'Successfully uploaded {file_name} to {bucket_name} in folder {today_date}')
            else:
                print(f'Failed to download {file_name}')

    return {
        'statusCode': 200,
        'body': f'Files have been successfully uploaded to S3 bucket {bucket_name} in folder {today_date}'
    }
