#!/bin/bash
#
# repository updater (merge from upstream existing repository)

repo=$1
if [ "$repo" = "" ]; then
	echo "$0 update indivisual repository"
	echo
	echo "usage: $0 reponame [-d]"
	echo
	exit 0
fi

grep PAT /home/box/pers/accounts |awk '{print $2}'

set -x

cd working/$repo

git fetch upstream master --tags
git checkout upstream
git merge upstream/master
set +x; echo -en "push it? "; read ans; set -x
[ "$ans" = "y" ] && git push && git push --tags

git checkout master
git merge upstream
set +x; echo -en "push it? "; read ans; set -x
[ "$ans" = "y" ] && git push && git push --tags
