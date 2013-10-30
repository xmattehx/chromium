#!/bin/bash
#based on https://wiki.archlinux.org/index.php/Chromium

if [ `uname -m` == 'x86_64' ]; then
  # 64-bit
  export CHROME="https://dl.google.com/linux/direct/google-chrome-unstable_current_amd64.deb"
  export TALK="https://dl.google.com/linux/direct/google-talkplugin_current_amd64.deb"
  export JAVA="http://javadl.sun.com/webapps/download/AutoDL?BundleId=65687"
else
  # 32-bit
  export CHROME="https://dl-ssl.google.com/linux/direct/google-chrome-unstable_current_i386.deb"
  export TALK="https://dl.google.com/linux/direct/google-talkplugin_current_i386.deb"
  export JAVA="http://javadl.sun.com/webapps/download/AutoDL?BundleId=65685"
fi


#clean stuff
mount -o remount, rw /
cd /opt/
rm "/opt/deb2tar.py"

cat > "/opt/deb2tar.py" << EOF
#!/usr/bin/python
# -*- coding: utf-8 -*-
 
"""
 
# deb2tar - convert a Debian Linux .deb file to a .tar
#
# First line -- file header: "!<arch>" or similar
# Multiple blocks -- each one, a header line followed by data
# Header line -- <filename> <num1> <num2> <num3> <mode> <len>
# Data -- <len> bytes of data
# We want the block called "data.tar.*"
 
"""
 
import shlex
import os
import sys
 
 
def copypart(
    src,
    dest,
    start,
    length,
    bufsize=1024 * 1024,
    ):
    """
      Binary copy
    """
 
    in_file = open(src, 'rb')
    in_file.seek(start)
 
    out_file = open(dest, 'wb')
    pointer = start
    chunk = False
    amount = bufsize
    while pointer < length:
        if length - pointer < amount:
            amount = length - pointer
        chunk = in_file.read(amount)
        pointer += len(chunk)
        out_file.write(chunk)
 
    in_file.close()
    out_file.close()
 
 
def main(file_open, file_write):
    """
      Copy tar data block
    """
 
    print 'Source file:', file_open
    print 'Destination file:', file_write
    zacetek = 0
    konec = 0
    file_name = ''
    with open(file_open, 'r', 1024 * 1024) as in_file:
        for (pointer, line) in enumerate(in_file):
            zacetek += len(line)
            if 'data.tar' in line:
                meta = shlex.split(line[line.find('data.tar'):len(line)])
                konec = int(meta[5])
                file_name = str(meta[0])
                break
 
    statinfo = os.stat(file_open)
    if statinfo.st_size - konec >= zacetek:
        copypart(file_open, file_write, int(zacetek), int(konec) + int(zacetek))
    else:
        print '----DEBUG----'
        print 'start block', zacetek
        print 'end block', konec
        print 'end deb', statinfo.st_size
        print 'diff', statinfo.st_size - konec
        print 'Internal filename is ' + file_name
        print 'meta', meta
        print 'Failed parsing file! Internal meta mismatch, please report this to author!'
        print '----DEBUG----'
 
if __name__ == '__main__':
    try:
        main(sys.argv[1], sys.argv[2])
    except Exception, e:
        print e
        print 'Usage:', sys.argv[0], 'debian_file.deb', 'tar_file.tar.lzma or gz'
EOF

mkdir -p /usr/lib/mozilla/plugins/

#Flash, pdf

echo "Downloading Google Chrome"
curl -z "/opt/chrome-bin.deb" -o "/opt/chrome-bin.deb" -L $CHROME


python /opt/deb2tar.py /opt/chrome-bin.deb /opt/chrome.tar.lzma
rm /opt/chrome-bin.deb
rm -rf chrome-unstable
mkdir chrome-unstable
tar -xvf /opt/chrome.tar.lzma -C chrome-unstable
rm /opt/chrome.tar.lzma

#mp3,mp4
cp /opt/chrome-unstable/opt/google/chrome/libffmpegsumo.so /usr/lib/cromo/ -f
cp /opt/chrome-unstable/opt/google/chrome/libffmpegsumo.so /opt/google/chrome/ -f
cp /opt/chrome-unstable/opt/google/chrome/libffmpegsumo.so /usr/lib/mozilla/plugins/ -f

