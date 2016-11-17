#!/bin/bash

if [ "$(id -u)" != "0" ]; then
	echo "ERROR: You are not root."
	exit 1
fi

workingdir=/tmp/shairport_install
shairportrepodir=$workingdir/git
mkdir -p $workingdir
mkdir -p $shairportrepodir
cp ./* $workingdir
cd $workingdir


function aptUp {
  apt-get update
  apt-get upgrade
}

function installPlayer {
  apt-get -y install omxplayer
  chmod a+rw /dev/vchiq
  read -p "Please select default output: [A]udio jack | [h]dmi: " output
  if [[ -z "$output" ]] || [[ $output == "A" ]] || [[ $output == "a" ]]; then
    amixer cset numid=3 1
  elif [[ -z "$output" ]] || [[ $output == "h" ]] || [[ $output == "H" ]]; then
    amixer cset numid=3 2
  else
    echo "invalid answer. setting to automatic."
    amixer cset numid=3 0
  fi

  read -p "Enter path to a file to test. Leave emtpy for example file: " file2play

  if [ -z "$file2play" ];
  then
    wget https://goo.gl/XJuOUW -O example.mp3 --no-check-certificate
    omxplayer example.mp3
  else
    omxplayer $file2play
  fi
}


function setVol {
  read -p "Is the volume to low? [Y/n]: " volcheck

  if [[ -z "$volcheck" ]] || [[ $volcheck == "y" ]] || [[ $volcheck == "Y" ]]; then

    echo "The mixer will open now.\n Press the up arrow until 85.\n Press esc to exit.\n"
    alsamixer

	elif [[ $volcheck == "n" ]] || [[ $volcheck == "N" ]]; then
		return

	else
		echo "Invalid option."
	   setVol
		return
	fi
}

function downloadFiles {
  cd $shairportrepodir

  apt-get install build-essential libssl-dev libcrypt-openssl-rsa-perl libao-dev libio-socket-inet6-perl libwww-perl avahi-utils pkg-config git chkconfig libssl-dev libavahi-client-dev libasound2-dev pcregrep
  git clone git://github.com/Hexxeh/rpi-update.git
  git clone -b 1.0-dev git://github.com/abrasive/shairport.git
  apt-get install pulseaudio
  gconftool-2 -t string --set /system/gstreamer/0.10/default/audiosink pulsesink
  modprobe snd_bcm2835
  wget https://snippets.khromov.se/wp-content/uploads/2013/04/piano2.wav
  cd $workingdir
}

function updateFirmware {
  chmod +x ./rpi-update/rpi-update
  ./rpi-update/rpi-update
}

function confAlsa {
  cp alsa.conf /usr/share/alsa/alsa.conf

}

function confAvhi {
  cp avahi-daemon /etc/init.d/avahi-daemon
  service avahi-daemon restart
  chkconfig avahi-daemon on
  echo "You\'ll now hear a piano...."
  aplay piano2.wav
}

function setupCron {
cmd=$2
extime=$1
job=$cmd & " " & $extime
cat <(fgrep -i -v "$cmd" <(crontab -l)) <(echo "$job") | crontab -
}

function confShairplay {
  cd $shairportrepodir
  ./configure
  make
  make install

  chmod +x shairport
  chkconfig shairport on
  cp shairport /etc/init.d/shairport
  chkconfig shairport off

  cd $workingdir
  chmod +x shairport-watchdog.sh
  cp shairport-watchdog.sh /root/shairport-watchdog.sh
  setupCron "* * * * *" "/root/shairport-watchdog.sh"

  cp shairport /usr/bin/shairport
  service shairport start
  service shairport status


}

aptUp
installPlayer
setVol
downloadFiles
updateFirmware
confAlsa
confAvhi
confShairplay
