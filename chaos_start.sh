#!/bin/bash
set -e

BRANCH_NAME=""
CHAOS_TARGET=""
DO_STATIC_TEST=false
PRINT_HELP=false
CTEST_TYPE=""
CTEST_UPDATE_SOURCE=false
if [ -z "$NPROC" ];then
   NPROC=$(getconf _NPROCESSORS_ONLN)
fi
echo "Using ${NPROC} number of porcessor"

function doCTEST(){
  echo "Performing $1 with proc number $NPROC"
  if ! make -j $NPROC $1; then
    echo >&2 "Error performing $1"
  fi
}

#parse parameter
while getopts "b:sht:c:u" opt; do
   case $opt in
      b) BRANCH_NAME="$OPTARG" ;;
      t) CHAOS_TARGET="$OPTARG" ;;
      s) DO_STATIC_TEST=true ;;
      c) CTEST_TYPE="$OPTARG" ;;
      u) CTEST_UPDATE_SOURCE=true ;;
      h) PRINT_HELP=true ;;
   esac
done

if $PRINT_HELP; then
  echo "Usage for ${0}"
  echo " -b specify the branch name"
  echo " -c execute compilation and testing using ctest specifing the type [Continuous, Experimental, Nightly]"
  echo " -u update the source using ctest update command to verify is the results need to be updated to dashboard"
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
else
  echo 'Source code already cloned'
fi

echo 'Set current directory /tmp/source/chaosframework'
cd /tmp/source/chaosframework

if ! git fetch; then
    echo >&2 "Error fetching new data"
    exit 1
fi

echo "Checking !CHAOS $BRANCH_NAME branch"
if ! git checkout origin/$BRANCH_NAME; then
    echo >&2 "Branch not found on origin repository"
    exit 1
fi

if ! git pull origin $BRANCH_NAME; then
  echo >&2 "Error updating the branch"
  exit 1
fi

if [ -n "$CTEST_TYPE" ]; then
  echo "Execute CTEST for type $CTEST_TYPE"
  if ! cmake -DCHAOS_ARCHITECTURE_TEST=ON .; then
    echo >&2 'Error configuring !CHAOS framwork'
    exit 1
  fi

  #execute ctest steps
  doCTEST "$CTEST_TYPE""Start"
  if [ $CTEST_UPDATE_SOURCE == true ]; then
    doCTEST "$CTEST_TYPE""Update"
  fi
  doCTEST "$CTEST_TYPE""Configure"
  doCTEST "$CTEST_TYPE""Build"
  doCTEST "$CTEST_TYPE""Test"
  doCTEST "$CTEST_TYPE""Submit"
else
  echo "Execute Normal compilation"

  if cmake .; then
    echo 'Successfully configured !CHAOS Framework'
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
fi

if $DO_STATIC_TEST; then
  echo 'Execute static test'
  cppcheck --enable=all -j $NPROC --xml-version=2 chaos chaos_service_common ChaosMetadataService ChaosMetadataServiceClient ChaosDataService ChaosWANProxy -ichaos/common/data/entity_db/sqlite_impl/ 2> /tmp/test_result/cppcheck.xml
fi
