#!/usr/bin/env bash

# Written and placed in public domain by Jeffrey Walton
# This script builds iConv from sources.

# iConv and GetText are unique among packages. They have circular
# dependencies on one another. We have to build iConv, then GetText,
# and iConv again. Also see https://www.gnu.org/software/libiconv/.
# The script that builds iConvert and GetText in accordance to specs
# is build-iconv-gettext.sh. You should use build-iconv-gettext.sh
# instead of build-iconv.sh directly

# iConv has additional hardships. The maintainers don't approve of
# Apple's UTF-8-Mac so they don't support it. Lack of UTF-8-Mac support
# on OS X causes other programs to fail, like Git. Also see
# https://marc.info/?l=git&m=158857581228100. That leaves two choices.
# First, use a GitHub like https://github.com/fumiyas/libiconv-utf8mac.
# Second, use Apple's sources at http://opensource.apple.com/tarballs/.
# Apple's libiconv-59 is really libiconv 1.11 in disguise. So we use
# the first method, clone libiconv-utf8mac, build a release tarball,
# and then use it in place of the GNU packages.

###############################################################################

CURR_DIR=$(pwd)
function finish {
    cd "$CURR_DIR" || exit 1
}
trap finish EXIT INT

###############################################################################

rm -rf libiconv-utf8mac libiconv

if ! git clone https://github.com/noloader/libiconv-utf8mac.git
then
    echo "Failed to clone libiconv-utf8mac"
    exit 1
fi

mv libiconv-utf8mac libiconv || exit 1
cd libiconv || exit 1

if ! make -f Makefile.utf8mac autogen
then
    echo "Failed to update libiconv-utf8mac"
    exit 1
fi

if ! patch -p0 < ../patch/iconv.patch
then
    echo "Failed to patch libiconv-utf8mac"
    exit 1
fi

sed 's/^VERSION=.*/VERSION=utf8mac-1.16/g' Makefile.utf8mac > Makefile.utf8mac.fixed
mv Makefile.utf8mac.fixed Makefile.utf8mac

if ! make -f Makefile.utf8mac dist
then
    echo "Failed to create libiconv-utf8mac tarball"
    exit 1
fi

exit 0
