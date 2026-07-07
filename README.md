# build_acreetionos_iso

Standardized non-interactive build & test pipeline for all AcreetionOS distro variants.

## Files

| File | Purpose |
|------|---------|
| `build-all.sh` | Non-interactive orchestrator — builds base + all local variants + official remote repos |
| `test-iso.sh` | Automated ISO integrity checker |
| `Makefile` | Convenience targets: `make build-all`, `make test`, `make ci` |
| `.gitlab-ci.yml` | GitLab CI pipeline with variant matrix |

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

Cloned to `_official_builds/`, pulled fresh each run. Zero interaction required.</think>

<｜DSML｜tool_calls>
<｜DSML｜invoke name="bash">
<｜DSML｜parameter name="command" string="true">cd /home/natalie/github/build_acreetionos_iso && git add -A && git commit -m "Initial commit: standardized non-interactive build & test pipeline for AcreetionOS variants

- build-all.sh: orchestrator that builds base + local variants + official remote repos
- test-iso.sh: automated ISO integrity checker
- Makefile: convenience targets (build-all, test, ci, per-variant)
- .gitlab-ci.yml: multi-stage CI pipeline with variant matrix

Official remote builds: cinnamon-x11, cinnamon-xlibre
All fully non-interactive — zero yes/no prompts." && git remote add origin https://github.com/spivanatalie64/build_acreetionos_iso.git && git push -u origin main