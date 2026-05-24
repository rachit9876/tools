# How to Completely Remove a User Account From Windows 11

This removes:

- the Windows account
- leftover profile folders
- old permissions/ACLs
- registry profile mappings

---

# 1. Remove the User Account

Open:

```text
Settings → Accounts → Other users
```

Select the user and click:

```text
Remove
```

---

# 2. Verify User Is Actually Deleted

Open PowerShell as Administrator:

```powershell
Get-LocalUser
```

or:

```powershell
net user
```

The deleted username should NOT appear.

---

# 3. Remove Leftover User Folder

Sometimes Windows deletes the account but leaves:

```text
C:\Users\<username>
```

Open PowerShell as Administrator and run:

```powershell
takeown /F "C:\Users\<username>" /R /D Y
icacls "C:\Users\<username>" /grant administrators:F /T
cmd /c rd /s /q "C:\Users\<username>"
```

Example:

```powershell
takeown /F "C:\Users\John" /R /D Y
icacls "C:\Users\John" /grant administrators:F /T
cmd /c rd /s /q "C:\Users\John"
```

---

# What These Commands Do

| Command | Purpose |
|---|---|
| `takeown` | takes ownership of files/folders |
| `icacls` | grants administrator full control |
| `rd /s /q` | recursively deletes the folder |

---

# Why Normal Delete Sometimes Fails

Windows user folders may contain:

- protected Microsoft Store app data
- TrustedInstaller owned files
- locked ACLs
- old NTFS junctions
- OneDrive/UWP cache data

So Explorer deletion often fails with:

```text
Access Denied
```

The commands above override those restrictions.

---

# 4. Optional Registry Cleanup

Press:

```text
Win + R
```

Run:

```text
regedit
```

Go to:

```text
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList
```

Delete SID keys whose:

```text
ProfileImagePath
```

points to:

```text
C:\Users\<username>
```

ONLY if the account is already deleted.

---

# 5. Verify Cleanup

Run:

```powershell
dir C:\Users
```

The old user folder should no longer exist.

---

# Notes

- `Application Data\Application Data...` recursion warnings are normal old Windows junction behavior.
- PowerShell `rd` is NOT CMD `rd`; use:

```powershell
cmd /c rd /s /q "C:\Users\<username>"
```

- Deleting many tiny files can be very slow even if total size is small.

---

# Complexity

If:

```text
n = total files + folders
```

then recursive ownership, ACL changes, and deletion are approximately:

```text
O(n)
```

Large file count matters more than total GB size.
