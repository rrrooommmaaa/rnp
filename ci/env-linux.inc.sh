#!/usr/bin/env bash
# shellcheck disable=SC1091

: "${CORES:=$(grep -c '^$' /proc/cpuinfo)}"
export CORES
export MAKE=make

DIST="$(get_linux_dist)"
DIST_VERSION_ID="$(sh -c '. /etc/os-release && echo $VERSION_ID')"
DIST_VERSION="${DIST}-${DIST_VERSION_ID}"

export DIST
export DIST_VERSION
export DIST_VERSION_ID

case "${DIST}" in
  fedora|centos)
    if command -v dnf >/dev/null; then
      export YUM=dnf
    else
      export YUM=yum
    fi
    ;;
esac

# Keep this re-entrant and run it after all calls to yum install.
post_yum_install_set_env() {
  case "${DIST}" in
    centos)
      if rpm --quiet -q ribose-automake116 && [[ "$PATH" != */opt/ribose/ribose-automake116/root/usr/bin* ]]; then
        # set ACLOCAL_PATH if using ribose-automake116
        ACLOCAL_PATH=$(scl enable ribose-automake116 -- aclocal --print-ac-dir):$(rpm --eval '%{_datadir}/aclocal')
        export ACLOCAL_PATH
        # set path etc
        . /opt/ribose/ribose-automake116/enable
      fi

      # use rh-ruby25 if installed
      if rpm --quiet -q rh-ruby25 && [[ "$PATH" != */opt/rh/rh-ruby25/root/usr/bin* ]]; then
        . /opt/rh/rh-ruby25/enable
        PATH=$HOME/bin:$PATH
        export PATH
        export SUDO_GEM="run"
      fi

      # use llvm-toolset-7 if installed
      if rpm --quiet -q llvm-toolset-7.0 && [[ "$PATH" != */opt/rh/llvm-toolset-7.0/root/usr/bin* ]]; then
        . /opt/rh/llvm-toolset-7.0/enable
      fi
      ;;
  esac
}
