# Release asset

The private Git repository contains the migration documentation, audit
metadata, manifests, and reproducible tools.

Release `backup-20260816` contains the portable installation payload:

```text
A3_1_PORTABLE_UPDATE_20260816.tar.zst
size:   1,587,215,633 bytes
sha256: 90009fc55beb88b7a2ad494e7172716016ad91e129d5cdccbe4cf8dd8eaa3ccb
```

The portable archive contains `deployment_payload/`, the migration tools,
README, checklist, and audit metadata. It intentionally excludes the roughly
10 GiB A3_2 raw snapshot and the A3_2-only Stage-2 chain, as documented in
`README.md`.

The full 19 GiB working backup remains on the source Mac at:

```text
/Users/hongdaliang/CODE/A3control/SYS_README/A3_2_to_A3_1_backup_20260816
```
