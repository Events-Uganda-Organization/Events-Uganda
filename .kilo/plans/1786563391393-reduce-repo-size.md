# Plan: Speed up repo cloning by removing unnecessary files

## Problem
The repo is ~1.2 GB locally but only ~56 MB is actually tracked by git. Cloning is slow because:
1. `node_modules/` and `otp-backend/node_modules/` are tracked (5000+ files, ~22 MB)
2. Large untracked build artifacts exist (`events_uganda/build/`: 1.07 GB, `.dart_tool/`: 58 MB)
3. `.gitignore` is nearly empty and doesn't exclude dependency/build folders

## Analysis
| Path | Size | Tracked? | Action |
|------|------|----------|--------|
| `events_uganda/build/` | 1079 MB | No | Delete locally |
| `events_uganda/.dart_tool/` | 58 MB | No | Delete locally |
| `.git/` | 50 MB | Yes | Keep |
| `node_modules/` | 15 MB | Yes (2541 files) | Remove from git, add to `.gitignore` |
| `otp-backend/` | 7.6 MB | Yes (2039 files) | Remove dependencies from git, add to `.gitignore` |
| `events_uganda/` (source) | 33 MB | Yes | Keep |
| `.idea/` | 0.1 MB | Yes (8 files) | Optional: remove from git |
| `otp-backend.zip` | 13.7 KB | Yes | Optional: remove |

## Steps

### 1. Update `.gitignore`
Add standard entries for Flutter, Node.js, and IDE files:
```
# Flutter
.dart_tool/
build/
*.iml

# Node.js
node_modules/
npm-debug.log*

# IDE
.idea/
.vscode/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Environment
.env
.env.local
.env.*.local

# Netlify
.netlify/

# Archives
*.zip
*.tar.gz
*.rar
```

### 2. Remove tracked `node_modules` from git
```bash
git rm -r --cached node_modules
git commit -m "Remove node_modules from tracking"
```

### 3. Remove tracked `otp-backend` dependencies from git
```bash
git rm -r --cached otp-backend/node_modules
git commit -m "Remove otp-backend node_modules from tracking"
```

### 4. Delete local untracked build artifacts
```bash
Remove-Item -Recurse -Force events_uganda/build
Remove-Item -Recurse -Force events_uganda/.dart_tool
```

### 5. Optional: Remove `.idea` from git tracking
```bash
git rm -r --cached .idea
git commit -m "Remove .idea from tracking"
```

### 6. Optional: Remove `otp-backend.zip`
```bash
git rm otp-backend.zip
git commit -m "Remove otp-backend.zip"
```

## After these changes
- Repo size on new laptop will be ~50-60 MB (tracked source + git history)
- Users run `npm install` / `flutter pub get` to regenerate dependencies
- `flutter build` recreates the `build/` folder as needed

## Validation
```bash
git ls-files | wc -l  # Should drop from 5004 to ~2400
du -sh .git          # Should be ~50 MB
git clone <repo>     # Should complete in seconds instead of minutes
```
