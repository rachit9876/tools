# Tools

<details>
  <summary>Haokies</summary>
  It can be used to view the cache files of a browser by simply providing the path to the cache storage folder.
  
```
C:\Users\<User Name>\AppData\Local\Google\Chrome\User Data\Default\Cache\Cache_Data
```

  ```
  import os
import re
import shutil

# File signature map (magic bytes → extension)
SIGNATURES = {
    b"\xff\xd8\xff": "jpg",
    b"\x89PNG\r\n\x1a\n": "png",
    b"GIF87a": "gif",
    b"GIF89a": "gif",
    b"RIFF": "avi",       # also wav/webp
    b"ID3": "mp3",
    b"OggS": "ogg",
    b"fLaC": "flac",
    b"\x1aE\xdf\xa3": "mkv",
    b"ftyp": "mp4",       # generic MP4/QuickTime
    b"%PDF": "pdf",
    b"PK\x03\x04": "zip", # may be docx/xlsx too
    b"{": "json",         # crude detection
    b"<html": "html",
    b"<!DOCT": "html",
    b"function": "js",
    b"var ": "js",
    b"woff": "woff",
    b"ttcf": "ttf"
}

# Assign category based on extension
CATEGORY_MAP = {
    "jpg": "images", "png": "images", "gif": "images", "webp": "images", "bmp": "images",
    "mp4": "videos", "mkv": "videos", "avi": "videos", "webm": "videos",
    "mp3": "audio", "ogg": "audio", "wav": "audio", "flac": "audio",
    "pdf": "docs", "docx": "docs", "xlsx": "docs", "txt": "docs", "json": "docs", "html": "docs",
    "js": "scripts", "css": "scripts",
    "woff": "fonts", "woff2": "fonts", "ttf": "fonts", "otf": "fonts",
    "zip": "misc"
}

def ensure_dir(path):
    if not os.path.exists(path):
        os.makedirs(path)

def detect_type(data):
    for sig, ext in SIGNATURES.items():
        if data.startswith(sig):
            return ext
    return None

def get_user_input():
    print("=" * 60)
    print("Chrome Cache Extractor")
    print("=" * 60)
    
    # Get source folder path
    while True:
        source_path = input("Please paste the source folder path in quotes: ").strip().strip('"')
        if os.path.exists(source_path):
            break
        else:
            print("Error: The path does not exist. Please try again.")
    
    # Get extraction option
    print("\nExtraction options:")
    print("1. Extract in current folder")
    print("2. Custom path")
    
    while True:
        option = input("Choose option (1 or 2): ").strip()
        if option == "1":
            output_base = os.getcwd()
            break
        elif option == "2":
            custom_path = input("Please enter custom path in quotes: ").strip().strip('"')
            if custom_path:
                output_base = custom_path
                # Create the custom path if it doesn't exist
                ensure_dir(custom_path)
                break
            else:
                print("Error: Please enter a valid path.")
        else:
            print("Error: Please enter 1 or 2.")
    
    # Set the final output directory to Haokies within the chosen base path
    OUTPUT_DIR = os.path.join(output_base, "Haokies")
    
    return source_path, OUTPUT_DIR

def carve_files(source_dir, output_dir):
    # Create the Haokies directory structure
    categories = ["docs", "images", "scripts", "videos", "audio", "fonts", "misc"]
    for category in categories:
        ensure_dir(os.path.join(output_dir, category))
    
    count = 0
    for root, _, files in os.walk(source_dir):
        for fname in files:
            fpath = os.path.join(root, fname)
            try:
                with open(fpath, "rb") as f:
                    data = f.read(2048)  # read first 2KB
                ext = detect_type(data)
                if ext:
                    cat = CATEGORY_MAP.get(ext, "misc")
                    out_dir = os.path.join(output_dir, cat)
                    out_file = os.path.join(out_dir, f"{fname}.{ext}")
                    
                    # Copy the entire file
                    with open(fpath, "rb") as src, open(out_file, "wb") as dst:
                        dst.write(src.read())
                    count += 1
            except Exception as e:
                print(f"[!] Error reading {fpath}: {e}")
    
    return count

def display_structure(output_dir):
    """Display the folder structure"""
    print(f"\nFolder structure created:")
    print(f"{output_dir}")
    for category in ["docs", "images", "scripts", "videos", "audio", "fonts", "misc"]:
        category_path = os.path.join(output_dir, category)
        if os.path.exists(category_path):
            file_count = len([f for f in os.listdir(category_path) if os.path.isfile(os.path.join(category_path, f))])
            print(f"├───{category} ({file_count} files)")
    
    # Show additional empty directories that were created
    empty_dirs = []
    for category in ["docs", "images", "scripts", "videos", "audio", "fonts", "misc"]:
        category_path = os.path.join(output_dir, category)
        if os.path.exists(category_path) and not os.listdir(category_path):
            empty_dirs.append(category)
    
    if empty_dirs:
        print("└───empty directories: " + ", ".join(empty_dirs))

if __name__ == "__main__":
    try:
        # Get user input
        CACHE_DIR, OUTPUT_DIR = get_user_input()
        
        print(f"\nSource directory: {CACHE_DIR}")
        print(f"Output directory: {OUTPUT_DIR}")
        print("\nStarting extraction...")
        
        # Perform extraction
        file_count = carve_files(CACHE_DIR, OUTPUT_DIR)
        
        # Display results
        print(f"\n[+] Extraction complete! {file_count} files carved into:")
        print(f"    {OUTPUT_DIR}")
        
        # Show folder structure
        display_structure(OUTPUT_DIR)
        
    except KeyboardInterrupt:
        print("\n\nOperation cancelled by user.")
    except Exception as e:
        print(f"\n[!] An error occurred: {e}")
  ```
