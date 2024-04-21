FROM ubuntu:focal

ENV DEBIAN_FRONTEND=noninteractive

# INSTALL SOURCES FOR CHROME REMOTE DESKTOP AND VSCODE
RUN apt-get update && apt-get upgrade --assume-yes && \
    apt-get --assume-yes install curl gpg wget tmate && \
    curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg && \
    mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg && \
    wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    echo "deb [arch=amd64] http://packages.microsoft.com/repos/vscode stable main" | \
    tee /etc/apt/sources.list.d/vs-code.list && \
    echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list && \
    apt-get update

# INSTALL XFCE DESKTOP AND DEPENDENCIES
RUN apt-get install --assume-yes --fix-missing sudo wget apt-utils xvfb xfce4 xbase-clients \
    desktop-base vim xscreensaver google-chrome-stable python-psutil psmisc python3-psutil xserver-xorg-video-dummy ffmpeg && \
    apt-get install --assume-yes python3-packaging python3-xdg libutempter0 && \
    wget https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb && \
    dpkg --install chrome-remote-desktop_current_amd64.deb && \
    apt-get install --assume-yes --fix-broken && \
    bash -c 'echo "exec /etc/X11/Xsession /usr/bin/xfce4-session" > /etc/chrome-remote-desktop-session'

RUN apt-get install --assume-yes firefox

# SPECIFY VARIABLES FOR SETTING UP CHROME REMOTE DESKTOP
ARG USER=myuser
# use 6 digits at least
ENV PIN=183183
ENV CODE=4/0AeaYSHBERxNfXFkASmlGiL4O5H2cNSAVNXqP-i2QDQBBDMJv4mFPF98TQekJfyxasOiPeA
ENV HOSTNAME=myvirtualdesktop

# ADD USER TO THE SPECIFIED GROUPS
RUN adduser --disabled-password --gecos '' $USER && \
    mkhomedir_helper $USER && \
    adduser $USER sudo && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    usermod -aG chrome-remote-desktop $USER && \
    mkdir -p /home/$USER/.config/chrome-remote-desktop && \
    chown -R $USER:$USER /home/$USER/.config/chrome-remote-desktop && \
    chmod -R a+rx /home/$USER/.config/chrome-remote-desktop && \
    touch /home/$USER/.config/chrome-remote-desktop/host.json && \
    echo "/usr/bin/pulseaudio --start" > /home/$USER/.chrome-remote-desktop-session && \
    echo "startxfce4 :1030" >> /home/$USER/.chrome-remote-desktop-session

# SETUP SSH and TMATE


EXPOSE 80 443 3306 4040 5432 5700 5701 5010 6800 6900 8080 8888 9000

CMD \
   sudo service chrome-remote-desktop stop && \
   sudo tmate -F && \
   echo $HOSTNAME && \
   sleep infinity & wait

