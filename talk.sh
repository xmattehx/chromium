#!/bin/bash
#based on https://wiki.archlinux.org/index.php/Chromium

export TALK="https://dl.google.com/linux/direct/google-talkplugin_current_amd64.deb"

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

rm /opt/talk.tar.gz
