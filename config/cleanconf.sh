#!/bin/sh
######################################################################
#
# File:		cleanconf.sh
#
# Purpose:	to remove autogenerated files
#
# Version:	$Id: cleanconf.sh 2288 2007-06-14 11:27:32Z cary $
#
# Copyright 2003, Tech-X Corporation
#
######################################################################

# read command-line parameters
regenconf=true
while getopts an opt; do
  case "$opt" in
    a)
      echo "-a now the default.  Use -n to prevent regeneration."
      ;;
    n)
      regenconf=false
      ;;
    \?) # unknown flag
      echo >&2 "Usage: $0 [-n]"
      exit 1
      ;;
  esac
done
shift `expr $OPTIND - 1`

# Get rid of old files
echo Removing all the autogenerated files
cmd='rm -f configure config.cache aclocal.m4 config.h.in'
echo "$cmd"
eval $cmd
# cmd='(cd config; rm -f ltmain.sh)'
# echo "$cmd"
# eval $cmd

# Change to writeable for remonval
chmod -R u+w .
rmfiles="Makefile.in Makefile.am.orig hdrs.txt cppsrcs.txt cxxsrcs.txt distfiles.txt"
for i in $rmfiles; do
   # cmd='find ./ -name hdrs.txt -exec rm -f {} \;'
  cmd="find ./ -name $i -exec "'rm -f {} \;'
  echo $cmd
  eval $cmd
done

echo Removing configure cache
cmd="rm -rf autom4te.cache autom4te-*.cache"
echo "$cmd"
eval $cmd

# Creating new files for this platform
if ! $regenconf; then
  echo
  echo You should now make files specific to local versions of
  echo automake/autoconf by doing the following:
  echo "	config/regenconf.sh"
  echo or
  echo "	$0 (i.e., run this without the -n option)"
else
  configdir=`dirname $0`
  echo $configdir/regenconf.sh
  $configdir/regenconf.sh
fi

