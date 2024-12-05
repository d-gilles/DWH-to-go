import wget
import zipfile
import pandas as pd
import os
import shutil
import boto3
from dotenv import load_dotenv
import io
import requests

# load .env
load_dotenv()

# set variables
os.environ["AWS_CONFIG_FILE"] = "~/.aws/config_terraform"
os.environ["AWS_SHARED_CREDENTIALS_FILE"] = "~/.aws/cred_terraform"
aws_region = os.getenv('AWS_REGION')
aws_profile = os.getenv('AWS_TERRAFORM_USER')
PROJECT_NAME=os.getenv('PROJECT_NAME')
ITERATION=os.getenv('ITERATION')

# create boto3 session
aws_session = boto3.Session(profile_name=aws_profile)
s3_client = aws_session.client('s3')

# set variables
folder_path = "./data"
url = 'https://archive.ics.uci.edu/static/public/352/online+retail.zip'

# create empty data folder
if os.path.exists(folder_path):
    shutil.rmtree(folder_path)
    print(f"** Folder '{folder_path}' got deleted.")
else:
    print(f"** Folder '{folder_path}' doesn't exist.")
os.makedirs(folder_path)
print(f"** Folder'{folder_path}' was created.")

# download the data 
print("** Start downloading the data...")
response = requests.get(url, stream=True)
if response.status_code == 200:
    with open('data.zip', 'wb') as file:
        for chunk in response.iter_content(chunk_size=8192):
            file.write(chunk)
    print("** Download finished.")
else:
    print(f"** Download failed. Status code: {response.status_code}")
    
# unzip file to data folder
print("** Start unzipping the data...")
with zipfile.ZipFile('data.zip', 'r') as zip_ref:
    zip_ref.extractall(path=folder_path)
os.remove('data.zip')

# load the xlsx file from data folder
print("** Importing the data...")
file = os.listdir(folder_path)[0]
df = pd.read_excel(os.path.join(folder_path, file))

# clean the data
print("** Cleaning the data...")
df = df[df['InvoiceNo'].astype(str).str.isdigit()]
df.loc[:,'StockCode'] = df['StockCode'].fillna("").astype(str)
df.loc[:,'Description'] = df['Description'].fillna("").astype(str)

# define bucket and name
print("** Uploading the data to s3...")
new_file_name = f"{file.split('.')[0].replace(' ', '')}.parquet"
bucket = f"{PROJECT_NAME}-i{ITERATION}-data-lake"
key = f"staging/{new_file_name}"

# write data to buffer
buffer = io.BytesIO()
df.to_parquet(buffer, engine='pyarrow', index=False)

# Upload
s3_client.put_object(Bucket=bucket, Key=key, Body=buffer.getvalue())
print(f"** File uploaded to s3://{bucket}/{key}")