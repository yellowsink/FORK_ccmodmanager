# USE AS `docker run --rm -it -p 8080:8080 -v $(pwd):/Olympus olympus`

FROM ubuntu:22.04 AS builder

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Set some common environment variables
ENV PWSH="pwsh -NoLogo -NoProfile -NonInteractive -Command"
ENV PWSHURL="https://github.com/PowerShell/PowerShell/releases/download/v7.2.5/powershell-lts_7.2.5-1.deb_amd64.deb"
ENV SERVERURL="https://github.com/halverneus/static-file-server/releases/download/v1.8.8/static-file-server-v1.8.8-linux-arm64"
ENV jobArchName="linux"
ENV agentArch="linux"
ENV artifactPrefix="linux."
ENV artifactSuffix=""
ENV monokickURL="https://github.com/flibitijibibo/MonoKickstart.git"
ENV luarocksArgs="LUA_LIBDIR='/usr/local/opt/lua/lib'"
ENV LOVEURL="https://github.com/love2d/love/releases/download/11.3/love-11.3-linux-x86_64.tar.gz"
ENV LOVETAR="love.tar.gz"
ENV loveBinaryDirectory=""
ENV loveResourcesDirectory=""
ENV launcher=""

WORKDIR /
SHELL ["/bin/sh", "-c"]

# Setup: install common tools
RUN apt -y update
RUN apt -y install \
    build-essential \
    apt-transport-https \
    software-properties-common \
    tar \
    wget \
    git
RUN wget ${PWSHURL}
RUN yes | dpkg -i powershell-lts_7.2.5-1.deb_amd64.deb
RUN apt -y install -f

RUN wget ${SERVERURL} -O serve
RUN chmod +x serve

# Setup: install dotnet and friends
RUN apt -y install gnupg ca-certificates dotnet6
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
RUN echo "deb https://download.mono-project.com/repo/ubuntu stable-bionic main" | tee /etc/apt/sources.list.d/mono-official-stable.list
RUN apt -y update && apt -y install mono-roslyn mono-complete mono-dbg msbuild

# Setup: install luarocks and deps
RUN apt -y update && apt -y install \
    luarocks \
    libgtk-3-dev

WORKDIR /Olympus
VOLUME /Olympus
# COPY . .

# Setup: luarocks config
RUN git config --global url."https://github.com/".insteadOf git://github.com/ && \
    luarocks config lua_version 5.1

EXPOSE 8080
ENTRYPOINT ["./build.sh"]
