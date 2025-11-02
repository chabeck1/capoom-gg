#!/usr/bin/env python3
"""
Download files from Google Drive using a shareable link.
Based on: https://stackoverflow.com/a/39225039
"""

import requests
import sys

def download_file_from_google_drive(file_id, destination):
    """Download a file from Google Drive given its file ID."""
    
    def get_confirm_token(response):
        for key, value in response.cookies.items():
            if key.startswith('download_warning'):
                return value
        return None

    def save_response_content(response, destination):
        CHUNK_SIZE = 32768
        
        with open(destination, "wb") as f:
            for chunk in response.iter_content(CHUNK_SIZE):
                if chunk:  # filter out keep-alive new chunks
                    f.write(chunk)

    URL = "https://docs.google.com/uc?export=download"

    session = requests.Session()

    print(f"Downloading file ID: {file_id}")
    response = session.get(URL, params={'id': file_id}, stream=True)
    token = get_confirm_token(response)

    if token:
        print("Large file detected, using confirmation token...")
        params = {'id': file_id, 'confirm': token}
        response = session.get(URL, params=params, stream=True)

    print(f"Saving to: {destination}")
    save_response_content(response, destination)
    print("Download complete!")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python gdrive_download.py <file_id> <destination_path>")
        print("\nExample:")
        print("  python gdrive_download.py 1ABC123def456 output.zip")
        print("\nTo get file_id from shareable link:")
        print("  https://drive.google.com/file/d/FILE_ID/view?usp=sharing")
        sys.exit(1)
    
    # Get file ID from command line
    file_id = sys.argv[1]
    destination = sys.argv[2]
    
    download_file_from_google_drive(file_id, destination)
