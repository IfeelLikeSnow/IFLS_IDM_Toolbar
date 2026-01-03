# IFLS_IDM_Toolbar — Repo package (download build)

## Validate the index
Run from repo root:

```bash
python tools/validate_reapack_index.py
```

## Publish to GitHub
1. Create an empty GitHub repository named `IFLS_IDM_Toolbar` (or any name you like).
2. Upload/commit all files from this folder to the `main` branch.
3. The ReaPack import URL will be:

```text
https://raw.githubusercontent.com/<YOUR_USER>/<YOUR_REPO>/main/index.xml
```

In REAPER: **Extensions → ReaPack → Import repositories…** and paste the URL.

## Troubleshooting
- If ReaPack sync fails with URL errors, re-run the validator.
- If packages don't update, bump the `<version name="...">` in `index.xml` to a newer value.
