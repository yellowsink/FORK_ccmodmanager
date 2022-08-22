#!/usr/bin/env bash
shopt -s extglob

# Set some common environment variables
PWSH="pwsh -NoLogo -NoProfile -NonInteractive -Command"
agentArch="linux"
luarocksArgs="LUA_LIBDIR='/usr/local/opt/lua/lib'"
monokickURL="https://github.com/flibitijibibo/MonoKickstart.git"
LOVEURL="https://github.com/love2d/love/releases/download/11.3/love-11.3-linux-x86_64.tar.gz"
LOVETAR="love.tar.gz"
SHARP_NAME="CCModManager.Sharp"
loveBinaryDirectory=""

rm -rf luarocks MonoKickstart love love-raw love.tar.gz olympus.zip olympus.love

dotnet restore sharp/"${SHARP_NAME}".csproj --verbosity Detailed

msbuild sharp/"${SHARP_NAME}".sln "/p:Configuration=Release" "/p:Platform=Any CPU"

wget -O ${LOVETAR} ${LOVEURL}
rm -rf love-raw love
mkdir -p love-raw && \
  tar -xvf ${LOVETAR} -C love-raw && \
  mv -v love-raw/dest/* love-raw && \
  rmdir love-raw/dest && \
  cp -rv love-raw love

${PWSH} "
  Compress-Archive -Path src/* -DestinationPath olympus.zip -Force && 
  Move-Item -Path olympus.zip -Destination olympus.love &&
  Copy-Item -Path olympus.love -Destination love/${loveBinaryDirectory}/olympus.love
"

ls
echo "-----------------"
ls luarocks


luarocks install --tree=.luarocks https://raw.githubusercontent.com/0x0ade/lua-subprocess/master/subprocess-scm-1.rockspec "${luarocksArgs}" && \
  luarocks install --tree=.luarocks https://raw.githubusercontent.com/Vexatos/nativefiledialog/master/lua/nfd-scm-1.rockspec "${luarocksArgs}" && \
  luarocks install --tree=.luarocks lsqlite3complete "${luarocksArgs}"
cp -rv .luarocks/lib/lua/**/* love/"${loveBinaryDirectory}" && \
cp -r .luarocks/share/lua/**/* love
cp -rv lib-${agentArch}/* love/"${loveBinaryDirectory}" && \
cp -rv sharp/bin/**/!(xunit.*|System.*|Microsoft.*|*.Tests.dll|*.pdb) love/"${loveBinaryDirectory}"/sharp
rm -rf love/"${loveBinaryDirectory}"/sharp/net452
cp -rv sharp/bin/**/net452/* love/"${loveBinaryDirectory}"/sharp

git clone "${monokickURL}"
${PWSH} "
  Move-Item -Path MonoKickstart/precompiled/kick.bin.osx -Destination MonoKickstart/precompiled/${SHARP_NAME}.bin.osx &&
  Move-Item -Path MonoKickstart/precompiled/kick.bin.x86_64 -Destination MonoKickstart/precompiled/${SHARP_NAME}.bin.x86_64 &&
  Remove-Item -Path MonoKickstart/precompiled/kick.bin.x86_64.debug -Force
"

cp -rv MonoKickstart/precompiled/* love/"${loveBinaryDirectory}"/sharp
cp -rv lib-mono/* love/"${loveBinaryDirectory}"/sharp

mkdir ../a

cp -v olympus.sh love/"${loveBinaryDirectory}"/olympus && \
  chmod a+rx love/"${loveBinaryDirectory}"/olympus && \
  chmod a+rx love/"${loveBinaryDirectory}"/love && \
  chmod a+rx love/"${loveBinaryDirectory}"/install.sh && \
  chmod a+rx love/"${loveBinaryDirectory}"/sharp/"${SHARP_NAME}".bin* && \
  cp -v src/data/icon.png love/"${loveBinaryDirectory}"/olympus.png && \
  rm -v love/"${loveBinaryDirectory}"/lib/x86_64-linux-gnu/libz.so.1 && \
  rm -v love/"${loveBinaryDirectory}"/usr/lib/x86_64-linux-gnu/libfreetype.so.6 && \
  rm -v love/"${loveBinaryDirectory}"/love.svg && \
  rm -v love/"${loveBinaryDirectory}"/love.desktop.in && \
  rm -v love/"${loveBinaryDirectory}"/license.txt && \
  mkdir -p ../a/main && \
  pushd love && \
  zip --symlinks -v -r ../../a/main/dist.zip * && \
  popd && \
  mv ../a/main/dist.zip .

rm -rf luarocks MonoKickstart love love-raw love.tar.gz olympus.zip olympus.love
mkdir /web
mv dist.zip /web
PORT=8080 FOLDER=/web /serve 
