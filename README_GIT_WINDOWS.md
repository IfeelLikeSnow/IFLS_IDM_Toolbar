# IFLS_IDM_Toolbar – Windows Git Setup (no Vim swap / fewer conflicts)

## 1) Set Git default editor (avoid Vim COMMIT_EDITMSG.swp)

### Option A: Notepad
```bat
git config --global core.editor "notepad"
git config --global --get core.editor
```

### Option B: VS Code
1) Ensure the `code` command exists:
```bat
where code
```
If not found: in VS Code run `Ctrl+Shift+P` → **Shell Command: Install 'code' command in PATH** (then reopen terminal).

2) Set editor:
```bat
git config --global core.editor "code --wait"
git config --global --get core.editor
```

## 2) If you see a Vim swap prompt
Choose `(D) Delete it`, or delete manually:
```bat
del /f /q "%CD%\.git\.COMMIT_EDITMSG.swp"
```

## 3) Clean rebase workflow (recommended)
```bat
git fetch origin
git pull --rebase origin main
git push
```
If conflicts happen:
```bat
git add <file>
git rebase --continue
```
Abort rebase:
```bat
git rebase --abort
```