#pdf
cp /opt/chrome-unstable/opt/google/chrome/libpdf.so /opt/google/chrome/ -f

#flash
cp /opt/chrome-unstable/opt/google/chrome/PepperFlash/libpepflashplayer.so /opt/google/chrome/pepper/ -f
cp /opt/chrome-unstable/opt/google/chrome/PepperFlash/manifest.json /opt/google/chrome/pepper/ -f
cat > "/opt/google/chrome/pepper/pepper-flash.info" << EOF
# Copyright (c) 2011 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
 
# Registration file for Pepper Flash player.
 
FILE_NAME=/opt/google/chrome/pepper/libpepflashplayer.so
PLUGIN_NAME="Shockwave Flash"
VERSION="11.8.800.96"
VISIBLE_VERSION="11.8 r800"
DESCRIPTION="$PLUGIN_NAME $VISIBLE_VERSION"
MIME_TYPES="application/x-shockwave-flash"
EOF

rm -rf chrome-unstable



## Google Talk
echo "Downloading Google Talk plugin"
curl -z "/opt/talk-bin.deb" -o "/opt/talk-bin.deb" -L $TALK

python /opt/deb2tar.py /opt/talk-bin.deb /opt/talk.tar.gz
rm /opt/talk-bin.deb
rm -rf /opt/google/talkplugin

tar -xvf /opt/talk.tar.gz -C /
rm /opt/google/chrome/pepper/libnpgoogletalk.so
ln -s /opt/google/talkplugin/libnpgoogletalk.so /opt/google/chrome/pepper/libnpgoogletalk.so
rm /opt/google/chrome/pepper/libnpgtpo3dautoplugin.so
ln -s /opt/google/talkplugin/libnpgtpo3dautoplugin.so /opt/google/chrome/pepper/libnpgtpo3dautoplugin.so

#rm /opt/talk.tar.gz

## JAVA
## JAVA
#echo "Downloading Oracle Java"
#curl -z "/opt/java-bin.tar.gz" -o "/opt/java-bin.tar.gz" -L $JAVA

#rm -rf /usr/lib/jvm/java-7-oracle/jre/
#mkdir -p /usr/lib/jvm/java-7-oracle/jre/
#tar -xvf /opt/java-bin.tar.gz -C /usr/lib/jvm/java-7-oracle/jre/ --strip-components 1
#rm /usr/lib/cromo/libnpjp2.so
#if [ `uname -m` == 'x86_64' ]; then
#  ln -s /usr/lib/jvm/java-7-oracle/jre/lib/amd64/libnpjp2.so /usr/lib64/cromo/libnpjp2.so
#  ln -s /usr/lib/jvm/java-7-oracle/jre/lib/amd64/libnpjp2.so /usr/lib64/mozilla/plugins/libnpjp2.so
#  ln -s /usr/lib/jvm/java-7-oracle/jre/lib/amd64/libnpjp2.so /usr/lib64/libnpjp2.so
#  ln -s /usr/lib/jvm/java-7-oracle/jre/lib/amd64/libnpjp2.so /opt/google/chrome/libnpjp2.so
#else
#  ln -s /usr/lib/jvm/java-7-oracle/jre/lib/i386/libnpjp2.so /usr/lib/cromo/libnpjp2.so
#  ln -s /usr/lib/jvm/java-7-oracle/jre/lib/i386/libnpjp2.so /usr/lib/mozilla/plugins/libnpjp2.so
#  ln -s /usr/lib/jvm/java-7-oracle/jre/lib/i386/libnpjp2.so /usr/lib/libnpjp2.so
#  ln -s /usr/lib/jvm/java-7-oracle/jre/lib/i386/libnpjp2.so /opt/google/chrome/libnpjp2.so
#fi
#curl -L https://gist.github.com/dz0ny/3065781/raw/9e3d43dc37e054acd9291641896e559cae11629c/99java > /etc/env.d/99java

env-update
restart ui
