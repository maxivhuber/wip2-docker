#!/bin/bash
PATCH=$1
REPOSITORY=$2
clear

if [[ -z $PATCH ]] || [[ -z $REPOSITORY ]];
then
    printf "do not call this manually\n"
    exit
fi

cp $HOME/.patch/patches/${PATCH} $HOME/.patch/${PATCH}
cd $HOME/.patch
patch -p0 < ${PATCH}
rm $HOME/.patch/${PATCH}
cd $HOME/.patch/${REPOSITORY}
git add .
git commit -m ${PATCH}

read -p "Push changes automatically? [y/n]" -n 1 -r
printf "\n"
if [[ $REPLY =~ ^[Yy]$ ]]; then
    git push
else
    printf "pls push your changes manually\n"
    exit
fi
exit
