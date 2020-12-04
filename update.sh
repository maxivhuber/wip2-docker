#!/bin/bash

#exit if a command fails
set -e

PATCH=$1
REPOSITORY=$2
BRANCH=$3
clear

#check for variables
if [[ -z $PATCH ]] || [[ -z $REPOSITORY ]];
then
    printf "do not call this manually\n"
    exit
fi

cd $HOME/.patch/${REPOSITORY}
git checkout $BRANCH -q
cp $HOME/.patch/patches/${PATCH} $HOME/.patch/${PATCH}
cd $HOME/.patch
patch -p0 < ${PATCH}
rm $HOME/.patch/${PATCH}
cd $HOME/.patch/${REPOSITORY}
git add .
git commit -m ${PATCH} -q

read -p "Push changes automatically? [y/n]" -n 1 -r
printf "\n"
if [[ $REPLY =~ ^[Yy]$ ]]; then
    git push
else
    printf "pls push your changes manually\n"
    exit
fi
exit
