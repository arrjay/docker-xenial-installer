FROM xenial-bootable

# service to start a console on _any_ serial port
ADD all-console-setup/addcons.service /etc/systemd/system/addcons.service
ADD all-console-setup/startcons.sh    /usr/local/sbin/startcons.sh
RUN ln -s /etc/systemd/system/addcons.service /etc/systemd/system/multi-user.target.wants/addcons.service

# replace pam login file with one that stops asking for passwords.
ADD pam-login /etc/pam.d/login

# installation scripts
ADD scripts /scripts

# remove apt lists
RUN rm -rf /var/lib/apt/lists/*

# replace apparmor cache
RUN rm -rf /etc/apparmor.d/cache && ln -sf /var/run/apparmor-cache /etc/apparmor.d/cache

# update tmpfiles.d
ADD tmpfiles.d/* /etc/tmpdiles.d
RUN ln -sf /dev/null /etc/tmpfiles.d/home.conf

# override cloud.d resize module
ADD cloud.cfg.d/* /etc/cloud/cloud.cfg.d/
RUN sed -i -e '/ - apt-.*/d' /etc/cloud/cloud.cfg

# udev/dracut rules for identifying cdroms by label
ADD 61-blkid-cdroms.rules /etc/udev/rules.d/61-blkid-cdroms.rules
ADD dracut-modules/blkid-cdrom /usr/lib/dracut/modules.d/49blkid-cdrom

# we use fstab-sys for making tmpfs to unpack livecd into
ADD fstab.sys /etc/fstab.sys
ADD dracut-modules/livecd /usr/lib/dracut/modules.d/50livecd
ADD dracut.conf /etc/dracut.conf

# fstab _here_ does bind trickery
ADD fstab /etc/fstab
RUN touch /var/hostname

# regenerate initrd finally
RUN bash -c 'for i in /boot/initrd.img* ; do v="${i#/boot/initrd.img-}" ; dracut -f "${i}" "${v}" ; done'

# pack and remove r/w dirs
RUN tar cpf var.tar  -C /var .  && \
    tar cpf tmp.tar  -C /tmp .  && \
    tar cpf home.tar -C /home . && \ 
    tar cpf ssh.tar  -C /etc/ssh '--exclude=ssh_host*' . && \
    rm -rf /var /tmp /home /etc/ssh && \
    mkdir /var /tmp /home /etc/ssh

# replace mtab
RUN ln -sf "../proc/self/mounts" "/etc/mtab"
