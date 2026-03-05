#!/bin/bash

git pull

for dir in */
do
  stow ${dir%/};
done
