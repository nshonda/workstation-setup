# SSH & Multi-Account GitHub

## SSH Config Structure

`setup-ssh.sh` creates two RSA keys:

| Key | Purpose |
|-----|---------|
| `id_rsa_mac` | Personal GitHub account |
| `id_rsa_basis_mac` | Work GitHub account |

### `~/.ssh/config`

```
Host github.com
    IdentityFile ~/.ssh/id_rsa_mac

Host github.com-<WORK_GH_USERNAME>
    HostName github.com
    IdentityFile ~/.ssh/id_rsa_basis_mac
```

### `~/.ssh/config.local`

Machine-specific overrides. On macOS, this adds `UseKeychain yes`.

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
    path = ~/.gitconfig-basis
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
