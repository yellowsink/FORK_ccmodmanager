FROM ubuntu:22.04

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Set some common environment variables
ENV PWSH="pwsh -NoLogo -NoProfile -NonInteractive -Command"
ENV PWSHURL="https://github.com/PowerShell/PowerShell/releases/download/v7.2.5/powershell-lts_7.2.5-1.deb_amd64.deb"
ENV LOVEURL="https://github.com/love2d/love/releases/download/11.3/love-11.3-linux-x86_64.tar.gz"
ENV LOVETAR="love.tar.gz"

WORKDIR /

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


# Setup: install dotnet and friends
RUN apt -y install gnupg ca-certificates dotnet6
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
RUN echo "deb https://download.mono-project.com/repo/ubuntu stable-bionic main" | tee /etc/apt/sources.list.d/mono-official-stable.list
RUN apt -y update && apt -y install mono-roslyn mono-complete mono-dbg msbuild

# Setup: install luarocks and deps
RUN apt -y update && apt -y install \
    luarocks \
    libgtk-3-dev

RUN git clone https://github.com/EverestAPI/Olympus
WORKDIR /Olympus

# Setup: luarocks config
RUN git config --global url."https://github.com/".insteadOf git://github.com/ && \
    luarocks config lua_version 5.1

# Build: install luarocks dependencies
RUN luarocks install --tree=luarocks https://raw.githubusercontent.com/0x0ade/lua-subprocess/master/subprocess-scm-1.rockspec && \
    luarocks install --tree=luarocks https://raw.githubusercontent.com/Vexatos/nativefiledialog/master/lua/nfd-scm-1.rockspec && \
    luarocks install --tree=luarocks lsqlite3complete

# Build: restore sharp
RUN dotnet restore sharp/Olympus.Sharp.csproj --verbosity Detailed

# Build: build sharp
RUN msbuild sharp/*.sln "/p:Configuration=Release" "/p:Platform=Any CPU"

RUN wget -O ${LOVETAR} ${LOVEURL}
RUN tar -xvzf ${LOVETAR}
RUN mkdir -p love-raw && \
    tar xvf ${LOVETAR}
