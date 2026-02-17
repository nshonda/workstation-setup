# SSH & Multi-Account GitHub

## SSH Config Structure

`setup-ssh.sh` creates two RSA keys:

| Key | Purpose |
|-----|---------|
| `id_rsa_mac` | Personal GitHub account (nshonda) |
| `id_rsa_basis_mac` | Work GitHub account (natalihonda-basis) |

### `~/.ssh/config`

```
Host github.com
    IdentityFile ~/.ssh/id_rsa_mac

Host github.com-natalihonda-basis
    HostName github.com
    IdentityFile ~/.ssh/id_rsa_basis_mac
```

### `~/.ssh/config.local`

Machine-specific overrides. On macOS, this adds `UseKeychain yes`.

## Cloning with the Right Identity

```bash
# Personal repos — use github.com as normal
git clone git@github.com:nshonda/my-repo.git

# Work repos — use the host alias
git clone git@github.com-natalihonda-basis:basis-org/work-repo.git
```

## Conditional Git Identity

`setup-git.sh` configures:

```gitconfig
[user]
    name = Natali Honda
    email = natalihonda@gmail.com

[includeIf "gitdir:~/workstation/work/"]
    path = ~/.gitconfig-basis
```

Any repo under `~/workstation/work/` automatically uses the work email. Everything else uses the personal email.

## Verifying

```bash
# Check which key GitHub sees
ssh -T git@github.com
ssh -T git@github.com-natalihonda-basis

# Check git identity in a repo
cd ~/workstation/work/some-repo
git config user.email  # should show work email
```
