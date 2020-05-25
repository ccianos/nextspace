#!/bin/sh
# This script uses `sudo` to install generated RPMs. Please make sure user you 
# run this script as has appropriate rights.
#

REPO_DIR=$1
. `dirname $0`/functions

if [ $# -eq 0 ];then
    print_help
    exit
fi

LOG_FILE=${CWD}/frameworks_build.log
FRAMEWORKS_VERSION=0.90

print_H1 " Building NEXTSPACE Frameworks package..."
cp ${REPO_DIR}/Frameworks/nextspace-frameworks.spec ${SPECS_DIR}
print_H2 "========== Install nextspace-frameworks build dependencies... ==================="
DEPS=`rpmspec -q --buildrequires ${SPECS_DIR}/nextspace-frameworks.spec | awk -c '{print $1}'`
sudo yum -y install ${DEPS} 2>&1 > ${LOG_FILE}
print_H2 "========== Downloading nextspace-frameworks sources... ========================="
source /Developer/Makefiles/GNUstep.sh
cd ${REPO_DIR}/Frameworks && make dist 2>&1 >> ${LOG_FILE}
cd $CWD
mv ${REPO_DIR}/nextspace-frameworks-${FRAMEWORKS_VERSION}.tar.gz ${SOURCES_DIR}
spectool -g -R ${SPECS_DIR}/nextspace-frameworks.spec 2>&1 >> ${LOG_FILE}
print_H2 "========== Building nextspace-frameworks package... ============================"
rpmbuild -bb ${SPECS_DIR}/nextspace-frameworks.spec 2>&1 >> ${LOG_FILE}
rm ${SPECS_DIR}/nextspace-frameworks.spec
if [ $? -eq 0 ]; then 
    print_OK " Building of NEXTSPACE Frameworks RPM SUCCEEDED!"
    print_H2 "========== Installing nextspace-frameworks RPMs... ============================="
    sudo yum -y install \
        ${RPMS_DIR}/nextspace-frameworks-${FRAMEWORKS_VERSION}* \
        ${RPMS_DIR}/nextspace-frameworks-devel-${FRAMEWORKS_VERSION}*
else
    print_ERR " Building of NEXTSPACE Frameworks RPM FAILED!"
    exit $?
fi

exit 0

