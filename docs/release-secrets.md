# Release secrets

`release.yml` needs these GitHub repo secrets. No values here; this is where each comes
from.

| Secret | Source |
|---|---|
| `DEVELOPER_ID_CERTIFICATE_P12_BASE64` | Keychain → My Certificates → "Developer ID Application: Michal Palczewski (FS3CWH8867)" → Export `.p12` → `base64 -i dev-id.p12` |
| `DEVELOPER_ID_CERTIFICATE_PASSWORD` | Password set when exporting the `.p12` |
| `NOTARIZE_APPLE_ID` | Apple ID that owns team `FS3CWH8867` (`michalp@nimbusdev.io` or personal; `xcrun notarytool history --apple-id EMAIL --team-id FS3CWH8867 --password PWD` tells which) |
| `NOTARIZE_PASSWORD` | account.apple.com → Sign-In and Security → App-Specific Passwords → Generate |
| `NOTARIZE_TEAM_ID` | `FS3CWH8867` |
| `HOMEBREW_TAP_TOKEN` | github.com/settings/tokens → classic, scope `repo`, write access to `homebrew-occam` |

Set with `gh secret set <NAME> --repo mpalczew/occam`; check with `gh secret list`.
