#!/bin/bash
# MIT License
#
# Copyright (c) 2022 Christian Hoekstra
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

set -e

# Helper script to upload files to Bitbucket Repository into Downloads

# $1 = Repo username
# $2 = Password
# $3 = Repository
# $4 = Filename to upload
function upload_bitbucket () {
    if [ "$#" -eq "4" ];then
        curl -# -u $1:$2 -X POST https://api.bitbucket.org/2.0/repositories/$1/$3/downloads -F files=@$4 -o /dev/null
        return 0
    else 
        echo "Invalid parameters: $* "
        echo "Usage:"
        echo " upload_bitbucket <Username> <Password> <Repository> <Filename>"
        exit 1
    fi
}

FILESIZE=`ls -lh $1 | awk '{print $5}'`

# Add appropiate values
USERNAME="<Please Change>"
PASSWD="<Please Change>"
REPO="<Please Change>"

echo  "Uploading (${FILESIZE}) $1: "
upload_bitbucket ${USERNAME} ${PASSWD} ${REPO} $1
