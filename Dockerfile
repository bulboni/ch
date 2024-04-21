FROM debian

ENV DEBIAN_FRONTEND=noninteractive

# INSTALL SOURCES FOR CHROME REMOTE DESKTOP AND VSCODE
RUN apt-get update && apt-get upgrade --assume-yes && \
    apt-get --assume-yes install curl gpg wget tmate && \
    curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg && \
    mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg && \
    wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    echo "deb [arch=amd64] http://packages.microsoft.com/repos/vscode stable main" | \
       tee /etc/apt/sources.list.d/vs-code.list && \
    sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'

# INSTALL XFCE DESKTOP AND DEPENDENCIES
RUN apt-get update && apt-get upgrade --assume-yes && \
    apt-get install --assume-yes --fix-missing sudo wget apt-utils xvfb xfce4 xbase-clients \
        desktop-base vim xscreensaver psmisc python3-psutil xserver-xorg-video-dummy ffmpeg && \
    apt-get install --assume-yes python3-packaging python3-xdg && \
    apt-get install libutempter0

# INSTALL FIREFOX
RUN apt-get install --assume-yes firefox-esr

# INSTALL CHROME REMOTE DESKTOP
RUN wget https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb && \
    dpkg --install chrome-remote-desktop_current_amd64.deb && \
    apt-get install --assume-yes --fix-broken && \
    bash -c 'echo "exec /etc/X11/Xsession /usr/bin/xfce4-session" > /etc/chrome-remote-desktop-session'

# SPECIFY VARIABLES FOR SETTING UP CHROME REMOTE DESKTOP
ARG USER=myuser
ENV PIN=183183
ENV CODE=4/0AeaYSHB9jtGvzr_fUGBh1KSsNjy3j1HtbODsPJCGcP-EsB2Fwgjv_gUtEQwHOGeS5uWG6w
ENV HOSTNAME=myvirtualdesktop

# ADD USER TO THE SPECIFIED GROUPS
RUN adduser --disabled-password --gecos '' $USER && \
    mkhomedir_helper $USER && \
    adduser $USER sudo && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    usermod -aG chrome-remote-desktop $USER

USER $USER
WORKDIR /home/$USER

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
