#!/usr/bin/env bash
set -e

BRANCH_TO_DEPLOY=master

[ -z "$1" ] && echo "You must supply the VERSION to release" && exit 1
[ -n "$2" ] && BRANCH_TO_DEPLOY=$2

echo "Branch or commit $BRANCH_TO_DEPLOY will be deployed"
read -p "This will STASH UNSTAGED/STAGED changes. Proceed? (yN) " -n 1 -r

if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

echo "### Stash all local changes"
git stash

echo "### Pull all changes from remote server"
git pull

echo "### Checkout master and reset $BRANCH_TO_DEPLOY"
git checkout origin/master
git reset --hard $BRANCH_TO_DEPLOY

echo "### Checkout and reset production branch"
git checkout production
git reset --hard origin/production

echo "### Merge $BRANCH_TO_DEPLOY to production"
git merge $BRANCH_TO_DEPLOY production

echo "### Update VERSION to $1"
echo $1 > VERSION

VERSION=$(cat VERSION)

echo "### Commit and tag release"
git commit -am "Release v$VERSION"
git tag $VERSION

echo "### Push to remote"
git push && git push --tags

echo "### Merge back to master"
git checkout master
git merge production master -m "Merge branch 'production'"

echo "### Set development version"
VERSION="$VERSION-dev"
echo "$VERSION" > VERSION
git commit -am "Set development version to $VERSION"
git push

echo "########## SUCCESS! ##########"
