# Converting S3WaaS `bfi_thumb` URLs to Original (High-Quality) Images

## Overview

Many WordPress-based S3WaaS (Secure, Scalable and Sugamya Website as a Service) websites use the **BFI Thumb** image resizing plugin.

A thumbnail URL often looks like this:

```text
https://<domain>/uploads/bfi_thumb/2024060757-qpamoan76czql1kkd00h76ek8lvlysyz3nlg1gd54g.jpeg
```

In many deployments, the original image is still publicly available in the normal WordPress `uploads` directory.

---

## Conversion Rule

Starting URL:

```text
/uploads/bfi_thumb/YYYYMMDDNN-<random_hash>.ext
```

Convert it to:

```text
/uploads/YYYY/MM/YYYYMMDDNN.ext
```

### Steps

1. Remove the `bfi_thumb/` directory.
2. Remove everything after the **first hyphen (`-`)**.
3. Extract the year and month from the filename.

   * First 4 digits → Year
   * Next 2 digits → Month
4. Insert `YYYY/MM/` after `/uploads/`.
5. Keep the original file extension (`.jpg`, `.jpeg`, `.png`, etc.).

---

## Example

### Thumbnail

```text
https://cdnbbsr.s3waas.gov.in/s3kv02b06301ed613de8790e9a2bb82b9c/uploads/bfi_thumb/2024060757-qpamoan76czql1kkd00h76ek8lvlysyz3nlg1gd54g.jpeg
```

### Converted Original

```text
https://cdnbbsr.s3waas.gov.in/s3kv02b06301ed613de8790e9a2bb82b9c/uploads/2024/06/2024060757.jpeg
```

---

## General Pattern

```text
Thumbnail
---------
https://domain/uploads/bfi_thumb/<filename>-<hash>.<ext>

↓

Original
--------
https://domain/uploads/<YYYY>/<MM>/<filename>.<ext>
```

---

## Filename Mapping

| Thumbnail Filename          | Original Filename |
| --------------------------- | ----------------- |
| `2024060757-abcdef.jpeg`    | `2024060757.jpeg` |
| `2025011234-randomhash.jpg` | `2025011234.jpg`  |
| `2023120001-xyz.png`        | `2023120001.png`  |

---

## Notes

* This works only when the original image is publicly accessible.
* Some S3WaaS deployments may delete or relocate the original image after generating thumbnails.
* The directory structure can vary depending on the site's WordPress configuration.
* If the converted URL returns **404 Not Found**, the original image is either unavailable or stored using a different layout.

---

## Quick Algorithm

```text
Input:
https://domain/uploads/bfi_thumb/FILENAME-HASH.EXT

1. Remove "bfi_thumb/"
2. Remove "-HASH"
3. YEAR = first 4 digits of FILENAME
4. MONTH = digits 5–6 of FILENAME
5. Output:
https://domain/uploads/YEAR/MONTH/FILENAME.EXT
```

---

## Example Transformation

```text
Input
https://domain/uploads/bfi_thumb/2024060757-qpamoan76czql1kkd00h76ek8lvlysyz3nlg1gd54g.jpeg

↓

Output
https://domain/uploads/2024/06/2024060757.jpeg
```
