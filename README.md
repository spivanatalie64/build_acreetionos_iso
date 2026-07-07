# build_acreetionos_iso

Standardized non-interactive build & test pipeline for all AcreetionOS distro variants.

## Files

| File | Purpose |
|------|---------|
| `build-all.sh` | Non-interactive orchestrator — builds base + all local variants + official remote repos |
| `test-iso.sh` | Automated ISO integrity checker |
| `Makefile` | Convenience targets: `make build-all`, `make test`, `make ci` |
| `.gitlab-ci.yml` | GitLab CI pipeline with variant matrix |
| `.github/workflows/build-test.yml` | GitHub Actions — container-based builds on GitHub-hosted runners |
| `setup-cron.sh` | Install systemd timer for daily automated builds |
| `webhook-trigger.sh` | Lightweight webhook listener for push-triggered builds |
| `build-trigger.service` | Systemd service for persistent webhook listener |

## Usage

```bash
./build-all.sh                    # build base + all variants + official remotes
./build-all.sh --only-official    # build only official (local + remote)
./build-all.sh --skip-official    # skip cinnamon-x11/cinnamon-xlibre
./build-all.sh --list             # list all variants
./build-all.sh cinnamon gnome     # build specific variants
./test-iso.sh                     # test all ISOs
make ci                           # full pipeline
```

## Official remote builds

Automatically clones and builds from:
- `github.com/acreetionos-code/acreetionos` → cinnamon-x11
- `github.com/acreetionos-code/acreetionos-xlibre` → cinnamon-xlibre

Cloned to `_official_builds/`, pulled fresh each run. Zero interaction required.

## Automated pipeline

### GitHub Actions (hosted runners)
- **cinnamon-x11**: builds in `archlinux:latest` container with `--privileged` for loop device support
- **cinnamon-xlibre**: builds on `ubuntu-latest` with xorriso
- **Triggers**: daily cron (6 AM), push to main, manual dispatch, or repository_dispatch webhook
- **Artifacts**: ISOs uploaded, test results logged, retained 7-30 days

### Systemd timer (daily builds on build server)
```bash
sudo ./setup-cron.sh
```

### Webhook trigger (push-triggered builds)
```bash
sudo cp build-trigger.service /etc/systemd/system/
sudo systemctl enable --now build-trigger
```

### Manual
```bash
./build-all.sh
./test-iso.sh
```