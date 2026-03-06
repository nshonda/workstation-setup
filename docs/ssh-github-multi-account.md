# SSH & Multi-Account GitHub

## SSH Config Structure

`setup-ssh.sh` creates two RSA keys:

| Key | Purpose |
|-----|---------|
| `id_rsa_mac` | Personal GitHub account |
| `id_rsa_work_mac` | Work GitHub account |

### `~/.ssh/config`

The main config defines hosts with `IdentitiesOnly` but delegates key paths to `config.local`:

```
# Personal GitHub Account
Host github.com
    HostName github.com
    User git
    IdentitiesOnly yes

# Work GitHub Account
Host github.com-<WORK_GH_USERNAME>
    HostName github.com
    User git
    IdentitiesOnly yes

# Common SSH settings
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3
    AddKeysToAgent yes

# Include machine-specific key mappings
Include ~/.ssh/config.local
```

### `~/.ssh/config.local`

Machine-specific key paths and overrides. Created once by `setup-ssh.sh`, not overwritten on re-runs. On macOS, this adds `UseKeychain yes`:

```
# Personal GitHub - Mac key
Host github.com
    IdentityFile ~/.ssh/id_rsa_mac
    UseKeychain yes

# Work GitHub - Mac key
Host github.com-<WORK_GH_USERNAME>
    IdentityFile ~/.ssh/id_rsa_work_mac
    UseKeychain yes
```

On Linux/WSL, the same without `UseKeychain`.

## Cloning with the Right Identity

```bash
# Personal repos — use github.com as normal
git clone git@github.com:<PERSONAL_GH_USERNAME>/my-repo.git

# Work repos — use the host alias
git clone git@github.com-<WORK_GH_USERNAME>:<WORK_ORG>/work-repo.git
```

## Conditional Git Identity

`setup-git.sh` configures:

```gitconfig
[user]
    name = <YOUR_NAME>
    email = <PERSONAL_EMAIL>

[includeIf "gitdir:~/workstation/work/"]
    path = ~/.gitconfig-work
```

Any repo under `~/workstation/work/` automatically uses the work email. Everything else uses the personal email.

## Verifying

```bash
# Check which key GitHub sees
ssh -T git@github.com
ssh -T git@github.com-<WORK_GH_USERNAME>

# Check git identity in a repo
cd ~/workstation/work/some-repo
git config user.email  # should show work email
```
