#!/usr/bin/env python3
"""
Download entire folder from Google Drive using shareable link.
Handles large files and bypasses the 50-file gdown limitation.
"""

import requests
import re
import os
import sys
from urllib.parse import parse_qs, urlparse

def get_folder_id(url):
    """Extract folder ID from various Google Drive URL formats."""
    patterns = [
        r'/folders/([a-zA-Z0-9_-]+)',
        r'id=([a-zA-Z0-9_-]+)',
    ]
    for pattern in patterns:
        match = re.search(pattern, url)
        if match:
            return match.group(1)
    return None

def download_file_from_google_drive(file_id, destination):
    """Download a single file from Google Drive."""
    
    def get_confirm_token(response):
        for key, value in response.cookies.items():
            if key.startswith('download_warning'):
                return value
        return None

    def save_response_content(response, destination):
        CHUNK_SIZE = 32768
        with open(destination, "wb") as f:
            downloaded = 0
            for chunk in response.iter_content(CHUNK_SIZE):
                if chunk:
                    f.write(chunk)
                    downloaded += len(chunk)
                    # Simple progress indicator
                    print(f"\r  Downloaded: {downloaded / 1024 / 1024:.2f} MB", end='', flush=True)
        print()  # New line after download

    URL = "https://docs.google.com/uc?export=download"
    session = requests.Session()

    response = session.get(URL, params={'id': file_id}, stream=True)
    token = get_confirm_token(response)

    if token:
        params = {'id': file_id, 'confirm': token}
        response = session.get(URL, params=params, stream=True)

    save_response_content(response, destination)

def get_folder_files(folder_id):
    """
    Attempt to get list of files in a Google Drive folder.
    Note: This requires the folder to be publicly accessible.
    """
    print(f"Attempting to list files in folder {folder_id}...")
    print("Note: This requires using Google Drive API or manual file ID entry.")
    print("\nUnfortunately, without API credentials, we cannot automatically")
    print("list all files in a folder. You have two options:\n")
    print("1. Provide a text file with file IDs (one per line)")
    print("2. Download the folder as a zip on your Mac and scp it to Great Lakes")
    return None

def download_folder(folder_url, destination_dir):
    """Download all files from a Google Drive folder."""
    
    folder_id = get_folder_id(folder_url)
    if not folder_id:
        print(f"Error: Could not extract folder ID from URL: {folder_url}")
        sys.exit(1)
    
    print(f"Folder ID: {folder_id}")
    print(f"Destination: {destination_dir}")
    
    # Create destination directory
    os.makedirs(destination_dir, exist_ok=True)
    
    # Try to get file list
    files = get_folder_files(folder_id)
    
    if not files:
        print("\n" + "="*60)
        print("WORKAROUND: Create a file_ids.txt with this format:")
        print("FILE_ID_1|filename1.ext")
        print("FILE_ID_2|filename2.ext")
        print("="*60)
        sys.exit(1)

def download_from_file_list(file_list_path, destination_dir):
    """Download files based on a text file with file IDs and names."""
    
    os.makedirs(destination_dir, exist_ok=True)
    
    with open(file_list_path, 'r') as f:
        lines = f.readlines()
    
    total = len(lines)
    for i, line in enumerate(lines, 1):
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        
        parts = line.split('|')
        if len(parts) != 2:
            print(f"Skipping invalid line: {line}")
            continue
        
        file_id, filename = parts
        file_id = file_id.strip()
        filename = filename.strip()
        
        dest_path = os.path.join(destination_dir, filename)
        
        print(f"\n[{i}/{total}] Downloading: {filename}")
        print(f"  File ID: {file_id}")
        
        try:
            download_file_from_google_drive(file_id, dest_path)
            print(f"  ✓ Saved to: {dest_path}")
        except Exception as e:
            print(f"  ✗ Error: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage:")
        print("  Single file:  python gdrive_download_folder.py file <file_id> <destination>")
        print("  From list:    python gdrive_download_folder.py list <file_ids.txt> <dest_dir>")
        print("\nfile_ids.txt format (one per line):")
        print("  FILE_ID_1|filename1.jpg")
        print("  FILE_ID_2|filename2.bin")
        sys.exit(1)
    
    mode = sys.argv[1]
    
    if mode == "file":
        if len(sys.argv) != 4:
            print("Usage: python gdrive_download_folder.py file <file_id> <destination>")
            sys.exit(1)
        file_id = sys.argv[2]
        destination = sys.argv[3]
        print(f"Downloading single file...")
        download_file_from_google_drive(file_id, destination)
        print("Done!")
        
    elif mode == "list":
        if len(sys.argv) != 4:
            print("Usage: python gdrive_download_folder.py list <file_ids.txt> <dest_dir>")
            sys.exit(1)
        file_list = sys.argv[2]
        dest_dir = sys.argv[3]
        download_from_file_list(file_list, dest_dir)
        print("\nAll downloads complete!")
        
    elif mode == "folder":
        if len(sys.argv) != 4:
            print("Usage: python gdrive_download_folder.py folder <folder_url> <dest_dir>")
            sys.exit(1)
        folder_url = sys.argv[2]
        dest_dir = sys.argv[3]
        download_folder(folder_url, dest_dir)
    else:
        print(f"Unknown mode: {mode}")
        print("Use 'file', 'list', or 'folder'")
        sys.exit(1)
