#!/bin/bash

#
# by TS, May 2019
#

VAR_MYNAME="$(basename "$0")"

# ----------------------------------------------------------

# Outputs CPU architecture string
#
# @param string $1 debian_rootfs|debian_dist
#
# @return int EXITCODE
function _getCpuArch() {
	case "$(uname -m)" in
		x86_64*)
			echo -n "amd64"
			;;
		i686*)
			if [ "$1" = "qemu" ]; then
				echo -n "i386"
			elif [ "$1" = "s6_overlay" -o "$1" = "alpine_dist" ]; then
				echo -n "x86"
			else
				echo -n "i386"
			fi
			;;
		aarch64*)
			if [ "$1" = "debian_rootfs" ]; then
				echo -n "arm64v8"
			elif [ "$1" = "debian_dist" ]; then
				echo -n "arm64"
			else
				echo "$VAR_MYNAME: Error: invalid arg '$1'" >/dev/stderr
				return 1
			fi
			;;
		armv7*)
			if [ "$1" = "debian_rootfs" ]; then
				echo -n "arm32v7"
			elif [ "$1" = "debian_dist" ]; then
				echo -n "armhf"
			else
				echo "$VAR_MYNAME: Error: invalid arg '$1'" >/dev/stderr
				return 1
			fi
			;;
		*)
			echo "$VAR_MYNAME: Error: Unknown CPU architecture '$(uname -m)'" >/dev/stderr
			return 1
			;;
	esac
	return 0
}

_getCpuArch debian_dist >/dev/null || exit 1

# ----------------------------------------------------------

LVAR_DEBIAN_DIST="$(_getCpuArch debian_dist)"

LVAR_REPO_PREFIX="tsle"
LVAR_PARENT_IMAGE_NAME="ws-apache-base-$LVAR_DEBIAN_DIST"
LVAR_PARENT_IMAGE_VER="2.7"

LVAR_PARENT_IMG_FULL="${LVAR_PARENT_IMAGE_NAME}:${LVAR_PARENT_IMAGE_VER}"

LVAR_IMAGE_NAME="ws-apache-php74-mariadb103-$LVAR_DEBIAN_DIST"
LVAR_IMAGE_VER="${LVAR_PARENT_IMAGE_VER}a"

# ----------------------------------------------------------

# @param string $1 Docker Image name
# @param string $2 optional: Docker Image version
#
# @returns int If Docker Image exists 0, otherwise 1
function _getDoesDockerImageExist() {
	local TMP_SEARCH="$1"
	[ -n "$2" ] && TMP_SEARCH="$TMP_SEARCH:$2"
	local TMP_AWK="$(echo -n "$1" | sed -e 's/\//\\\//g')"
	#echo "  checking '$TMP_SEARCH'"
	local TMP_IMGID="$(docker image ls "$TMP_SEARCH" | awk '/^'$TMP_AWK' / { print $3 }')"
	[ -n "$TMP_IMGID" ] && return 0 || return 1
}

_getDoesDockerImageExist "$LVAR_PARENT_IMAGE_NAME" "$LVAR_PARENT_IMAGE_VER"
if [ $? -ne 0 ]; then
	LVAR_PARENT_IMG_FULL="${LVAR_REPO_PREFIX}/$LVAR_PARENT_IMG_FULL"
	_getDoesDockerImageExist "${LVAR_REPO_PREFIX}/${LVAR_PARENT_IMAGE_NAME}" "$LVAR_PARENT_IMAGE_VER"
	if [ $? -ne 0 ]; then
		echo "$VAR_MYNAME: Trying to pull image from repository '${LVAR_REPO_PREFIX}/'..."
		docker pull ${LVAR_PARENT_IMG_FULL}
		if [ $? -ne 0 ]; then
			echo "$VAR_MYNAME: Error: could not pull image '${LVAR_PARENT_IMG_FULL}'. Aborting." >/dev/stderr
			exit 1
		fi
	else
		echo "$VAR_MYNAME: Updating image from repository '${LVAR_REPO_PREFIX}/'..."
		docker pull ${LVAR_PARENT_IMG_FULL} || exit 1
		echo
	fi
fi

# ----------------------------------------------------------

cd build-ctx || exit 1

# ----------------------------------------------------------

LVAR_MARIADB_VERSION="10.3"

docker build \
		--build-arg CF_APACHE_BASE_IMGFULL="$LVAR_PARENT_IMG_FULL" \
		--build-arg CF_APACHE_BASE_VER="$LVAR_PARENT_IMAGE_VER" \
		--build-arg CF_MARIADB_VERSION="$LVAR_MARIADB_VERSION" \
		-t "$LVAR_IMAGE_NAME":"$LVAR_IMAGE_VER" \
		.
