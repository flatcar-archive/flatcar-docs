#!/bin/bash

set -euo pipefail

sudo apt-get install -y python3-venv mkdocs

git config --global user.name 'Flatcar Buildbot'
git config --global user.email 'buildbot@flatcar-linux.org'

# we need to add one ssh key after another, to work around
# issues when specifying multiple ssh keys to the agent.
eval "$(ssh-agent -s)"
ssh-add - <<< "${FLATCAR_WEBSITE_DOCS_GITHUB_ACTIONS_KEY}"
git clone git@github.com:kinvolk/flatcar-website-docs

ssh-add -D
ssh-add - <<< "${FLATCAR_DOCS_GITHUB_ACTIONS_KEY}"
git clone git@github.com:kinvolk/docs.flatcar-linux.org

# Clone flatcar-website-docs, build the docs, and copy the results under
# `site` directory into docs.flatcar-linux.org repo.
pushd flatcar-website-docs || exit

make fetch-docs
python3 -m venv .
source bin/activate
pip install -r requirements.txt
sudo gem install httparty liquid
make build
make copy-build

popd || exit

# Push the results into the remote git repo.
pushd docs.flatcar-linux.org

git commit -a -m "Update Flatcar docs ($(date +'%Y-%m-%d'))"
git checkout -B site site
git push origin site

popd || exit
