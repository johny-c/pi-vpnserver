#!/usr/bin/env bash

function read_input {
    question="$1"
    default="$2"
    q="$1 ($2)? "
    read -p "$q" ans

    if [ -n "$ans" ]; then
        printf '%s' "$ans"
    else
        printf '%s' "$default"
    fi
}


function read_from_yaml {
    fpath="$1"
    key="$2"
    value=$(grep $key $fpath | cut -d : -f 2)
    printf "%s" $value
}


function write_to_yaml {
    fpath="$1"
    key="$2"
    value="$3"
    newline="$key: $value"

    var_exists=$(grep $key $fpath | wc -l)
    if [ $var_exists -gt 0 ]; then
        oldline=$(grep $key $fpath)
        sed -i -- "s/$oldline/$newline/g" $fpath
    else
        echo "$newline" >> $fpath
    fi
}
