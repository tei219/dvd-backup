#!/bin/bash
LANG=C
cd /iso

LOG=backup.log

function _log() {
  echo "$(date) $*" >> ${LOG} 
}

_log "udev"
if [[ ! -z $(udevadm info -p $(udevadm info -q path /dev/sr0) | grep ID_FS) ]]; then
  _log "detected"

  _log "check udevinfo"
  udevadm info -p $(udevadm info -q path /dev/sr0) > udevinfo
  _log "check creation date"
  mount -t auto /dev/sr0 /media && stat -c "%x" /media > createdate && umount /media 

  CREATE_DATE=$(cat createdate | sed -e 's/[+ ]/_/g' -e 's/:/-/g')
  DVD_LABEL=$(cat udevinfo | grep ID_FS_LABEL= | awk -F= '{print $2}')
  FN_ISO=${DVD_LABEL}_${CREATE_DATE}.iso
  _log "check info (handbrake)"
  HandBrakeCLI -i /dev/sr0 -t 0 > ${FN_ISO}.handinfo 2>&1
  _log "check info (dvdbackup)"
  dvdbackup -i /dev/sr0 -I > ${FN_ISO}.dvdinfo 2>&1

  _log "making iso file ... ${FN_ISO}"
  dd if=/dev/sr0 of=${FN_ISO}

  _log "verifiy image sr0"
  sha256sum /dev/sr0 > ${FN_ISO}.sr0.sum

  _log "verifiy image backup"
  sha256sum ${FN_ISO} > ${FN_ISO}.sum
  sleep 3

  _log "ejected" 
  eject
  sleep 3
  _log "script end"
fi
