#!/bin/sh

dir=$(dirname $(readlink -f $0))
(
    cd ${dir}
    for i in $(ls ${dir}/advanced); do
        ln -sn ../advanced/${i} ./init/${i}
    done
)
