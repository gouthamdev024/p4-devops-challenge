import boto3
import openpyxl
from io import BytesIO
from datetime import datetime

s3 = boto3.client('s3')

def lambda_handler(event, context):
    input_bucket = 'p4-devops-input-bucket-2'
    output_bucket = 'p4-devops-output-bucket-2'
    today_date = datetime.now().strftime('%d-%m-%Y')
    prefix = f"{today_date}/"

    print("process-lambda...")
    
    # List files in the specific date folder
    response = s3.list_objects_v2(Bucket=input_bucket, Prefix=prefix)

    records_summary = "filename: number_of_records\n"
    if 'Contents' in response:
        for obj in response['Contents']:
            key = obj['Key']
            if key.endswith('.xlsx'):  # Process only XLSX files
                xlsx_file = s3.get_object(Bucket=input_bucket, Key=key)
                workbook = openpyxl.load_workbook(BytesIO(xlsx_file['Body'].read()))
                sheet = workbook.active
                num_records = sheet.max_row - 1  # Assuming the first row is headers
                file_name = key.split('/')[-1]
                records_summary += f"{file_name}: {num_records}\n"

    # Write the summary to the output bucket
    output_key = f"{prefix}records_summary.txt"
    s3.put_object(Bucket=output_bucket, Key=output_key, Body=records_summary)

    return {
        'statusCode': 200,
        'body': 'Record count summary has been successfully created!'
    }
