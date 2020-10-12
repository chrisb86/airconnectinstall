#!/usr/bin/env sh

# airconnectinstall.sh
# Copyright 2020 Christian Baer
# http://git.debilux.org/chbaer/airconnectinstall

# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTI

BASEDIR="/usr/local/share/airconnect"
RC_SCRIPT="/usr/local/etc/rc.d/airconnect"
AIRCONNECT_USER="airconnect"
AIRCONNECT_GROUP="airconnect"
AIRCONNECT_CONF_DIR="/usr/local/etc/airconnect"
AIRCONNECT_LOG_DIR="/var/log/airconnect"
AIRCONNECT_PID_DIR="/var/run/airconnect"
AIRCONNECT_GIT="https://github.com/philippe44/AirConnect"

## Create user and directories
echo ">>> Creating user and directories"
pw user add ${AIRCONNECT_USER} -c ${AIRCONNECT_USER} -u 1001 -d /nonexistent -s /usr/bin/nologin
mkdir -p ${BASEDIR} ${AIRCONNECT_CONF_DIR} ${AIRCONNECT_LOG_DIR} ${AIRCONNECT_PID_DIR} /usr/local/etc/rc.d

## Download AirConnect

if [ ! -f "${BASEDIR}/CHANGELOG" ]; then
	echo ">>> Downloading AirConnect"
	git clone ${AIRCONNECT_GIT} ${BASEDIR}
else
  cd ${BASEDIR}
  git fetch origin
fi

## Install rc script
echo ">>> Installing rc script ${RC_SCRIPT}."
cat <<\EOF > ${RC_SCRIPT}
#!/bin/sh

# PROVIDE: airconnect
# REQUIRE: LOGIN
# KEYWORD: shutdown

#
# Add the following line to /etc/rc.conf to enable 'airconnect':
#
# airconnect_enable="YES"
#
# Other configuration settings for jdownloader that can be set in /etc/rc.conf:
#
# airconnect_user (str)
#   This is the user that airconnect runs as
#   Set to airconnect by default
#
# airconnect_group (str)
#   This is the group that airconnect runs as
#   Set to airconnect by default
#

. /etc/rc.subr
name=airconnect

rcvar=airconnect_enable
load_rc_config ${name}

: ${airconnect_enable:=NO}
: ${airconnect_user:=airconnect}
: ${airconnect_group:=airconnect}
: ${airconnect_basedir:=/usr/local/share/airconnect}
: ${airconnect_confdir:=/usr/local/etc/airconnect}
: ${airconnect_logdir:=/var/log/airconnect}
: ${airconnect_piddir:=/var/run/airconnect}

pidfile="${airconnect_piddir}/${name}.pid"
logfile="${airconnect_logdir}/${name}.log"
command=${airconnect_basedir}/bin/airupnp-bsd-x64
command_args="-x ${airconnect_confdir}/config.xml -o S1,S3,S5,S9,S12,ZP80,ZP90,S15,ZP100,ZP120 -l 1000:2000 -f ${logfile} -p ${pidfile} -z"

run_rc_command "$1"

EOF

cat <<\EOF > ${AIRCONNECT_CONF_DIR}/config.xml
<?xml version="1.0"?>
<airupnp>
  <common>
    <enabled>1</enabled>
    <max_volume>100</max_volume>
    <codec>flc</codec>
    <metadata>1</metadata>
    <artwork>https://raw.githubusercontent.com/pwt/docker-airconnect-arm/master/airconnect-logo.png</artwork>
    <latency>1000:1000:f</latency>
    <drift>1</drift>
  </common>
  <main_log>info</main_log>
  <upnp_log>warn</upnp_log>
  <util_log>warn</util_log>
  <raop_log>warn</raop_log>
  <log_limit>2</log_limit>
</airupnp>

EOF

chmod u+x ${RC_SCRIPT}

## Set permissions
echo ">>> Setting permissions."
chown -R ${AIRCONNECT_USER}:${AIRCONNECT_GROUP} ${BASEDIR} ${AIRCONNECT_CONF_DIR} ${AIRCONNECT_LOG_DIR} ${AIRCONNECT_PID_DIR}
chmod +x ${BASEDIR}/bin/*

echo ">>> Enabling AirConnect service"
sysrc "airconnect_enable=YES"

service airconnect start