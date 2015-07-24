#!/bin/bash

from="centos:centos7"
rpms=""
corosync_config=""

make_image()
{
	echo "Making Dockerfile"
	rm -f Dockerfile

	if [ -z "$corosync_config" ]; then
		corosync_config="defaults/corosync.conf"
	fi

	echo "FROM $from" > Dockerfile

	# this gets around a bug in rhel 7.0
	touch /etc/yum.repos.d/redhat.repo

	rm -rf repos
	mkdir repos
	if [ -n "$repodir" ]; then
		cp $repodir/* repos/
		echo "ADD /repos /etc/yum.repos.d/" >> Dockerfile
	fi

	rm -rf rpms
	mkdir rpms
	if [ -n "$rpmdir" ]; then
		echo "ADD /rpms /root/" >> Dockerfile
		echo "RUN yum install -y /root/*.rpm" >> Dockerfile
		cp $rpmdir/* rpms/
	fi

	echo "RUN yum install -y net-tools pacemaker resource-agents pcs corosync which fence-agents-common sysvinit-tools" >> Dockerfile

	echo "ADD /helper_scripts /usr/sbin" >> Dockerfile
	echo "ADD $corosync_config /etc/corosync/" >> Dockerfile

	echo "ENTRYPOINT /usr/sbin/pcmk_launch.sh" >> Dockerfile

	# generate image
	echo "Making image"
	docker $doc_opts build .
	if [ $? -ne 0 ]; then
		echo "ERROR: failed to generate docker image"
		exit 1
	fi
	image=$(docker $doc_opts images -q | head -n 1)

	# cleanup
	rm -rf rpms repos
}

