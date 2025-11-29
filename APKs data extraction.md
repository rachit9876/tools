# 📱 Android App Data Recovery Guide

A comprehensive guide to recover data from any Android app using ADB backup and extraction.

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Step 1: Set Up Environment](#step-1-set-up-environment)
3. [Step 2: Install App on Emulator](#step-2-install-app-on-emulator)
4. [Step 3: Create Android Backup](#step-3-create-android-backup)
5. [Step 4: Extract the Backup](#step-4-extract-the-backup)
6. [Step 5: Understand Data Structure](#step-5-understand-data-structure)
7. [Step 6: Read the Database](#step-6-read-the-database)
8. [Alternative Methods](#alternative-methods)
9. [Troubleshooting](#troubleshooting)
10. [Common App Data Locations](#common-app-data-locations)

---

## Prerequisites

| Tool | Purpose | Download |
|------|---------|----------|
| **ADB** | Android Debug Bridge | [platform-tools](https://developer.android.com/studio/releases/platform-tools) |
| **Android Emulator** | Run Android apps on PC | [Bluestacks](https://www.bluestacks.com/), [LDPlayer](https://www.ldplayer.net/), [NoxPlayer](https://www.bignox.com/) |
| **Python 3.x** | Extract backup files | [python.org](https://www.python.org/downloads/) |
| **APK File** | The app you want to recover data from | - |

> 💡 **Tip**: Use older Android versions (Nougat/Android 7) in emulators as they have fewer security restrictions.

---

## Step 1: Set Up Environment

### 1.1 Install ADB

1. Download [platform-tools](https://developer.android.com/studio/releases/platform-tools)
2. Extract to a folder (e.g., `C:\platform-tools`)
3. Add to system PATH or use full path

### 1.2 Install & Configure Emulator

**For Bluestacks:**
1. Download and install [Bluestacks 5](https://www.bluestacks.com/)
2. Choose **Nougat 64-bit** instance (Android 7)
3. Go to **Settings → Advanced**
4. Enable **Android Debug Bridge (ADB)**

### 1.3 Verify ADB Connection

```powershell
# List connected devices
adb devices

# Expected output:
# List of devices attached
# emulator-5554   device
```

If connection issues occur:
```powershell
# Restart ADB server
adb kill-server
adb start-server
adb devices
```

---

## Step 2: Install App on Emulator

### 2.1 Install APK

```powershell
adb install "C:\path\to\your\app.apk"
```

### 2.2 Verify Installation

```powershell
# List all packages
adb shell pm list packages

# Search for specific app
adb shell pm list packages | findstr "appname"

# Example: Find diary app
adb shell pm list packages | findstr "diary"
```

### 2.3 Find Package Name

If you don't know the package name:

```powershell
# List all installed packages with their paths
adb shell pm list packages -f

# Or decompile APK and check AndroidManifest.xml
```

---

## Step 3: Create Android Backup

This is the **most important step** - extract app data using ADB backup.

### 3.1 Basic Backup Command

```powershell
adb backup -f "backup.ab" -apk com.package.name
```

### 3.2 Backup Options

| Flag | Description |
|------|-------------|
| `-f filename.ab` | Output backup file name |
| `-apk` | Include the APK file |
| `-noapk` | Exclude APK (smaller backup) |
| `-shared` | Include shared/external storage |
| `-all` | Backup all apps |
| `-nosystem` | Exclude system apps |

### 3.3 Examples

```powershell
# Backup single app with APK
adb backup -f "diary_backup.ab" -apk com.sleepwalkers.diary

# Backup without APK (smaller file)
adb backup -f "diary_backup.ab" -noapk com.sleepwalkers.diary

# Backup all user apps
adb backup -f "full_backup.ab" -apk -all -nosystem
```

### 3.4 Confirm Backup on Device

⚠️ **IMPORTANT**: After running the backup command:

1. Look at the emulator screen
2. A dialog will appear asking to confirm backup
3. **Tap "Back up my data"** button
4. Wait for backup to complete

> The backup file size indicates if data was captured. A very small file (< 1KB) means no data.

---

## Step 4: Extract the Backup

### 4.1 Android Backup File Structure

```
ANDROID BACKUP
4              ← Format version
1              ← Compressed (1=yes, 0=no)
none           ← Encryption (none/AES-256)
[zlib compressed tar data]
```

### 4.2 Python Extraction Script

Save this as `extract_backup.py`:

```python
import zlib
import tarfile
import os
import sys

def extract_android_backup(backup_path, output_dir):
    """
    Extract Android backup (.ab) file to a directory.
    
    Args:
        backup_path: Path to .ab backup file
        output_dir: Directory to extract files to
    """
    print(f"Reading backup file: {backup_path}")
    
    # Read the backup file
    with open(backup_path, 'rb') as f:
        data = f.read()
    
    print(f"Total file size: {len(data)} bytes")
    
    # Parse header
    lines = data.split(b'\n', 4)
    
    header = lines[0].decode().strip()
    version = lines[1].decode().strip()
    compressed = lines[2].decode().strip()
    encryption = lines[3].decode().strip()
    
    print(f"Header: {header}")
    print(f"Version: {version}")
    print(f"Compressed: {compressed}")
    print(f"Encryption: {encryption}")
    
    # Check if encrypted
    if encryption != 'none':
        print("ERROR: Backup is encrypted! You need the password to decrypt.")
        print("Use 'abe.jar' tool with password to decrypt first.")
        return False
    
    # Calculate where compressed data starts
    header_end = sum(len(l) + 1 for l in lines[:4])
    compressed_data = data[header_end:]
    
    print(f"Compressed data starts at byte: {header_end}")
    print(f"Compressed data size: {len(compressed_data)} bytes")
    
    # Decompress using zlib
    print("Decompressing...")
    try:
        tar_data = zlib.decompress(compressed_data)
        print(f"Decompressed size: {len(tar_data)} bytes")
    except zlib.error as e:
        print(f"Decompression error: {e}")
        return False
    
    # Save as tar file
    tar_path = backup_path.replace('.ab', '.tar')
    with open(tar_path, 'wb') as f:
        f.write(tar_data)
    print(f"Saved TAR file: {tar_path}")
    
    # Extract tar archive
    print(f"Extracting to: {output_dir}")
    os.makedirs(output_dir, exist_ok=True)
    
    with tarfile.open(tar_path, 'r') as tar:
        tar.extractall(output_dir)
    
    print("Extraction complete!")
    
    # List extracted files
    print("\nExtracted files:")
    for root, dirs, files in os.walk(output_dir):
        for file in files:
            filepath = os.path.join(root, file)
            size = os.path.getsize(filepath)
            print(f"  {filepath} ({size} bytes)")
    
    return True

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python extract_backup.py <backup.ab> [output_dir]")
        print("Example: python extract_backup.py diary_backup.ab extracted_data")
        sys.exit(1)
    
    backup_file = sys.argv[1]
    output_dir = sys.argv[2] if len(sys.argv) > 2 else backup_file.replace('.ab', '_extracted')
    
    extract_android_backup(backup_file, output_dir)
```

### 4.3 Run Extraction

```powershell
python extract_backup.py backup.ab extracted_data
```

---

## Step 5: Understand Data Structure

### 5.1 Extracted Folder Layout

```
extracted_data/
└── apps/
    └── com.package.name/
        ├── _manifest           ← App manifest info
        ├── a/                  ← APK files
        │   └── base.apk
        ├── db/                 ← SQLite DATABASES ⭐
        │   ├── app.db
        │   └── app.db-journal
        ├── f/                  ← Internal files
        │   ├── attachments/    ← Images, media
        │   └── cache/
        ├── r/                  ← Resources, optimized files
        └── sp/                 ← SharedPreferences (XML)
            └── settings.xml
```

### 5.2 Key Folders

| Folder | Contains | Importance |
|--------|----------|------------|
| `db/` | SQLite databases | ⭐⭐⭐ **Main data storage** |
| `f/` | Files, images, attachments | ⭐⭐⭐ Media files |
| `sp/` | Settings, preferences | ⭐⭐ App configuration |
| `a/` | APK files | ⭐ App itself |
| `r/` | Cached/optimized resources | ⭐ Usually not needed |

---

## Step 6: Read the Database

### 6.1 Python Script to Read Database

Save as `read_database.py`:

```python
import sqlite3
import os
from datetime import datetime

def read_database(db_path):
    """
    Read and display contents of a SQLite database.
    """
    print(f"Opening database: {db_path}")
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Get all tables
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
    tables = cursor.fetchall()
    
    print(f"\n{'='*60}")
    print(f"Tables found: {[t[0] for t in tables]}")
    print(f"{'='*60}")
    
    for table in tables:
        table_name = table[0]
        
        # Skip system tables
        if table_name.startswith('android_') or table_name.startswith('sqlite_'):
            continue
        
        # Get column info
        cursor.execute(f"PRAGMA table_info({table_name})")
        columns = cursor.fetchall()
        column_names = [col[1] for col in columns]
        
        print(f"\n\n{'='*60}")
        print(f"TABLE: {table_name}")
        print(f"Columns: {column_names}")
        print(f"{'='*60}")
        
        # Get all data
        cursor.execute(f"SELECT * FROM {table_name}")
        rows = cursor.fetchall()
        
        print(f"Total rows: {len(rows)}\n")
        
        for row in rows:
            print("-" * 40)
            for i, col_name in enumerate(column_names):
                value = row[i]
                
                # Try to convert timestamps
                if value and ('date' in col_name.lower() or 'time' in col_name.lower()):
                    try:
                        if isinstance(value, (int, float)) and value > 1000000000:
                            if value > 10000000000:  # Milliseconds
                                value = f"{value} ({datetime.fromtimestamp(value/1000)})"
                            else:  # Seconds
                                value = f"{value} ({datetime.fromtimestamp(value)})"
                    except:
                        pass
                
                if value is not None and str(value).strip():
                    print(f"{col_name}: {value}")
    
    conn.close()

def export_to_text(db_path, output_path):
    """
    Export database contents to a text file.
    """
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
    tables = cursor.fetchall()
    
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write("DATABASE EXPORT\n")
        f.write(f"Source: {db_path}\n")
        f.write(f"Exported: {datetime.now()}\n")
        f.write("=" * 80 + "\n\n")
        
        for table in tables:
            table_name = table[0]
            if table_name.startswith('android_') or table_name.startswith('sqlite_'):
                continue
            
            cursor.execute(f"PRAGMA table_info({table_name})")
            columns = [col[1] for col in cursor.fetchall()]
            
            cursor.execute(f"SELECT * FROM {table_name}")
            rows = cursor.fetchall()
            
            f.write(f"\n{'='*80}\n")
            f.write(f"TABLE: {table_name} ({len(rows)} rows)\n")
            f.write(f"{'='*80}\n\n")
            
            for row in rows:
                for i, col in enumerate(columns):
                    if row[i] is not None:
                        f.write(f"{col}: {row[i]}\n")
                f.write("-" * 40 + "\n")
    
    conn.close()
    print(f"Exported to: {output_path}")

if __name__ == "__main__":
    import sys
    
    if len(sys.argv) < 2:
        print("Usage: python read_database.py <database.db> [output.txt]")
        sys.exit(1)
    
    db_file = sys.argv[1]
    read_database(db_file)
    
    if len(sys.argv) > 2:
        export_to_text(db_file, sys.argv[2])
```

### 6.2 Run Database Reader

```powershell
# Just view the database
python read_database.py extracted_data/apps/com.app/db/database.db

# Export to text file
python read_database.py extracted_data/apps/com.app/db/database.db output.txt
```

### 6.3 Using GUI Tools

You can also use GUI tools to browse SQLite databases:

- [DB Browser for SQLite](https://sqlitebrowser.org/) (Free)
- [SQLiteStudio](https://sqlitestudio.pl/) (Free)
- [DBeaver](https://dbeaver.io/) (Free)

---

## Alternative Methods

### Method A: Root Access (Emulator Only)

```powershell
# Get root access
adb root

# Access app data directly
adb shell ls /data/data/com.package.name/

# Pull entire app data folder
adb pull /data/data/com.package.name/ ./app_data/
```

### Method B: Run-As (Debuggable Apps Only)

```powershell
# Enter app context
adb shell run-as com.package.name

# Copy database to accessible location
cp databases/data.db /sdcard/data.db
exit

# Pull from device
adb pull /sdcard/data.db
```

### Method C: Using Android Backup Extractor (ABE)

For encrypted backups or more control:

1. Download [ABE](https://github.com/nelenkov/android-backup-extractor/releases)
2. Run:
```powershell
java -jar abe.jar unpack backup.ab backup.tar [password]
```

---

## Troubleshooting

### Problem: ADB device not found

```powershell
# Solution 1: Restart ADB
adb kill-server
adb start-server

# Solution 2: Check emulator ADB setting
# Bluestacks → Settings → Advanced → Enable ADB

# Solution 3: Try different ports
adb connect localhost:5555
adb connect localhost:5556
```

### Problem: Backup file is too small (< 1KB)

**Causes:**
- App doesn't allow backup (`android:allowBackup="false"`)
- App has no data yet
- You didn't confirm backup on device

**Solutions:**
- Open the app first and create some data
- Use root method instead
- Check if confirmation dialog appeared

### Problem: "Permission denied" when accessing data

```powershell
# Try getting root
adb root

# Or use backup method instead of direct pull
adb backup -f backup.ab -apk com.package.name
```

### Problem: Encrypted backup

```powershell
# Use ABE with password
java -jar abe.jar unpack backup.ab backup.tar "your_password"

# If no password was set, try empty password
java -jar abe.jar unpack backup.ab backup.tar ""
```

### Problem: Shell commands close immediately

This happens with some emulators. Solutions:
- Use Bluestacks' own ADB: `C:\Program Files\BlueStacks_nxt\HD-Adb.exe`
- Try `adb exec-out` instead of `adb shell`
- Restart the emulator

---

## Common App Data Locations

### Database Names by App Type

| App Category | Common Database Names |
|--------------|----------------------|
| **Diary/Notes** | `diary.db`, `notes.db`, `entries.db`, `journal.db` |
| **Messaging** | `messages.db`, `chat.db`, `conversations.db` |
| **WhatsApp** | `msgstore.db`, `wa.db`, `contacts.db` |
| **Social Media** | `database.db`, `user.db`, `feed.db` |
| **Photos/Gallery** | `media.db`, `photos.db`, `gallery.db` |
| **Games** | `save.db`, `game.db`, `progress.db`, `player.db` |
| **Finance** | `transactions.db`, `accounts.db`, `wallet.db` |
| **Health/Fitness** | `health.db`, `workout.db`, `steps.db` |

### File Locations

| Data Type | Typical Location |
|-----------|-----------------|
| **Databases** | `db/` folder |
| **Images/Photos** | `f/attachments/`, `f/images/`, `f/media/` |
| **Downloads** | `f/downloads/` |
| **Cache** | `f/cache/`, `r/cache/` |
| **Settings** | `sp/*.xml` |

---

## Quick Reference

### Complete Workflow Commands

```powershell
# 1. Connect to emulator
adb devices

# 2. Install app
adb install app.apk

# 3. Create backup (confirm on device!)
adb backup -f backup.ab -apk com.package.name

# 4. Extract backup
python extract_backup.py backup.ab extracted_data

# 5. Read database
python read_database.py extracted_data/apps/com.package.name/db/data.db
```

### Flowchart

```
┌─────────────────────────────────┐
│     Have APK + Need Data        │
└─────────────────┬───────────────┘
                  ▼
┌─────────────────────────────────┐
│   Install Emulator (Bluestacks) │
│   Enable ADB in Settings        │
└─────────────────┬───────────────┘
                  ▼
┌─────────────────────────────────┐
│   adb install app.apk           │
└─────────────────┬───────────────┘
                  ▼
┌─────────────────────────────────┐
│   adb backup -f backup.ab       │
│   -apk com.package.name         │
│                                 │
│   ⚠️ Tap "Back up" on screen    │
└─────────────────┬───────────────┘
                  ▼
┌─────────────────────────────────┐
│   python extract_backup.py      │
│   backup.ab extracted_data      │
└─────────────────┬───────────────┘
                  ▼
┌─────────────────────────────────┐
│   Browse extracted_data/        │
│   ├── db/ → SQLite databases    │
│   ├── f/  → Files, images       │
│   └── sp/ → Settings (XML)      │
└─────────────────┬───────────────┘
                  ▼
┌─────────────────────────────────┐
│   python read_database.py       │
│   extracted_data/.../db/data.db │
│                                 │
│   ✅ Data Recovered!            │
└─────────────────────────────────┘
```

---

## Resources

- [ADB Documentation](https://developer.android.com/studio/command-line/adb)
- [Android Backup Extractor](https://github.com/nelenkov/android-backup-extractor)
- [DB Browser for SQLite](https://sqlitebrowser.org/)
- [Bluestacks](https://www.bluestacks.com/)

---

## License

This guide is provided for educational and personal data recovery purposes only. Always respect privacy laws and only recover data you have legal rights to access.

---

*Guide created: November 2025*
