# sys-monitoring_python

A small Python system resource monitoring app deployed to Kubernetes on DigitalOcean. This repository contains the application code, Dockerfile, Terraform infra to create a DigitalOcean Container Registry and kubernetes cluster, and GitHub Actions workflows to build/publish the image and deploy.

## Repository layout
- `.github/workflows/`
  - `build-image.yml` — CI to build, tag and push Docker images to DigitalOcean registry
  - `main.yml` / `app-infra.yml` — Terraform CI (infra automation)
- `Dockerfile` — application image build instructions
- `requirements.txt` — Python dependencies
- `template/` — (optional) deployment manifests / templates
- `*.tf` — Terraform files (create registry / infra)
- `README.md` — this file

## Features
- Builds a Docker image for the Python system-monitoring app
- Pushes image to DigitalOcean Container Registry
- Terraform to provision registry and kubernetes cluster (and other infra if added)
- CI via GitHub Actions for build/push and infra workflows
- Deployment to the DigitalOcean Kubernetes cluster

## Prerequisites
- Docker installed (local testing)
- doctl (DigitalOcean CLI) for registry auth or Docker login with DO token
- Terraform (if using infra steps locally)
- GitHub repository with Actions enabled
- A DigitalOcean API token with registry and (if needed) Kubernetes access

## Required repository secrets / variables (GitHub)
- `DO_CONNECT_TOKEN` (or `DO_TOKEN`) — DigitalOcean API token (store in Repository Secrets)
- (Optional) `DO_CLUSTER_NAME` — name of the Kubernetes cluster (if deploying via workflow)
- Keep Terraform token usage as `TF_VAR_do_token` if you export via env in workflow or use a `terraform.tfvars` file.

## Quickstart — local (build & push)
1. Authenticate locally (doctl):
   - doctl auth init -t <YOUR_DIGITALOCEAN_TOKEN>
   - doctl registry login
2. Build and tag:
   - docker build -t registry.digitalocean.com/<REGISTRY_NAME>/<IMAGE_NAME>:latest .
     Example: docker build -t registry.digitalocean.com/smoke/python-app:latest .
3. Push:
   - docker push registry.digitalocean.com/<REGISTRY_NAME>/<IMAGE_NAME>:latest

## Quickstart — Terraform (local)
1. Create `terraform.tfvars` or use `-var-file` when running terraform to avoid interactive prompts for tokens:
   - terraform.tfvars:
     ```
     do_token = "dop_..."
     region   = "XYZ"
     ```
2. Init & apply:
   - terraform init
   - terraform apply -auto-approve

3. Terraform will create the container registry and the kubernetes cluster (if configured in the `.tf` files).

Note: Terraform reads variables defined in `variable.tf`. You may set environment variables prefixed with `TF_VAR_` (e.g. `export TF_VAR_do_token="..."`) before running Terraform.

## CI (GitHub Actions) behavior
- `build-image.yml`
  - Trigger: `workflow_dispatch` and push to `python-app-deployment` (or configured branch)
  - Steps: checkout, authenticate to DO registry (use action or doctl), build image, tag with `latest` and a unique tag (recommended), push tags.
  - Make sure `with:` inputs use GitHub expression syntax: `token: ${{ secrets.DO_CONNECT_TOKEN }}` or `token: ${{ env.DO_CONNECT_TOKEN }}`. Do not pass raw `$DO_CONNECT_TOKEN` to `with:` as it will be literal.

- Infra workflow (Terraform)
  - Trigger: `workflow_dispatch` and push to infra branch (e.g. `deployment-infra`)
  - Ensure workflow file exists on the repository default branch to see the "Run workflow" button in Actions UI (or use `gh workflow run ... --ref <branch>`).

Example recommended image tagging in CI:
```bash
IMAGE=registry.digitalocean.com/smoke/python-app
UNIQUE_TAG=${{ github.run_number }}   # or github.run_id / short sha
docker build -t $IMAGE:$UNIQUE_TAG -t $IMAGE:latest .
docker push $IMAGE:$UNIQUE_TAG
docker push $IMAGE:latest
```

## Deploying to Kubernetes (CI step example)
- Authenticate doctl in workflow: use `digitalocean/action-doctl@v2` with `token: ${{ secrets.DO_CONNECT_TOKEN }}`
- Save kubeconfig: `doctl kubernetes cluster kubeconfig save "$DO_CLUSTER_NAME"`
- Update deployment image:
  - kubectl set image deployment/"$DEPLOYMENT_NAME" "$CONTAINER_NAME"="$REGISTRY/$IMAGE_NAME:$UNIQUE_TAG" -n <namespace>
  - kubectl rollout status deployment/"$DEPLOYMENT_NAME" -n <namespace>

Always validate `DO_CLUSTER_NAME` (non-empty) before calling doctl.

## Troubleshooting
- "unauthorized: authentication required" on docker push → authenticate first (doctl registry login or docker login), ensure token has correct scopes and is stored correctly in GitHub Secrets (no trailing newline).
- Action inputs: use `${{ secrets.NAME }}` for `with:` fields; use `$VAR` in `run:` shell steps.
- Missing "Run workflow" button → workflow file must be present on repository default branch or use `gh` CLI to trigger on a non-default branch.
- YAML/indentation issues → validate with `yamllint` or ensure strict indentation.

## Useful commands
- Check workflows on runner:
  - gh workflow list
  - gh workflow run <workflow_file> --ref <branch>
- Show file with numbers:
  - cat -n .github/workflows/build-image.yml

## License
MIT (or change as appropriate)

---
Placeholders in this README (registry name, token names, cluster name) should be replaced with repo-specific values. Commit this file to the repo root to provide a clear project overview
