#!/usr/bin/env bash
# Use *real* vimdiff to edit merge conflicts in Git
#
# Instead of editing a file with  <<<< ==== >>> conflict markers, this opens
# each "side" of the conflict markers in a two-way vimdiff window.
# (I'm not clear why this isn't the default behavior for Git's vimdiff
# mergetool script. What purpose does the middle pane with the conflict markers
# serve that vimdiff can't do better on its own?)
# 
# Workflow:
#
# 1.    Save your changes to the LOCAL temporary file (in the left window).
# 2.    The base file for the merge is available if you want to look at it in
#       the second tabpage.
# 3.    When vimdiff exits cleanly, the file containing the conflict markers
#       will be updated with the contents of your LOCAL file edits.
#       NOTE: Use :cq to abort the merge and exit vimdiff with an error code.
#
# Put the following in your ~/.gitconfig (you can substitute vim for gvim):
#
# [mergetool "vimdiffconflicts"]
#     cmd = unmerge.sh vim $BASE $LOCAL $REMOTE $MERGED
#     trustExitCode = true

if [[ -z $@ || $# != "5" ]] ; then
    echo -e "Usage: $0 \$BASE \$LOCAL \$REMOTE \$MERGED"
    exit 1
fi

cmd=$1
BASE=$2
LOCAL=$3
REMOTE=$4
MERGED=$5

# Remove the conflict markers for each side and put each result into the LOCAL
# and REMOTE temporary files (since we're not using them otherwise).
sed -e '/<<<<<<</,/=======/d' -e '/>>>>>>>/d' $MERGED > $LOCAL
sed -e '/=======/,/>>>>>>>/d' -e '/<<<<<<</d' $MERGED > $REMOTE

# Fire up vimdiff
$cmd -f -d $BASE $LOCAL $REMOTE \
    -c ':diffoff' -c ':set scrollbind' -c 'wincmd T' -c ':tabfirst'

EC=$?

# Overwrite $MERGED only if vimdiff exits cleanly.
if [[ $EC == "0" ]] ; then
    cat $LOCAL > $MERGED
fi

# Always delete the temp files
rm $BASE $LOCAL $REMOTE

exit $EC
