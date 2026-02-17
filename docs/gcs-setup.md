# GCS Setup (for Interactive Plans)

The `interactive-plan` skill can upload HTML architecture plans to a Google Cloud Storage bucket for sharing. This is optional.

## 1. Authenticate

```bash
gcloud auth login
```

This opens a browser to sign in with your Google account.

## 2. Create a Project (if needed)

```bash
# List existing projects
gcloud projects list

# Create a new one
gcloud projects create <PROJECT_ID> --name="<Project Name>"

# Set it as default
gcloud config set project <PROJECT_ID>
```

## 3. Create a Bucket

```bash
# Create a bucket (name must be globally unique)
gcloud storage buckets create gs://<BUCKET_NAME> --location=us-central1

# Make objects publicly readable by default (for sharing plan URLs)
gcloud storage buckets update gs://<BUCKET_NAME> --uniform-bucket-level-access
gcloud storage buckets add-iam-policy-binding gs://<BUCKET_NAME> \
    --member=allUsers --role=roles/storage.objectViewer
```

## 4. Set the Bucket in Setup

When running `./scripts/setup-claude.sh`, enter your bucket name at the GCS prompt. This fills in the `interactive-plan` skill config.

To update it later, edit `~/.claude/skills/interactive-plan/SKILL.md` and replace the bucket name.

## Usage

Once configured, use the skill in Claude Code:

```
/interactive-plan --gcs              # Upload to your default bucket
/interactive-plan --gcs other-bucket # Upload to a different bucket
```

Plans are accessible at `https://storage.googleapis.com/<BUCKET_NAME>/<filename>.html`.
