import requests
import pandas as pd
from azure.storage.blob import BlobServiceClient
from datetime import datetime
import os
import time
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()



# --- Configuration ---
# NYC 311 API endpoint: Retrieves a small sample of 50 311 service requests for reliable testing.
# Change $limit=50 back to $limit=5000 when deploying to a reliable Airflow environment.
API_URL = "https://data.cityofnewyork.us/resource/erm2-nwe9.json?$limit=50"

# Azure Blob configuration - read from environment variables
BLOB_CONN = os.getenv("AZURE_STORAGE_CONNECTION_STRING")
BLOB_CONTAINER = "urban-rawdata" # MUST match the container name in main.tf

def fetch_311_data(api_url):
    """
    Fetches data from the NYC 311 API, converts it to a Pandas DataFrame,
    and saves it to a local CSV file with a timestamped filename.
    """
    # NOTE: print is used here for local terminal feedback. Airflow logs will capture this.
    print(f"Fetching data from NYC 311 API: {api_url}...")
    
    try:
        # INCREASED TIMEOUT TO 60 SECONDS for greater reliability
        response = requests.get(api_url, timeout=90) 
        response.raise_for_status() # Raise HTTPError for bad responses (4xx or 5xx)
    except requests.exceptions.RequestException as e:
        print(f"Error fetching data from API: {e}")
        return None

    data_list = response.json()
    if not data_list:
        print("API returned no data.")
        return None

    # Convert JSON list to Pandas DataFrame
    data = pd.DataFrame(data_list)
    
    # Generate a unique, timestamped filename
    filename = f"311_data_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv"
    
    # Save the data locally
    data.to_csv(filename, index=False, encoding='utf-8')
    print(f"Successfully saved {len(data)} records to local file: {filename}")
    
    return filename

def upload_to_blob(filename, conn_string, container_name):
    """
    Uploads a local file to Azure Blob Storage.
    """
    if not conn_string:
        print("Error: AZURE_STORAGE_CONNECTION_STRING environment variable is not set.")
        return
        
    print(f"Connecting to Azure Blob Storage container: {container_name}...")
    try:
        # Initialize the Blob Service Client
        blob_service = BlobServiceClient.from_connection_string(conn_string)
        container_client = blob_service.get_container_client(container_name)
        
        # Check if the container exists (optional, but good practice)
        if not container_client.exists():
            print(f"Container '{container_name}' does not exist. Please check your Terraform configuration or create it.")
            return

        # Upload the file
        with open(filename, "rb") as data:
            container_client.upload_blob(name=filename, data=data, overwrite=True)
            
        print(f"Successfully uploaded {filename} to Azure Blob Storage.")
        
    except Exception as e:
        print(f"Error during Azure Blob upload: {e}")
        return
        
    finally:
        # Clean up the local file after upload
        if os.path.exists(filename):
            os.remove(filename)
            print(f"Cleaned up local file: {filename}")
    
    # CRITICAL: Return the filename to the main execution block
    return filename 


if __name__ == "__main__":
    start_time = time.time()
    
    # 1. Fetch data and save locally
    local_file = fetch_311_data(API_URL)
    
    if local_file:
        # 2. Upload to Azure Blob Storage
        # This requires the environment variable to be set in your shell session
        uploaded_filename = upload_to_blob(local_file, BLOB_CONN, BLOB_CONTAINER)
        
        # 3. CRITICAL: Print the filename ONLY if the upload was successful
        # This output is captured by the BashOperator and pushed to XCom.
        if uploaded_filename:
            print(uploaded_filename)
    
    end_time = time.time()
    print(f"\nPipeline run complete in {end_time - start_time:.2f} seconds.")
