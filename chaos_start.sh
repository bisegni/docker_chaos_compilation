#!/bin/bash
set -e

BRANCH_NAME=""
DO_STATIC_TEST=false
PRINT_HELP=false

if [ -z "$NPROC" ];then
   NPROC=$(getconf _NPROCESSORS_ONLN)
fi
echo "Using ${NPROC} number of porcessor"
#parse parameter
while getopts "b:sh" opt; do
   case $opt in
      b) BRANCH_NAME="$OPTARG" ;;
      s) DO_STATIC_TEST=true ;;
      h) PRINT_HELP=true ;;
   esac
done

if $PRINT_HELP; then
  echo "Usage for ${0}"
  echo " -b specify the branch name"
  echo " -s execute the static test"
  exit 0;
fi

if [ -z "$BRANCH_NAME" ]; then
  echo "No branch name given"
  exit 1 # error
fi

echo 'Cloning https://opensource-stash.infn.it/scm/chaos/chaosframework.git repository'
git clone https://opensource-stash.infn.it/scm/chaos/chaosframework.git  /tmp/source/chaosframework
echo 'Set current directory /tmp/source/chaosframework'
cd /tmp/source/chaosframework

echo Compiling !CHAOS $BRANCH_NAME branch
if git checkout origin/$BRANCH_NAME; then
        echo Successfully cheked out branch origin/$BRANCH_NAME
else
    echo >&2 "Branch not found on origin repository"
    exit 1
fi

if ./bootstrap.sh; then
  echo 'Successfully compiled !CHAOS Framework'
else
  echo >&2 'Error compiling !CHAOS framwork'
  exit 1
fi

if $DO_STATIC_TEST; then
  echo 'Execute static test'
  cppcheck --enable=all -j $NPROC --xml-version=2 chaos chaos_service_common ChaosMetadataService ChaosMetadataServiceClient ChaosDataService ChaosWANProxy -ichaos/common/data/entity_db/sqlite_impl/ 2> /tmp/test_result/cppcheck.xml
fi
