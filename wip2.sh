#!/bin/bash
#exit if a command fails
set -e

#colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

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
##

#how to exit
clear
printf "Use ${RED}STRG + C${NC} to ${RED}EXIT${NC}\n"
printf "\n"
##

#functions
#get email for git, safe credentials, clone repo
cloneRepo () {
   #safe variables
   REPOSITORY=$1 
   BRANCH=$2
   URL=$3
   USER=$4
   PW=$5

   #get email for git
   printf "Enter your ${RED}email for git${NC}\n"
   read MAIL
   read -p "Use \"$MAIL\" as git email? [y/n]" -n 1 -r
   printf "\n"

   if [[ $REPLY =~ ^[Yy]$ ]]; then
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

      #call patcher
      getDocker $REPOSITORY $BRANCH     
   else
      cloneRepo $REPOSITORY $BRANCH $URL $USER $PW
   fi

}

updateRepo () {
   REPOSITORY=$1
   BRANCH=$2

   cd $HOME/.patch/$REPOSITORY
   git checkout $BRANCH -q
   git fetch --all -q
   git pull -q
   
   getDocker $REPOSITORY $BRANCH
}

#get username and password for git
getCredentials () {
   REPOSITORY=$1 
   BRANCH=$2
   URL=$3

   clear
   printf "Enter your GitHub ${RED}username${NC}\n"
   read USER
   read -p "Use \"$USER\" as GitHub user? [y/n]" -n 1 -r
   printf "\n"

   if [[ $REPLY =~ ^[Yy]$ ]]; then
     #get password
     while true; do
     printf "Enter your GitHub ${RED}password${NC}\n"
     read -s PW
     printf "Repeat your GitHub ${RED}password${NC}\n"
     read -s PWR
     if [[ $PW = $PWR ]]; then
     #break and call next function
     break
     fi
     #password dosent match
     printf "${RED}Passwords doesnt match${NC}\n"
     done
   
   else
      getCredentials $REPOSITORY $BRANCH $URL
   fi
   cloneRepo $REPOSITORY $BRANCH $URL $USER $PW
} 


updateGit() {
   REPOSITORY=$1 
   BRANCH=$2
   FILE=$3
   printf "success\n"
   exit
}

patch () {
   REPOSITORY=$1 
   BRANCH=$2
   CONTAINER=$3
   TRAIL=$4
   FILE="$(date +"%s").patch"

   mkdir -p $HOME/.patch/patches
   docker cp ${CONTAINER}:$TRAIL ${HOME}/.patch/update
   printf "${GREEN}cleaning up...${NC}\n"
   find $HOME/.patch/update -name 'node_modules' -type d -prune -print -exec rm -rf '{}' \;
   cd $HOME/.patch
   diff --exclude='.git' -ruN $REPOSITORY update > $HOME/.patch/$FILE
   rm -rf ${HOME}/.patch/update
   updateGit $REPOSITORY $BRANCH $FILE

   
   
}

#get url to clone git repository
getURL () {
   REPOSITORY=$1 
   BRANCH=$2
   printf "Enter ${RED}URL for cloning${NC} via https (${RED}EMPTY${NC} if already cloned)\n"
   printf "More information on:\n${GREEN}https://docs.github.com/en/free-pro-team@latest/github/using-git/which-remote-url-should-i-use${NC}\n" 
   read URL

   if [[ -z $URL ]]; then
      read -p "Repository in \"$HOME/.patch/$REPOSITORY\" exists already? [y/n]" -n 1 -r
      printf "\n"
      if [[ $REPLY =~ ^[Yy]$ ]]; then
         updateRepo $REPOSITORY $BRANCH
      else
         getURL $REPOSITORY $BRANCH
      fi
   fi

   read -p "Use \"$URL\" to clone repository? [y/n]" -n 1 -r
   printf "\n"
   if [[ $REPLY =~ ^[Yy]$ ]]; then
      getCredentials $REPOSITORY $BRANCH $URL
   else
      getURL $REPOSITORY $BRANCH
   fi
}

# get name of repo
getRepo () {
   printf "Enter target ${RED}repository name${NC}\n" 
   read REPOSITORY
   read -p "Use \"$REPOSITORY\" as repository? [y/n]" -n 1 -r
   printf "\n"

   if [[ $REPLY =~ ^[Yy]$ ]]; then
      getBranch $REPOSITORY
   else
      getRepo
   fi
}

getBranch () {
   REPOSITORY=$1
   printf "Enter target ${RED}branch name${NC}\n" 
   read BRANCH
   read -p "Use \"$BRANCH\"? [y/n] as branch?" -n 1 -r
   printf "\n"

   if [[ $REPLY =~ ^[Yy]$ ]]; then
      getURL $REPOSITORY $BRANCH
   else
      getBranch $REPOSITORY
   fi
}

getDocker () {
   REPOSITORY=$1
   BRANCH=$2

   clear
   printf "Enter name of ${RED}Docker container${NC}\n"
   read CONTAINER
   read -p "Use \"$CONTAINER\" container? [y/n]" -n 1 -r
   printf "\n"

   if [[ $REPLY =~ ^[Yy]$ ]]; then
     #get directory path inside container
     while true; do
     printf "Enter the directory path ${RED}inside the container${NC}\n"
     printf "Example: ${GREEN}/home/user${NC}\n"
     read TRAIL

     read -p "Use \"$TRAIL\" inside container? [y/n]" -n 1 -r
     printf "\n"
     if [[ $REPLY =~ ^[Yy]$ ]]; then
      break
     fi
     done
     #jump to head
   
   else
      getDocker $REPOSITORY $BRANCH
   fi
      patch $REPOSITORY $BRANCH ${CONTAINER} ${TRAIL}
}

getRepo