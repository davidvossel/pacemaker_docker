#!/bin/bash

from="centos:centos7"
rpms=""
corosync_config=""
export_file=""

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

	echo "RUN yum install -y net-tools pacemaker resource-agents pcs corosync which fence-agents-common sysvinit-tools docker" >> Dockerfile

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

	if [ -z "$export_file" ]; then
		export_file="pcmk_container_${image}.tar"

	fi
	docker save $image > ${export_file}

	echo "Docker container $image is exported to tar file ${export_file}"

	# cleanup
	rm -rf rpms repos
}

function helptext() {
	echo "pcmk_create_image.sh - A tool for creating a pacemaker docker image."
	echo ""
	echo "Usage: pcmk_create_image.sh [options]"
	echo ""
	echo "Options:"
	echo "-f, --from               Specify the FROM image to base the docker containers off of. Default is \"$from\""
	echo "-o, --repo-copy          Copy the repos in this host directory into the image's /etc/yum.repos.d/ directory"
	echo "-R, --rpm-copy           Copy rpms in this directory to image for install".
	echo "-e, --export-file        Export pacemaker container image to this file path.".
	echo ""
	exit $1
}

while true ; do
	case "$1" in
	--help|-h|-\?) helptext 0;;
	-f|--from) from="$2"; shift; shift;;
	-o|--repo-copy) repodir=$2; shift; shift;;
	-R|--rpm-copy) rpmdir=$2; shift; shift;;
	-e|--export-file) export_file=$2; shift; shift;;
	"") break;;
	*) 
		echo "unknown option $1"
		helptext 1;;
	esac
done

make_image

