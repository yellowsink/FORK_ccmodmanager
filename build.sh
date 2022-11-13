#!/usr/bin/env bash
shopt -s extglob

# Set some common environment variables
PWSH="pwsh -NoLogo -NoProfile -NonInteractive -Command"
agentArch="linux"
luarocksArgs="LUA_LIBDIR='/usr/local/opt/lua/lib'"
LOVEURL="https://github.com/love2d/love/releases/download/11.3/love-11.3-linux-x86_64.tar.gz"
LOVETAR="love.tar.gz"
SHARP_NAME="CCModManager.Sharp"
loveBinaryDirectory=""

rm -rf luarocks love love-raw love.tar.gz ccmodmanager.zip ccmodmanager.love

dotnet restore sharp/"${SHARP_NAME}".csproj --verbosity Detailed

#msbuild sharp/"${SHARP_NAME}".sln "/p:Configuration=Release" "/p:Platform=Any CPU"
dotnet build -c Release sharp/"${SHARP_NAME}.sln"

wget -O ${LOVETAR} ${LOVEURL}
rm -rf love-raw love
mkdir -p love-raw && \
  tar -xvf ${LOVETAR} -C love-raw && \
  mv -v love-raw/dest/* love-raw && \
  rmdir love-raw/dest && \
  cp -rv love-raw love

${PWSH} "
  Compress-Archive -Path src/* -DestinationPath ccmodmanager.zip -Force && 
  Move-Item -Path ccmodmanager.zip -Destination ccmodmanager.love &&
  Copy-Item -Path ccmodmanager.love -Destination love/${loveBinaryDirectory}/ccmodmanager.love
"

luarocks install --tree=.luarocks https://raw.githubusercontent.com/0x0ade/lua-subprocess/master/subprocess-scm-1.rockspec "${luarocksArgs}" && \
  luarocks install --tree=.luarocks https://raw.githubusercontent.com/Vexatos/nativefiledialog/master/lua/nfd-scm-1.rockspec "${luarocksArgs}" && \
  luarocks install --tree=.luarocks lsqlite3complete "${luarocksArgs}"
cp -rv .luarocks/lib/lua/**/* love/"${loveBinaryDirectory}" && \
cp -r .luarocks/share/lua/**/* love
cp -rv lib-${agentArch}/* love/"${loveBinaryDirectory}" && \
cp -rv sharp/bin/**/net6/!(xunit.*|System.*|Microsoft.*|*.Tests.dll|*.pdb) love/"${loveBinaryDirectory}"/sharp
mv love/"${loveBinaryDirectory}"/sharp/"${SHARP_NAME}" love/"${loveBinaryDirectory}"/sharp/"${SHARP_NAME}"
rm -rf love/"${loveBinaryDirectory}"/sharp/net*
cp -rv sharp/bin/**/net*/* love/"${loveBinaryDirectory}"/sharp

cp -rv lib-mono/* love/"${loveBinaryDirectory}"/sharp

mkdir ../a

cp -v ccmodmanager.sh love/"${loveBinaryDirectory}"/ccmodmanager && \
  chmod a+rx love/"${loveBinaryDirectory}"/ccmodmanager && \
  chmod a+rx love/"${loveBinaryDirectory}"/love && \
  chmod a+rx love/"${loveBinaryDirectory}"/install.sh && \
  chmod a+rx love/"${loveBinaryDirectory}"/sharp/"${SHARP_NAME}" && \
  chmod a+rx love/"${loveBinaryDirectory}"/sharp/"${SHARP_NAME}".dll && \
  cp -v src/data/icon.png love/"${loveBinaryDirectory}"/ccmodmanager.png && \
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

rm -rf luarocks love love-raw love.tar.gz ccmodmanager.zip ccmodmanager.love
mkdir /web
mv dist.zip /web
PORT=8080 FOLDER=/web /serve 