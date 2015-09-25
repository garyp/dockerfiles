FROM ubuntu:vivid
MAINTAINER Gary Peck <gary@realify.com>

RUN useradd -m builder

RUN apt-get update \
    && apt-get build-dep -y --no-install-recommends vim \
    && apt-get install -y --no-install-recommends \
        # python3 support
        python3-dev \
        # from https://github.com/Valloric/YouCompleteMe/wiki/Building-Vim-from-source
        libncurses5-dev \
        libgnome2-dev \
        libgnomeui-dev \
        libgtk2.0-dev \
        libatk1.0-dev \
        libbonoboui2-dev \
        libcairo2-dev \
        libx11-dev \
        libxpm-dev \
        libxt-dev \
        python-dev \
        ruby-dev \
        git \
    && rm -rf /var/lib/apt/lists/*

USER builder
WORKDIR /home/builder
RUN git clone https://github.com/vim/vim.git

# based on configure flags suggested at https://github.com/Valloric/YouCompleteMe/wiki/Building-Vim-from-source
RUN cd vim && ./configure \
        --with-features=huge \
        --enable-multibyte \
        --enable-rubyinterp \
        --enable-perlinterp \
        --enable-luainterp \
        --enable-cscope \
        # compile with gnome2 support, not just gtk2
        --enable-gui=gnome2 \
        # use dynamic support for python so both versions can be built
        --enable-pythoninterp=dynamic \
        --with-python-config-dir=$(python-config --configdir) \
        --enable-python3interp=dynamic \
        --with-python3-config-dir=$(python3-config --configdir) \
        --prefix=/usr/local \
    && make VIMRUNTIMEDIR=/usr/share/vim/vim74 \
    && make DESTDIR=$HOME/out install

ENV PATH /home/builder/out/usr/local/bin:$PATH
CMD ['vim']