</details>

<details>
  <summary>bingCrawler</summary>
  It is used to get images from serach engine directy.
  
```
# First, install the required library
!pip install icrawler --quiet

import os
import time
from icrawler.builtin import BingImageCrawler

class NSFWBingCrawler(BingImageCrawler):
    def _request(self, url, **kwargs):
        if "adlt=" in url:
            url = url.replace("adlt=strict", "adlt=off")
        else:
            url += "&adlt=off"
        return super()._request(url, **kwargs)

def download_images(query, num_images, base="/content/downloaded_images"):
    """
    Download images from Bing with NSFW content allowed
    
    Args:
        query (str): Search term for images
        num_images (int): Number of images to download
        base (str): Base directory to save images
    
    Returns:
        str: Path where images were saved
    """
    # Create save directory
    save_dir = os.path.join(base, query.replace(" ", "_"))
    os.makedirs(save_dir, exist_ok=True)
    
    print(f"Downloading {num_images} images for query: '{query}'")
    print(f"Images will be saved to: {save_dir}")
    print("Starting download... (this may take a few minutes)")
    
    # Initialize and run crawler
    crawler = NSFWBingCrawler(storage={"root_dir": save_dir})
    crawler.crawl(keyword=query, max_num=num_images)
    
    return save_dir

def main():
    print("=" * 50)
    print("BING IMAGE DOWNLOADER (NSFW Enabled)")
    print("=" * 50)
    print()
    
    # Get user input
    search_term = input("Enter search term: ").strip()
    if not search_term:
        print("Error: Search term cannot be empty!")
        return
    
    try:
        num_files = int(input("Enter number of images to download: "))
        if num_files <= 0:
            print("Error: Number must be greater than 0!")
            return
        if num_files > 1000:
            print("Warning: Large number of images may take a long time!")
            confirm = input("Continue? (y/n): ").lower()
            if confirm != 'y':
                return
    except ValueError:
        print("Error: Please enter a valid number!")
        return
    
    print()
    
    # Download images
    try:
        path = download_images(search_term, num_files)
        print()
        print("✅ Download completed successfully!")
        print(f"📁 Images saved to: {path}")
        
        # Count downloaded files
        downloaded_count = len([f for f in os.listdir(path) if f.endswith(('.jpg', '.jpeg', '.png', '.gif'))])
        print(f"📊 Total images downloaded: {downloaded_count}")
        
    except Exception as e:
        print(f"❌ Error during download: {str(e)}")

if __name__ == "__main__":
    main()
```
</details>









