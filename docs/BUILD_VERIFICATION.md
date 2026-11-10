# Verification record for 0.1.247

This records the source and offline checks for the update from GitHub main
0.1.239 to 0.1.247. It is not a claim of verified live-client rendering,
taint safety, protected API compatibility, or frame-time improvement.

- Runtime: 15 Lua modules in matching standard and Camelot manifests.
- Current regression suites: 35 files directly under `tests/`, run on both
  Lua 5.1 and Lua 5.4. Historical subdirectories are separate baselines.
- Package: 17 files under one `bjarkiPortraits/` folder.
- The portable verifier rebuilt a package whose every member matched the
  previously delivered 0.1.247 ZIP byte for byte.
- Cross-addon startup was checked in both addon load orders with empty,
  compatible and incompatible evidence bridges on both Lua engines.

## Source identity

[Source SHA-256 manifest](SOURCE_SHA256_0.1.247.txt) records the runtime files,
manifests and any shipped media. Paths are relative to the addon root.
This manifest is historical evidence for 0.1.247; update it only when making
an intentional new verification record, not to silence a mismatch.

The previously delivered `bjarkiPortraits-0.1.247-COMPLETE.zip` had SHA-256:

```text
ecbe46b2edd8183f1f6d0d18370466a4a445dde45727cf685c112dbd8d4bd2e9
```

ZIP timestamps and other archive metadata can differ between builds. Compare
the member hashes for source identity rather than treating a different archive
hash alone as a runtime change.

## Reproduce

From the repository root, use Python 3.10 or newer and Lua/luac 5.1 and 5.4:

```sh
python3 tools/verify.py --output ../bjarkiPortraits-0.1.247-COMPLETE.zip
```

The output path must not exist and must be outside the repository. Without
`--output`, the command validates manifests, compiles modules and tests, and runs
the current suites without creating a package. See [testing](TESTING.md) for
focused checks and the optional embedded Lua runner.

Local publication checks used Lupa's Lua 5.1 and Lua 5.4 engines. The
[package workflow](../.github/workflows/package-addon.yml) uses standalone
Lua/luac for both versions and produces the installable artifact. Check the
[workflow runs](https://github.com/bjoern-janson/bjarkiPortraits/actions/workflows/package-addon.yml?query=branch%3Amain)
for the exact commit before downloading.

## Evidence limit

Current open client reports remain in [known issues](../KNOWN_ISSUES.md).
Source comparisons and mocked API regressions establish the tested code paths;
they do not establish that every live timer, protected aura, or combat transition
behaves as modeled.
