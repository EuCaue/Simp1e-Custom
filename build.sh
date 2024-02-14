#!/bin/bash
# Put this file into the root directory of cursor theme

# Get theme directory
BASEDIR=$(dirname "$(realpath $0)")
cd $BASEDIR

# Download and update git submodules if they are not present
if [[ ! -f "$BASEDIR/cursor-generator/make.py" ]]
then
	git submodule update --init
fi

# The generator script is sourced here
source $BASEDIR/cursor-generator/generator.sh


