FROM ubuntu:focal

ENV DEBIAN_FRONTEND=noninteractive

# INSTALL SOURCES FOR CHROME REMOTE DESKTOP AND VSCODE
RUN apt-get update && apt-get upgrade --assume-yes && \
    apt-get install --assume-yes curl gpg wget && \
    curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg && \
    mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg && \
    wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    echo "deb [arch=amd64] http://packages.microsoft.com/repos/vscode stable main" | tee /etc/apt/sources.list.d/vs-code.list && \
    echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list && \
    apt-get update

# INSTALL XFCE DESKTOP AND DEPENDENCIES
RUN apt-get install --assume-yes --fix-missing sudo wget apt-utils xvfb xfce4 xbase-clients \
    desktop-base vim xscreensaver google-chrome-stable python-psutil psmisc python3-psutil xserver-xorg-video-dummy ffmpeg \
    python3-packaging python3-xdg libutempter0 && \
    wget https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb && \
    dpkg --install chrome-remote-desktop_current_amd64.deb && \
    apt-get install --assume-yes --fix-broken

# INSTALL FIREFOX
RUN apt-get install --assume-yes firefox

# SPECIFY VARIABLES FOR SETTING UP CHROME REMOTE DESKTOP
ARG USER=myuser
ENV PIN=183183
ENV CODE=4/0AeaYSHBFgpncONUU76uZgbKIezatDx6RUE80VoXWeZf96ksYk81zcXUPP1q18KGjd387aA
ENV HOSTNAME=desk1

# ADD USER TO THE SPECIFIED GROUPS
RUN adduser --disabled-password --gecos '' $USER && \
    mkhomedir_helper $USER && \
    adduser $USER sudo && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    usermod -aG chrome-remote-desktop $USER

USER $USER
WORKDIR /home/$USER

# SETUP CHROME REMOTE DESKTOP SESSION
RUN mkdir -p .config/chrome-remote-desktop && \
    chown "$USER:$USER" .config/chrome-remote-desktop && \
    chmod a+rx .config/chrome-remote-desktop && \
    touch .config/chrome-remote-desktop/host.json && \
    echo "/usr/bin/pulseaudio --start" > .chrome-remote-desktop-session && \
    echo "startxfce4 :1030" >> .chrome-remote-desktop-session

CMD DISPLAY= /opt/google/chrome-remote-desktop/start-host --code=$CODE --redirect-url="https://remotedesktop.google.com/_/oauthredirect" --name=$HOSTNAME --pin=$PIN && \
    HOST_HASH=$(echo -n $HOSTNAME | md5sum | cut -c -32) && \
    FILENAME=.config/chrome-remote-desktop/host#${HOST_HASH}.json && echo $FILENAME && \
    cp .config/chrome-remote-desktop/host#*.json $FILENAME && \
    sudo service chrome-remote-desktop stop && \
    sudo service chrome-remote-desktop start && \
    echo $HOSTNAME && \
    sleep infinity & wait
