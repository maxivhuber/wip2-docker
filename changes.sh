#!/bin/bash

#exit if a command fails
set -e

#Variables
#colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
#values
REPOSITORY=""
BRANCH=""
USER=""
PW=""
MAIL=""
URL=""
CONTAINER=""
TRAIL=""
PATCH=""

prepare() {
    #check for necessary programs (git, docker, diff, patch)
    if  ! command -v git &> /dev/null 
        then
        printf "${RED}git${NC} could not be found\nPlease install it to get this program working\n"
        exit

    elif ! command -v diff &> /dev/null
        then 
        printf "${RED}diff${NC} ${RED}(diffutils)${NC} could not be found\nPlease install it to get this program working\n"
        exit

    elif ! command -v docker &> /dev/null
        then 
        printf "${RED}docker${NC} could not be found\nPlease install it to get this program working\n"
        exit

    elif ! command -v patch &> /dev/null
        then 
        printf "${RED}patch${NC} could not be found\nPlease install it to get this program working\n"
        exit
    fi

    #how to exit
    clear
    printf "Use ${RED}STRG + C${NC} to ${RED}EXIT${NC}\n"
    printf "\n"
    ##
}

getRepoName () {
   printf "Enter target ${RED}repository name${NC}\n" 
   read REPOSITORY
   read -p "Use \"$REPOSITORY\" as repository? [y/n]" -n 1 -r
   printf "\n"

   if [[ $REPLY =~ ^[Yy]$ ]]; then
    return 0
   else
      getRepoName
   fi
}

getBranchName () {
   printf "Enter target ${RED}branch name${NC}\n" 
   read BRANCH
   read -p "Use \"$BRANCH\"? [y/n] as branch?" -n 1 -r
   printf "\n"

   if [[ $REPLY =~ ^[Yy]$ ]]; then
      clear
      return 0
   else
      getBranchName
   fi
}

clone () {
    getGitHubUser () {
        printf "Enter your GitHub ${RED}username${NC}\n"
        read USER
        read -p "Use \"$USER\" as GitHub user? [y/n]" -n 1 -r
        printf "\n"
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            return 0
        else 
            getGitHubUser
        fi
        return 0
    }

    getGitHubPassword () {
        printf "Enter your GitHub ${RED}password${NC}\n"
        read -s PW
        printf "Repeat your GitHub ${RED}password${NC}\n"
        read -s PWR
        if [[ $PW = $PWR ]]; then
            clear
            return 0
        fi
        printf "${RED}Passwords doesnt match${NC}\n"
        getGitHubPassword
    }

    getGitEmail () {
        printf "Enter your ${RED}email for git${NC}\n"
        read MAIL
        read -p "Use \"$MAIL\" as git email? [y/n]" -n 1 -r
        printf "\n"
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            clear
            return 0
        else 
            getGitEmail
        fi
        return 0
    }

    getCloneURL () {
        printf "Enter ${RED}URL for cloning${NC} via https (${RED}EMPTY${NC} if already cloned)\n"
        printf "More information on:\n${GREEN}https://docs.github.com/en/free-pro-team@latest/github/using-git/which-remote-url-should-i-use${NC}\n" 
        read URL
        read -p "Wollen sie \"${URL}\" verwenden? [y/n]" -n 1 -r
        printf "\n"
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            clear
            return 0
        else
            getCloneURL
        fi
            return 0
    }

    cloneRepo () {
        mkdir -p $HOME/.patch/$REPOSITORY
        git init $HOME/.patch/$REPOSITORY -q
        cd $HOME/.patch/$REPOSITORY
        git config user.email $MAIL
        git config user.name $USER
        git config credential.helper store
        touch $HOME/.git-credentials
        AUTH="https://${USER}:${PW}@github.com"

        if ! grep -q $AUTH "$HOME/.git-credentials"; then
            echo $AUTH >> $HOME/.git-credentials
        fi

        #get remote
        git remote add $BRANCH $URL
        git fetch --all -q
        git checkout $BRANCH -q
        return 0
        } 

        getGitHubUser
        getGitHubPassword
        getCloneURL
        getGitEmail
        cloneRepo
        #cloneRepo
        return 0
}

update() {
    cd $HOME/.patch/$REPOSITORY
    git checkout $BRANCH -q
    git fetch --all -q
    git pull -q
    return 0
}

getDockerName () {
   printf "Enter name of ${RED}Docker container${NC}\n"
   read CONTAINER
   read -p "Use \"$CONTAINER\" as container? [y/n]" -n 1 -r
   printf "\n"
   if [[ $REPLY =~ ^[Yy]$ ]]; then
        return 0
   else
        getDockerName
   fi
   return 0

}

getDockerPath () {
    printf "Enter the path of the directory ${RED}inside the container${NC}\n"
    printf "Example: ${GREEN}/home/user${NC}\n"
    read TRAIL
    read -p "Use \"$TRAIL\" inside container? [y/n]" -n 1 -r
    printf "\n"
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        return 0
    else
        getDockerPath
    fi
    return 0
}

patch () {
    PATCH="$(date +"%s").patch"

    mkdir -p $HOME/.patch/patches
    docker cp ${CONTAINER}:$TRAIL ${HOME}/.patch/update
    printf "${GREEN}cleaning up...${NC}\n"
    find $HOME/.patch/update -name 'node_modules' -type d -prune -print -exec rm -rf '{}' \;
    cd $HOME/.patch
    diff --exclude='.git' -ruN $REPOSITORY update > $HOME/.patch/patches/$PATCH || [ $? -eq 1 ]
    rm -rf ${HOME}/.patch/update
    return 0
}

#commands
prepare
getRepoName
getBranchName
#clone or update
read -p "Clone(c) or update(u) ? [c/u]" -n 1 -r
   printf "\n"

   if [[ $REPLY =~ ^[Cc]$ ]]; then
        clone
   elif [[ $REPLY =~ ^[Uu]$ ]]; then
        update
   else 
        exit 1
   fi

getDockerName
getDockerPath
patch
update.sh $PATCH $REPOSITORY $BRANCH
exit