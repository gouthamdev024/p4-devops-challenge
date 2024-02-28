# Solution

## Lambda Functions

### ingest lambda

- This function download knowledge, skills and abilities data xlsx files from onet database.
- Uploads these files into s3 bucket `p4-devops-input-bucket-2`.
- This is scheduled to run every week.

### process lambda

- This function listens for events in `p4-devops-input-bucket-2` and when files are added this function is triggered.
- It loops through all files in the input bucket and counts the records for each file and write it to a file in `p4-devops-output-bucket-2`.

## Devops

### infra

- `terraform` has been used to create the following resources and configure them in aws.
  
    1. S3 bucket `p4-devops-input-bucket-2`
    2. S3 bucket `p4-devops-output-bucket-2`
    3. Weekly lambda function with Iam role with access to S3, and cloudwatch with schedule configured to run every week.
    4. S3  triggered lambda function with Iam role with access to S3, and cloudwatch with S3 bucket `p4-devops-input-bucket-2` added as input trigger.
 
-  Steps to manually run

    ```bash
    $ cd infra
    $ terraform init
    $ terraform plan
    $ terraform apply --auto-approve
    ```
 
### CI CD

- `terraform.yaml` workflow is triggered when changes made to `infra` folder.
- it creates / updated infra in aws.
- `weekly-lambda.yaml` workflow is triggered when changes made to `ingest-lambda` folder.
- it deploys latest weekly ingest lambda function to aws.
- `triggered-lambda.yaml` workflow is triggered when changes made to `process-lambda` folder.
- it deploys latest process lambda function to aws.
