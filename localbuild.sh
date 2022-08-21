#!/usr/bin/env bash

set -euo pipefail

SCRIPTDIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
LOVEURL="https://github.com/love2d/love/releases/download/11.3/love-11.3-linux-x86_64.tar.gz"
LOVETAR="love.tar.gz"
luarocksArgs="LUA_LIBDIR='/usr/local/opt/lua/lib'"

# Utility functions {{{
  # Logging {{{
    ansi_reset="$(tput sgr0 || true)"
    ansi_red="$(tput setaf 1 || true)"
    ansi_yellow="$(tput setaf 3 || true)"
    ansi_blue="$(tput setaf 4 || true)"
    ansi_green="$(tput setaf 2 || true)"
    log_info()    { echo >&2 "${ansi_blue}[info]${ansi_reset}" "$@"; }
    log_warn()    { echo >&2 "${ansi_yellow}[warn]${ansi_reset}" "$@"; }
    log_error()   { echo >&2 "${ansi_red}[ERROR]${ansi_reset}" "$@"; }
    log_success() { echo >&2 "${ansi_green}[success]${ansi_reset}" "$@"; }

    # Use the log_error function to indicate where an error occurs
    trap 'log_error line $LINENO' ERR
  # }}}

  # Checks for command on path
  command_exists() {
    whence -- "$@" &> /dev/null
  }
# }}}

if command_exists luarocks; then
  log_error "luarocks not found!"
  exit 1
fi

if [[ ! -d "${SCRIPTDIR}/.cache" ]]; then
  mkdir "${SCRIPTDIR}/.cache"
fi

if [[ ! -e "${SCRIPTDIR}/.cache/love.tar.gz" ]]; then
  wget -O "${SCRIPTDIR}/.cache/${LOVETAR}" ${LOVEURL}
fi

rm -rf love-raw love
mkdir -p love-raw && \
  tar -xvf "${SCRIPTDIR}/.cache/${LOVETAR}" -C love-raw && \
  mv love-raw/dest/* love-raw && \
  rmdir love-raw/dest && \
  cp -r love-raw love && \
  rm -rf love-raw

pushd src || exit
zip -r olympus.love *
mv olympus.love ../love
popd || exit

if [[ ! -d "${SCRIPTDIR}/.luarocks" ]]; then
  luarocks install --tree=luarocks https://raw.githubusercontent.com/0x0ade/lua-subprocess/master/subprocess-scm-1.rockspec "${luarocksArgs}" && \
  luarocks install --tree=luarocks https://raw.githubusercontent.com/Vexatos/nativefiledialog/master/lua/nfd-scm-1.rockspec "${luarocksArgs}" && \
  luarocks install --tree=luarocks lsqlite3complete "${luarocksArgs}"
fi

cp -r .luarocks/lib/lua/**/* love
cp -r lib-linux/* love

cp olympus.sh love/olympus && \
  chmod a+rx love/olympus && \
  chmod a+rx love/love && \
  chmod a+rx love/install.sh
