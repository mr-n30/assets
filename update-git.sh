#!/bin/sh

$INSTALL_DIR=/opt/tools

# Update all packeges from GitHub
for dir in $(find $INSTALL_DIR -name .git -type d | sed 's/\.git//g')
do
    cd $dir && git pull
done

# Update nmap
cd $INSTALL_DIR/nmap && \
    ./configure && \
    make && \
    make install
