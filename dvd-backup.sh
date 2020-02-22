#!/bin/bash
LANG=C
cd /root/dvd-backup

DEVN="$1"
DEVNAME="/dev/$1"
MOUNTDIR="/media/cdrom/$1"
LOG="./backup.$1.log"
CREATEDATE="createdate.$1"
UDEVINFO="udevinfo.$1"

mkdir -p ${MOUNTDIR} 2>/dev/null 

function _log() {
  echo "$(date) ${DEVN} $*" >> ${LOG} 
}

_log "udev $1"
if [[ ! -z $1 && ! -z $(udevadm info -p $(udevadm info -q path ${DEVNAME}) | grep ID_FS) ]]; then
  _log "detected"

  _log "check udevinfo"
  udevadm info -p $(udevadm info -q path ${DEVNAME}) > ${UDEVINFO}
  _log "check creation date"
  mount -t auto ${DEVNAME} ${MOUNTDIR} && stat -c "%x" ${MOUNTDIR} > ${CREATEDATE} && umount ${MOUNTDIR}

  CREATE_DATE=$(cat ${CREATEDATE} | sed -e 's/[+ ]/_/g' -e 's/:/-/g')
  DVD_LABEL=$(cat ${UDEVINFO} | grep ID_FS_LABEL= | awk -F= '{print $2}')
  FN_ISO=${DVD_LABEL}_${CREATE_DATE}.iso
  if [[ ! -e ${FN_ISO} ]]; then
    _log "check info (handbrake)"
    HandBrakeCLI -i ${DEVNAME} -t 0 > ${FN_ISO}.handinfo 2>&1
    _log "check info (dvdbackup)"
    dvdbackup -i ${DEVNAME} -I > ${FN_ISO}.dvdinfo 2>&1

    _log "making iso file ... ${FN_ISO}"
    dd if=${DEVNAME} of=${FN_ISO}
#    dd if=${DEVNAME} | tee ${FN_ISO} | sha256sum > ${FN_ISO}.${DEVN}.sum 

    _log "verify image ${DEVNAME}"
   sha256sum ${DEVNAME} > ${FN_ISO}.${DEVN}.sum

    _log "verify image backup"
    sha256sum ${FN_ISO} > ${FN_ISO}.sum
    sleep 3
  else
    _log "already ripped"
  fi
  _log "ejected" 
  eject ${DEVNAME}
  sleep 3
  _log "script end"
fi
