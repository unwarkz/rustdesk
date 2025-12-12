# FixIT Connect Build Workflows

## Manual Release Build

### Workflow: `fixit-release.yml`

**Purpose**: Build and release FixIT Connect v1.4.4 for all platforms

**Trigger**: Manual only (workflow_dispatch)

**Platforms**:
- Windows (x64)
- Linux (x64)
- Android (arm64)
- iOS (universal)
- macOS (universal)

### How to Run

1. Navigate to **Actions** tab in GitHub
2. Select **"FixIT Connect v1.4.4 Release Build"**
3. Click **"Run workflow"** dropdown
4. (Optional) Modify release tag (default: `fixit-v1.4.4`)
5. Click **"Run workflow"** button

### Build Process

The workflow performs the following steps for each platform:

1. **Generate Bridge Files** (once, shared across all builds)
   - Generates Rust-Flutter bridge code
   - Uploads as artifact for other jobs

2. **Generate Icons** (per platform)
   - Runs `generate_fixit_icons.sh`
   - Creates all required icon sizes

3. **Build Platform Binary** (per platform)
   - Installs dependencies (vcpkg for C++ libs)
   - Builds Flutter application
   - Builds Rust backend
   - Packages platform-specific artifacts

4. **Create GitHub Release**
   - Collects all platform artifacts
   - Creates release with tag `fixit-v1.4.4`
   - Uploads all artifacts to release

### Expected Artifacts

| Platform | Artifact Name | Size (approx) | Notes |
|----------|--------------|---------------|-------|
| Windows | fixit-connect-windows-x64 | ~50MB | Unsigned EXE |
| Linux | fixit-connect-linux-x64.tar.gz | ~40MB | Includes icons & .desktop |
| Android | fixit-connect-android-arm64.apk | ~30MB | arm64-v8a only |
| iOS | fixit-connect-ios.ipa | ~25MB | Unsigned, needs sideload |
| macOS | fixit-connect-macos.dmg | ~45MB | Unsigned DMG |

### Build Time

- **Total**: ~45-60 minutes
- **Per platform**: ~10-15 minutes
- **Parallel execution**: All platforms build simultaneously

### Requirements

**Build Dependencies** (auto-installed by workflow):
- Rust toolchain (1.75 for most, 1.81 for macOS)
- Flutter SDK (3.24.5)
- Platform-specific SDKs (NDK for Android, Xcode for iOS/macOS)
- vcpkg for C++ dependencies
- ImageMagick & Inkscape for icon generation

**Secrets** (optional, not currently used):
- `ANDROID_SIGNING_KEY` - For Android app signing
- `MACOS_P12_BASE64` - For macOS code signing
- `SIGN_BASE_URL` - For code signing service

### Troubleshooting

**If build fails**:

1. Check job logs in Actions tab
2. Common issues:
   - **vcpkg timeout**: Retry workflow
   - **Flutter version mismatch**: Update FLUTTER_VERSION in workflow
   - **Icon generation fails**: Ensure ImageMagick is installed
   - **Bridge generation fails**: Check Rust toolchain version

**If artifacts missing**:
- Ensure all jobs completed successfully
- Check "Create Release" job logs
- Verify artifact upload steps

### Configuration

Edit `.github/workflows/fixit-release.yml` to modify:

```yaml
env:
  VERSION: "1.4.4"                    # App version
  TAG_NAME: "fixit-v1.4.4"            # Release tag
  FLUTTER_VERSION: "3.24.5"           # Flutter SDK version
  RUST_VERSION: "1.75"                # Rust version (most platforms)
  MAC_RUST_VERSION: "1.81"            # Rust version (macOS only)
  NDK_VERSION: "r27c"                 # Android NDK version
  VCPKG_COMMIT_ID: "120deac..."       # vcpkg version
```

### Release Notes Template

When release is created, it includes:

```markdown
# FixIT Connect v1.4.4

Cross-platform remote desktop application built on RustDesk.

## Downloads

- **Windows**: fixit-connect-windows-x64
- **Linux**: fixit-connect-linux-x64.tar.gz
- **Android**: fixit-connect-android-arm64.apk
- **iOS**: fixit-connect-ios.ipa (requires sideloading)
- **macOS**: fixit-connect-macos.dmg (not signed)

## Features

- Remote desktop control
- File transfer
- Built on open-source RustDesk
- Visit https://fixit.kz for more information

## Notes

- No code signing applied
- Manual installation required on some platforms
```

### Security Considerations

1. **No Secrets in Code**: All sensitive data via GitHub Secrets
2. **Unsigned Builds**: Users will see security warnings
3. **Artifact Scanning**: Consider adding virus scanning step
4. **Dependency Versions**: Pinned for reproducibility

### Maintenance

**Regular Updates**:
- Update Flutter version quarterly
- Update Rust version as needed
- Update vcpkg commit ID monthly
- Test builds after major dependency updates

**Version Bumps**:
1. Update `VERSION` in workflow
2. Update `TAG_NAME` to match
3. Update Cargo.toml version
4. Commit and tag repository

### Related Files

- **Icon Script**: `/generate_fixit_icons.sh`
- **Build Script**: `/build.py`
- **Documentation**: `/FIXIT_REBRANDING.md`
- **Desktop Entry**: `/res/fixit-connect.desktop`

### Support

For build issues:
- Check GitHub Actions logs
- Review FIXIT_REBRANDING.md
- Consult RustDesk build documentation

For application issues:
- Visit https://fixit.kz
- Check RustDesk documentation
