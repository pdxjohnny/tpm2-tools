#!/bin/bash

set -eo pipefail

# Checkout 4.X integration test directory
git stash -q
curr_branch=$(git log HEAD --pretty=oneline --abbrev-commit| head -n 1|awk  '{print $1}')
git checkout -b $curr_branch -q
git fetch origin --tags -q
git checkout 4.3.0 -q
git checkout -b 4.3.0 -q
git checkout $curr_branch -q
git checkout 4.3.0 test/integration/tests -q
git branch -D 4.3.0 -q

#
# RSA OAEP decryption was enabled as a feature after 4.X and so testing it
# would signal a false compatibility test failure.
#
git checkout HEAD test/integration/tests/rsadecrypt.sh && \
#
# tpm2_getekcertificate is known to break backwards compatibility
#
git checkout HEAD test/integration/tests/getekcertificate.sh && \
#
# symlink is an irrelevant test for 4.X branch
#
rm test/integration/tests/symlink.sh && \
echo "v4X compatibility test follows" && \
echo "..."

#
# Beyond 4.X release, the tpm2-tools were combined into a single
# busybox style binary "tpm2". The following makes adjustments
# to the tool-name which essentially invokes the same tools.
#
#
for f in `find test/integration/tests -iname '*.sh'`
do
    for i in `find tools -iname 'tpm2*.c'`
    do
        test=$(basename $i .c)
        replace=$(basename $i .c | sed  's/tpm2_//g')
        sed -i "s/$test/tpm2 $replace/g" $f
    done
done

mkdir compatibility_testbuild && \
pushd compatibility_testbuild && \
../configure --enable-unit --disable-fapi --disable-hardening && \
set -x && \
make -j$(nproc) && \
make check -j$(nproc)
popd
git reset --hard HEAD
