# Build Inkwell using only your Android phone

You need a GitHub account, browser and file manager that can extract ZIPs. No PC, terminal app, personal access token or local Flutter installation is required.

## 1. Download two files from this chat

- **inkwell-source.zip** — keep this exact filename. Do not extract it for the easy route below.
- **GitHub-Android-Build.yml** — workflow text to copy in step 4.

## 2. Create a repository

1. Sign in at **https://github.com/new** in your phone browser.
2. Name the repository `inkwell` (another name is fine).
3. Choose public or private, optionally add a README, and create it.
4. If controls are hidden, enable the browser's **Desktop site** option. Use GitHub's website; the mobile app may not expose file-upload and creation controls.

Check your account's current Actions limits/billing. Public repositories using standard hosted runners generally have free Actions usage; private repositories have plan-dependent allowances.

## 3. Upload the source ZIP

1. On the repository's Code page, choose **Add file → Upload files**. For an empty repository, use **uploading an existing file** instead.
2. Select `inkwell-source.zip` from Downloads.
3. Commit to the default branch (normally `main`).

The root must contain `inkwell-source.zip`. GitHub does not unpack ZIP files automatically. The workflow does this on its runner.

## 4. Create the workflow

1. Choose **Add file → Create new file**.
2. Enter this exact filename:

   `.github/workflows/android.yml`

3. Open **GitHub-Android-Build.yml** in this chat's viewer or a text editor on your phone. Copy **all** the text.
4. Paste into GitHub's editor and commit to the default branch.

Do not paste a personal token anywhere. No secrets are needed.

## 5. Build on GitHub

1. Open **Actions** and enable workflows if asked.
2. Select **Build Android APK**. A push may have already started a run.
3. Otherwise choose **Run workflow → Run workflow** on your default branch.
4. Wait for a green tick. The first build downloads the toolchain and can take several minutes. You can leave the page and return; the workflow has a 40-minute timeout.

GitHub runs dependency setup, analysis, tests and APK compilation on its servers.

## 6. Download and install

1. Open the successful run and scroll to **Artifacts**.
2. Download **Inkwell-test-APKs** while signed in.
3. Extract the artifact ZIP in your file manager.
4. Choose **app-arm64-v8a-debug.apk** for most modern phones. `app-armeabi-v7a-debug.apk` is for older 32-bit ARM devices. `app-x86_64-debug.apk` is for x86-64 Android devices/emulators.
5. Tap the APK and follow Android's installer. If asked, allow installation from that browser/file manager only if you trust the build; turn the permission off afterward. Do not disable device-wide protections to bypass a security warning.
6. Open **Inkwell**. Android 7.0 or later is required.

Artifacts are retained for 14 days. Run the workflow again if they expire.

## 7. Try the starter

- Library → Start reading → Next/Previous page.
- Reader settings → test all three reading directions.
- Return → History → resume a saved page.
- Browse → Samples → title details → save/remove.
- Settings → Dark theme.
- Browse → Extensions → inspect any system-installed extension packages.

**Version 0.2 adds experimental source execution.** See [Keiyoushi testing instructions](KEIYOUSHI_TESTING.md) and [the verification matrix](VALIDATION.md). Finding a package does not guarantee compatibility. Private extensions stored inside Mihon are not visible as system packages.

## Future updates

Replace the root `inkwell-source.zip` with the new archive using the same name and commit. Keep `.github/workflows/android.yml` outside the ZIP in the repository. Update that workflow too if a new project version supplies a changed one.

For normal source development later, unpack the archive at repository root so `pubspec.yaml` is at the root, and remove the uploaded ZIP. The workflow handles either layout. If both exist, the unpacked project takes priority.

## Troubleshooting

- **Hidden controls:** browser → Desktop site.
- **No Run workflow button:** workflow must exist on the default branch; sign in as an owner/collaborator with workflow permissions.
- **Red build:** open the failed step and share its error text or screenshot, without tokens or secret values.
- **Missing ZIP:** exact filename must be `inkwell-source.zip` at the repository root, not in a folder.
- **Conflicting package / app not installed:** debug keys can change between builds. Uninstalling an old Inkwell can fix signature conflicts, but **deletes all its library/progress data**. Stable release signing is future work.
- **No extensions found:** only system-installed APKs are discoverable, not private extensions inside other readers.

## Credential safety

This procedure does not need a GitHub token. Never put one in chat, workflow text, source files or commit messages. If you have exposed a token publicly or somewhere untrusted, revoke it in GitHub settings.
