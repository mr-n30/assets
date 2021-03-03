#!/bin/sh

# Update all packeges from GitHub
for dir in $(find $1 -name .git -type d | sed 's/\.git//g')
do
    cd $dir && git pull
done

# Update nmap
cd $1/nmap && \
    ./configure && \
    make && \
    make install
