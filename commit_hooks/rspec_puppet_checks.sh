#!/bin/bash

git_root=`git rev-parse --show-toplevel`
syntax_errors=0
error_msg=$(mktemp /tmp/error_msg_rspec-puppet.XXXXX)

# Run rspec-puppet tests
oldpwd=$(pwd)
tmpchangedmodules=''
#get a list of files changed under the modules directory so we can
#sort/uniq them later
for changedfile in `git diff --raw --cached --name-only --diff-filter=ACM | grep '^modules' | grep '\.*.pp$\|\.*.rb$'`; do
    changeddir=$(dirname $changedfile | cut -d"/" -f1,2)
    tmpchangedmodules="$tmpchangedmodules\n$changeddir"
done

#sort/uniq so we only run rspec tests once
changedmodules=$(echo -e "$tmpchangedmodules" | sort -u)


#now that we have the list of modules that changed, run rspec for each module
for module_dir in $changedmodules; do
    echo -e "\e[0;36mRunning rspec-puppet tests for module $1...\e[0m"
    cd $module_dir
    if [ ! -d "rspec" ]; then
      continue
    fi
    #this will run rspec for every test in the module
    rspec > $error_msg
    RC=$?
    if [ $RC -ne 0 ]; then
        echo -en "\e[0;31m"
        cat $error_msg
        echo -e "Error: rspec-puppet test(s) failed for $module_dir (see above)\e[0m"
        syntax_errors=`expr $syntax_errors + 1`
    fi
done
cd $oldpwd > /dev/null

rm $error_msg

if [ "$syntax_errors" -ne 0 ]; then
    echo -e "\e[0;31mError: $syntax_errors rspec-puppet test(s) failed. Commit will be aborted.\e[0m"
    exit 1
fi

exit 0
