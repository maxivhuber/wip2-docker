#!/bin/bash
PATCH=$1
REPOSITORY=$2
clear
cp $HOME/.patch/patches/${PATCH} $HOME/.patch/${PATCH}
cd $HOME/.patch
patch -p0 < ${PATCH}
rm $HOME/.patch/${PATCH}
cd $HOME/.patch/${REPOSITORY}
git add .

read -p "Commit changes automatically? [y/n]" -n 1 -r
printf "\n"
if [[ $REPLY =~ ^[Yy]$ ]]; then
    git commit -m ${PATCH}
else
    printf "pls commit your changes manually\n"
    exit
fi
exit
