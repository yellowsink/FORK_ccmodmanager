#!/usr/bin/env bash

set -euo pipefail
shopt -s extglob

SCRIPTDIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
LOVEURL="https://github.com/love2d/love/releases/download/11.3/love-11.3-linux-x86_64.tar.gz"
LOVETAR="love.tar.gz"
monokickURL="https://github.com/flibitijibibo/MonoKickstart.git"
SHARP_NAME="CCModManager.Sharp"
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

if [[ ! -d "${SCRIPTDIR}/.cache/MonoKickstart" ]]; then
  git clone "${monokickURL}" "${SCRIPTDIR}/.cache/MonoKickstart"
fi

if [[ ! -d "${SCRIPTDIR}/.luarocks" ]]; then
  luarocks install --tree=luarocks https://raw.githubusercontent.com/0x0ade/lua-subprocess/master/subprocess-scm-1.rockspec "${luarocksArgs}" && \
  luarocks install --tree=luarocks https://raw.githubusercontent.com/Vexatos/nativefiledialog/master/lua/nfd-scm-1.rockspec "${luarocksArgs}" && \
  luarocks install --tree=luarocks lsqlite3complete "${luarocksArgs}"
fi

rm -rf love-raw love

dotnet exec "/usr/share/dotnet/sdk/6.0.108/MSBuild.dll" sharp/"${SHARP_NAME}".sln "/p:Configuration=Release" "/p:Platform=Any CPU"

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

cp -r .luarocks/lib/lua/**/* love
cp -r .luarocks/share/lua/**/* love
cp -r lib-linux/* love
cp -rv sharp/bin/**/!(xunit.*|System.*|Microsoft.*|*.Tests.dll|*.pdb) love/sharp
mv love/sharp/net452/* love/sharp
rm -rf love/sharp/net452

cp "${SCRIPTDIR}/.cache/MonoKickstart/precompiled/kick.bin.x86_64" "${SCRIPTDIR}/.cache/MonoKickstart/precompiled/${SHARP_NAME}.bin.x86_64"
rm -rf "${SCRIPTDIR}/.cache/MonoKickstart/precompiled/kick.bin.x86_64.debug"
cp -rv "${SCRIPTDIR}"/.cache/MonoKickstart/precompiled/* love/sharp
cp -rv lib-mono/* love/sharp

cp olympus.sh love/olympus && \
  chmod a+rx love/olympus && \
  chmod a+rx love/love && \
  chmod a+rx love/install.sh && \
  chmod a+rx love/sharp/"${SHARP_NAME}".bin* && \
