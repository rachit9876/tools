# tools

```
from google.colab import files
import os, shutil

# Upload any file (Chrome cache, memory dump, disk image, etc.)
uploaded = files.upload()
filename = list(uploaded.keys())[0]

out_dir = "extracted_images"
os.makedirs(out_dir, exist_ok=True)

def save_image(data, start, end, ext, counter):
    img = data[start:end]
    fname = os.path.join(out_dir, f"{ext}_{start}_{counter}.{ext}")
    with open(fname, "wb") as f:
        f.write(img)
    return 1

with open(filename, "rb") as f:
    raw = f.read()

count = {}

# --- JPEG ---
sig, end = b"\xFF\xD8\xFF", b"\xFF\xD9"
count['jpg'] = 0
pos = 0
while True:
    s = raw.find(sig, pos)
    if s == -1: break
    e = raw.find(end, s)
    if e == -1: break
    e += len(end)
    count['jpg'] += save_image(raw, s, e, "jpg", count['jpg'])
    pos = e

# --- PNG ---
sig, end = b"\x89PNG", b"IEND\xAE\x42\x60\x82"
count['png'] = 0
pos = 0
while True:
    s = raw.find(sig, pos)
    if s == -1: break
    e = raw.find(end, s)
    if e == -1: break
    e += len(end)
    count['png'] += save_image(raw, s, e, "png", count['png'])
    pos = e

# --- GIF ---
sig = b"GIF89a"
end = b"\x00\x3B"
count['gif'] = 0
pos = 0
while True:
    s = raw.find(sig, pos)
    if s == -1: break
    e = raw.find(end, s)
    if e == -1: break
    e += len(end)
    count['gif'] += save_image(raw, s, e, "gif", count['gif'])
    pos = e

# --- BMP ---
sig = b"BM"
count['bmp'] = 0
pos = 0
while True:
    s = raw.find(sig, pos)
    if s == -1: break
    # BMP size is at offset +2
    size = int.from_bytes(raw[s+2:s+6], "little")
    e = s + size
    if e > len(raw): break
    count['bmp'] += save_image(raw, s, e, "bmp", count['bmp'])
    pos = e

# --- ICO ---
sig = b"\x00\x00\x01\x00"
count['ico'] = 0
pos = 0
while True:
    s = raw.find(sig, pos)
    if s == -1: break
    # crude cutoff (limit 1MB per icon)
    e = min(s+1048576, len(raw))
    count['ico'] += save_image(raw, s, e, "ico", count['ico'])
    pos = e

# --- WebP ---
count['webp'] = 0
pos = 0
while True:
    s = raw.find(b"RIFF", pos)
    if s == -1: break
    if raw[s+8:s+12] == b"WEBP":
        size = int.from_bytes(raw[s+4:s+8], "little") + 8
        e = s + size
        count['webp'] += save_image(raw, s, e, "webp", count['webp'])
        pos = e
    else:
        pos = s + 4

# --- AVIF / HEIF ---
count['avif'] = 0
pos = 0
while True:
    s = raw.find(b"ftypavif", pos)
    if s == -1: break
    e = min(s+1048576, len(raw))
    count['avif'] += save_image(raw, s, e, "avif", count['avif'])
    pos = e

count['heic'] = 0
pos = 0
while True:
    s = raw.find(b"ftypheic", pos)
    if s == -1: break
    e = min(s+1048576, len(raw))
    count['heic'] += save_image(raw, s, e, "heic", count['heic'])
    pos = e

print("Extraction complete:", count)

# Pack into zip for download
shutil.make_archive("images_dump", 'zip', out_dir)
files.download("images_dump.zip")

```
