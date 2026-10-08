# keystore/

## `ci-debug.keystore` — committed on purpose

This is a **throwaway debug key**, not a release key, and it is committed to the repository
deliberately. `app/build.gradle` uses it for debug builds.

**Why it exists.** Android refuses to install an update whose signature differs from the installed
app. GitHub's build runners are ephemeral: `~/.android/debug.keystore` does not exist on a fresh
runner, so Gradle generates a **new random key on every run**. The practical effect was that each
new debug APK from CI failed to install over the previous one with a plain "App not installed".
Committing one fixed key makes every debug build share the same signature, so debug builds update
in place.

**The trade-off, stated plainly.** Because the key and its password (`android`) are public, anyone
can produce an APK that Android will accept as an update to an installed **debug** build. That is
acceptable for a debug channel, and it is why this key must never be used for a release build:

- Debug builds are `app.ktv.reader.debug`.
- Release builds are `app.ktv.reader`, signed with a separate private key supplied through
  repository secrets (see `FORK_NOTES.md`), and they are what the in-app updater uses.

The two never share a signing identity, so the debug key cannot be used to update a release install.

## Rotating it

If you ever replace `ci-debug.keystore`, update the expected fingerprint in
`.github/workflows/build.yml` (step *Enforce stable debug signing*), which fails the build when the
APK signature does not match. Rotating means installed debug builds must be uninstalled once.
