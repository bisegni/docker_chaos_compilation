#!/bin/bash
set -e

BRANCH_NAME=""
CHAOS_TARGET=""
DO_STATIC_TEST=false
PRINT_HELP=false

if [ -z "$NPROC" ];then
   NPROC=$(getconf _NPROCESSORS_ONLN)
fi
echo "Using ${NPROC} number of porcessor"
#parse parameter
while getopts "b:sht:" opt; do
   case $opt in
      b) BRANCH_NAME="$OPTARG" ;;
      t) CHAOS_TARGET="$OPTARG" ;;
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

if [ -n "$CHAOS_TARGET" ]; then
  echo "Compiling for target ${CHAOS_TARGET}"
  if [ "$CHAOS_TARGET" == "arm-linux-2.6" ]; then
    export PATH=$PATH:/usr/local/chaos/gcc-arm-infn-linux26/bin
    echo "Using new path ${PATH}"
  elif [ "$CHAOS_TARGET" == "i686-linux26" ]; then
    export PATH=$PATH:/usr/local/chaos/i686-nptl-linux-gnu/bin
    echo "Using new path ${PATH}"
  fi
  export CHAOS_TARGET=$CHAOS_TARGET
fi

if [ ! -d /tmp/source/chaosframework ]; then
  echo 'Cloning https://opensource-stash.infn.it/scm/chaos/chaosframework.git repository'
  git clone https://opensource-stash.infn.it/scm/chaos/chaosframework.git  /tmp/source/chaosframework
fi

echo 'Set current directory /tmp/source/chaosframework'
cd /tmp/source/chaosframework

echo "Compiling !CHAOS $BRANCH_NAME branch"
if git checkout origin/$BRANCH_NAME; then
    echo Successfully cheked out branch origin/$BRANCH_NAME
else
    echo >&2 "Branch not found on origin repository"
    exit 1
fi

if cmake -DCHAOS_ARCHITECTURE_TEST=1 .; then
  echo 'Successfully compiled configured !CHAOS Framework'
else
  echo >&2 'Error configuring !CHAOS framwork'
  exit 1
fi

if make -j $NPROC install; then
  echo 'Successfully compiled configured !CHAOS Framework'
else
  echo >&2 'Error configuring !CHAOS framwork'
  exit 1
fi

if ! ctest -D ContinuousBuild; then
  echo >&2 'Error performing continus build on !CHAOS framwork'
  exit 1;
fi

if ! ctest -D ContinuousTest; then
  echo >&2 'Error performing continuous test on !CHAOS framwork'
  exit 1;
fi

if ! ctest -D ContinuousSubmit; then
  echo >&2 'Error pushing continuous result for !CHAOS framwork'
  exit 1;
fi

if $DO_STATIC_TEST; then
  echo 'Execute static test'
  cppcheck --enable=all -j $NPROC --xml-version=2 chaos chaos_service_common ChaosMetadataService ChaosMetadataServiceClient ChaosDataService ChaosWANProxy -ichaos/common/data/entity_db/sqlite_impl/ 2> /tmp/test_result/cppcheck.xml
fi
