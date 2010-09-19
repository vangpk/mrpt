#!/bin/bash
# Creates a set of packages for each different Ubuntu distribution, with the 
# intention of uploading them to: 
#   https://launchpad.net/~joseluisblancoc/+archive/ppa-mrpt
#
# JLBC, 2010

# Checks
# --------------------------------
if [ -f version_prefix.txt ];
then
	MRPT_VERSION_STR=`cat version_prefix.txt`
	MRPT_VERSION_MAJOR=${MRPT_VERSION_STR:0:1}
	MRPT_VERSION_MINOR=${MRPT_VERSION_STR:2:1}
	MRPT_VERSION_PATCH=${MRPT_VERSION_STR:4:1}
	AUX_SVN=$(svnversion)
	#Remove the trailing "M":
	MRPT_VERSION_SVN=${AUX_SVN%M}

	MRPT_VER_MM="${MRPT_VERSION_MAJOR}.${MRPT_VERSION_MINOR}"
	MRPT_VER_MMP="${MRPT_VERSION_MAJOR}.${MRPT_VERSION_MINOR}.${MRPT_VERSION_PATCH}"
	echo "MRPT version: ${MRPT_VER_MMP} (SVN: ${MRPT_VERSION_SVN})"
else
	echo "ERROR: Run this script from the MRPT root directory."
	exit 1
fi

MRPT_UBUNTU_OUT_DIR="$HOME/mrpt_ubuntu"
MRPTSRC=`pwd`
MRPT_DEB_DIR="$HOME/mrpt_debian"
MRPT_EXTERN_DEBIAN_DIR="$MRPTSRC/packaging/debian/"
EMAIL4DEB="Jose Luis Blanco (University of Malaga) <joseluisblancoc@gmail.com>"

# Clean out dirs:
rm -fr $MRPT_UBUNTU_OUT_DIR/

# -------------------------------------------------------------------
# And now create the custom packages for each Ubuntu distribution
# -------------------------------------------------------------------
#LST_DISTROS=(jaunty karmic lucid maverick)
LST_DISTROS=(jaunty)

count=${#LST_DISTROS[@]}
IDXS=$(seq 0 $(expr $count - 1))

NEW_DEBIAN_VER=1
DEBCHANGE_CMD="--newversion 1:${MRPT_VERSION_STR}svn${MRPT_VERSION_SVN}-${NEW_DEBIAN_VER}"
for IDX in ${IDXS};
do
	DEBIAN_DIST=${LST_DISTROS[$IDX]}
#	VERSION_DIST=${VER_DISTROS[$IDX]}

	# -------------------------------------------------------------------
	# Call the standard "prepare_debian.sh" script:
	# -------------------------------------------------------------------
	cd ${MRPTSRC}
	bash scripts/prepare_debian.sh -s -u

	echo 
	echo "===== Distribution: ${DEBIAN_DIST}  ========="
	cd ${MRPT_DEB_DIR}/mrpt-${MRPT_VER_MMP}svn${MRPT_VERSION_SVN}/debian
	cp ${MRPT_EXTERN_DEBIAN_DIR}/changelog changelog
	echo "Changing to a new Debian version: ${DEBCHANGE_CMD}"
	echo "Adding a new entry to debian/changelog for distribution ${DEBIAN_DIST}"
	DEBEMAIL=${EMAIL4DEB} debchange $DEBCHANGE_CMD --distribution ${DEBIAN_DIST} --force-distribution New version of upstream sources.

	echo "Now, let's build the source Deb package with 'debuild -S -sa':"
	cd ..
	debuild -S -sa
	
	# Make a copy of all these packages:
	cd ..
	mkdir -p $MRPT_UBUNTU_OUT_DIR/$DEBIAN_DIST
	cp mrpt_* $MRPT_UBUNTU_OUT_DIR/$DEBIAN_DIST/
	echo ">>>>>> Saving packages to: $MRPT_UBUNTU_OUT_DIR/$DEBIAN_DIST/"
done


exit 0
