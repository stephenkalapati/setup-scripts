#!/usr/bin/env bash
# Installs and configures git

if [[ $SKIP_GIT ]]; then
    echo "SKIP_GIT is set. Skipping 15-git.sh"
    exit 0
fi

if [ "$OSNAME" = "Fedora Linux" ]; then
    echo "Ensuring git is installed"
    sudo dnf install git
fi

if [ "$OSNAME" = "Ubuntu" ]; then
    echo "Ensuring git is installed"
    sudo apt install git
fi

echo "Copying git configuration"
cp ${FILESDIR}/git/gitconfig ${HOME}/.gitconfig
cp ${FILESDIR}/git/gitconfig-dscrn ${HOME}/.gitconfig-dscrn

echo "Setting up git private key"
[[ -d ${HOME}/.ssh ]] && mkdir ${HOME}/.ssh
sops -d --extract '["github_rsa_priv_key"]' files/ssh/vault.sops.yml > ${HOME}/.ssh/github
chmod 600 ${HOME}/.ssh/github

echo "Copying pub key"
cp ${FILESDIR}/ssh/github.pub ${HOME}/.ssh/

echo "Setting up Code directories"
mkdir -p ${CODEDIR}/personal
mkdir -p ${CODEDIR}/public

echo "Downloading all personal github repos"
cd ${CODEDIR}/personal
GITHUB_TOKEN=$(sops -d --extract '["github_token"]' files/all/vault.sops.yml)
GITHUB_JSON=$(curl -H "Authorization: token ${GITHUB_TOKEN}" https://api.github.com/search/repositories\?q\=user:kentonspr)

for item in $(jq -c -r '.items[].ssh_url' <<< $GITHUB_JSON); do
    git clone $item
done
