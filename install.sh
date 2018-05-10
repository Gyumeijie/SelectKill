#!/bin/bash


if [ $# -lt 1 ]; then
   install_path="~/SelectKill" 
else 
   install_path=$1 
fi

eval mkdir -p ${install_path}
eval cp -r {parser,skill}.sh "${install_path}"
cp config.ini ~/.skill.conf

shell_rc="~/.${SHELL##*/}rc"
bash_shell=$(which bash)

echo "alias SelectKill=\"${bash_shell} ${install_path}/skill.sh\"" >> $(eval echo "$shell_rc")
