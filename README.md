# IFLS_IDM_Toolbar (minimal, stable ReaPack index)

This repo version is designed to avoid ReaPack install/path issues and GitHub Actions merge conflicts.

## ReaPack setup
Add repository index:
https://raw.githubusercontent.com/IfeelLikeSnow/IFLS_IDM_Toolbar/main/index.xml

Then: Extensions > ReaPack > Synchronize packages
Install: IFLS_IDM_Toolbar_Core

## Build & activate toolbar in REAPER
1) Actions: run "DF95_Build_IFLS_Main_Toolbar_MenuSet"
2) Options > Customize menus/toolbars...
3) Select "Floating toolbar 1"
4) Import/Export > Import toolbar...
5) Choose: MenuSets/IFLS_Main.Toolbar.ReaperMenuSet
6) View > Toolbars > Floating toolbar 1

## GitHub Desktop: fix "Resolve conflicts before Rebase (index.xml)"
If you see a rebase conflict on index.xml:
- Click "Abort rebase" (recommended), then apply the ZIP content and commit again.
Or via CMD (inside repo):
  git rebase --abort
  git fetch origin
  git reset --hard origin/main
  (copy ZIP files over your repo folder)
  git add -A
  git commit -m "Update to minimal stable ReaPack index"
  git push

If you MUST continue the rebase:
- Open index.xml and replace its full content with the one from this ZIP (no <<<<<< markers).
- git add index.xml
- git rebase --continue
- then push with: git push --force-with-lease
