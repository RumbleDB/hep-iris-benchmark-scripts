#!/usr/bin/env bash

# Go to root directory of repo
cd "$(dirname "${BASH_SOURCE[0]}")"
cd "$(git rev-parse --show-toplevel)"

# Test if submodules need to be updated
if [[ -z "$(git submodule foreach echo hello)" ]]
then
    echo "No git submodules found. Maybe you need to run 'git submodule update'?"
    exit 1
fi

# Collect info about sub-modules
data="$(git submodule foreach -q 'echo "$sm_path\t$sha1\t$(git config remote.origin.url)"')"

# Remove sub-modules
echo "$data" | while read line
do
    path="$(echo "$line" | cut -f1)"
    git rm -rf "$path"
done

# Commit temporary commit and record its SHA1
git commit -m "TMP: Removing git submodules."
first_sha1="$(git rev-parse HEAD)"

# Add content of old submodules back, one merge commit at the time
echo "$data" | while read line
do
    path="$(echo "$line" | cut -f1)"
    sha1="$(echo "$line" | cut -f2)"
    rurl="$(echo "$line" | cut -f3)"

    git subtree add --prefix "$path" "$rurl" "$sha1" --squash
done

# Amend all merge commits into the previous one
git reset --soft "$first_sha1"
git commit --amend -m "Inline sub-modules."
