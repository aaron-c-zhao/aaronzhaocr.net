#!/bin/bash

while getopts "n:c:t:" option; do
    case $option in
        n)
            name="$OPTARG";;
        c)
            category="$OPTARG";;
        t)
            tags+=("$OPTARG");;
        \?)
            echo "Error: Invalid option"
            exit;;
    esac
done

# compose tags 
tags_str="["


for tag in "${tags[@]}"; do
    if [ "${tags_str: -1}" != '[' ]; then
        tags_str+=", "
    fi
    tags_str+="\"${tag}\""
done

tags_str+="]"

today=$(date "+%Y-%m-%d")
now=$(date "+%H:%M:%S +0100")

read -d '' template << EOF 
---
layout: post
tags: ${tags_str}
title:  \"${name}\"
date:   ${today} ${now}
categories: ${category}
---
EOF


# generate file name
IFS=' '
read -ra wordsarr <<< "$name"

for word in ${wordsarr[@]}; do
    if [ -n "$title" ]; then
        title+="-"
    fi
    title+="$word"
done

file="${today}-${title}.markdown"

echo "$template" >> _drafts/$file



