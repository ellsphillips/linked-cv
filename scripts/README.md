# Scripts

This directory contains utility scripts for maintaining the linked-cv package.

## check_version.sh

Validates that all package version references in documentation and examples match the version specified in `typst.toml` (the source of truth).

Pure bash implementation using only standard Unix tools (grep, sed) with **zero dependencies**.

### Usage

```bash
# Check for version inconsistencies
./scripts/check_version.sh

# Automatically fix version inconsistencies
./scripts/check_version.sh --update
```

### What it checks

- `README.md` - All `@preview/linked-cv:VERSION` imports
- `example/cv.typ` - Package imports
- Any `.typ` files in the project root

### Install as pre-commit hook

To run this check before every commit, create a pre-commit hook:

```bash
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
echo "Running version consistency check..."
./scripts/check_version.sh
if [ $? -ne 0 ]; then
    echo ""
    echo "Version check failed! Commit aborted."
    echo "Please update package versions to match typst.toml"
    exit 1
fi
EOF

chmod +x .git/hooks/pre-commit
```

### Update package version

When updating the package version:

1. Update `version` in `typst.toml` (source of truth)
2. Run the update script to automatically fix all references:
   ```bash
   ./scripts/check_version.sh --update
   ```
3. Verify all changes:
   ```bash
   ./scripts/check_version.sh
   ```

The script will automatically update all version references in:
- Documentation files (README.md)
- Example files (example/cv.typ)
- Any .typ files in the project root
