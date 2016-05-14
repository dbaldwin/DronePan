#!/bin/bash

slather_path=$(which slather)
if [ -x "$slather_path" ] ; then
    slather
    open html/index.html
else
    echo "Couldn't find slather - try 'gem install slather'"
fi