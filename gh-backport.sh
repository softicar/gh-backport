#!/bin/bash

########################################################################################
#
# gh-backport.sh
#
# Creates a GitHub Pull-Request to backport an already-merged commit to a target branch.
#
# Usage: ./gh-backport.sh <PR-number> <version-branch>
#
# Author: Alexander Schmidt (alexander.schmidt@forspace-solutions.com)
#
########################################################################################

label_name="backport"
label_color="FBCA04"
label_description="Backported to a maintenance branch"
bold=$(tput bold)
normal=$(tput sgr0)


# ---- functions ---- #

function print_help() {
cat << EOF
Creates a GitHub Pull-Request to backport an already-merged commit to a target branch.

${bold}USAGE${normal}
  gh-backport.sh <PR-number> <version-branch>

${bold}EXAMPLE${normal}
  gh-backport.sh 123 v20
EOF
}

function setup_repo_labels() {
	if [[ -z $(gh label list | awk '{print $1}' | egrep "^${label_name}$") ]]; then
		gh label create "$label_name" -c "$label_color" -d "$label_description"
	fi
}

function assert_clean_checkout() {
	[[ ! -z "$(git status --porcelain)" ]] && { echo "FATAL: You have unstaged changes."; exit 1; }
}


# ---- check prerequisites ---- #

[[ ! $(which awk) ]] && { echo "FATAL: 'awk' is not installed."; exit 1; }
[[ ! $(which git) ]] && { echo "FATAL: 'git' is not installed."; exit 1; }
[[ ! $(which gh) ]] && { echo "FATAL: 'gh' is not installed."; exit 1; }
[[ ! $(which jq) ]] && { echo "FATAL: 'jq' is not installed."; exit 1; }


# ---- handle parameters ---- #

PR=$1
VERSION_BRANCH=$2
[ ! $VERSION_BRANCH ] && { print_help; exit 1; }

[[ ! "$PR" =~ ^[0-9]+$ ]] && { echo "FATAL: The given PR number must be an integer."; exit 1; }


# ---- main script ---- #

setup_repo_labels

echo "Creating a PR to backport PR '$PR' to branch '$VERSION_BRANCH'..."

assert_clean_checkout

COMMIT=$(gh pr view $PR --json mergeCommit | jq '.mergeCommit.oid' --raw-output) && \
git checkout $VERSION_BRANCH && \
git pull && \
git checkout -b $PR-to-$VERSION_BRANCH && \
git cherry-pick $COMMIT && \
git push -u origin HEAD && \
gh pr create --fill --base $VERSION_BRANCH --label $label_name && \
echo "PR created."
