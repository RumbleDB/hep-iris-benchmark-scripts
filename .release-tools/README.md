# Release tools

This document describes how to update the entry of this repository on
[Zenodo](https://zenodo.org). The basics steps are:

1. Make a fresh recursive clone of the main repository from Github.
1. Create a temporary branch at the commit you want to release.
1. Run [`inline-submodules.sh`](inline-submodules.sh) from this folder. This
   removes all git submodules, copies their content into their respective
   original paths, and creates a new commit with the now inlined files. This is
   necessary for including the files into the Zenodo archive, which does not
   automatically contain the files from submodules.
1. Tag the new commit and push the tag to Github.
1. Create a new release or pre-release on Github. This automatically updates
   the entry on Zenodo as well.
