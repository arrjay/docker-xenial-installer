FROM xenial-bootable

# install selinux for writing rh images
# note that installing selinux itself should be the _last_ thing you do as we explicitly break the grub-pc dep
RUN dpkg-divert --rename /usr/sbin/update-grub && ln -s /bin/true /usr/sbin/update-grub && \
    dpkg-divert --rename /usr/sbin/update-selinux-policy && ln -s /bin/true /usr/sbin/update-selinux-policy && \
    apt-get -qq update && \
    env LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get -qq -y purge apparmor && \
    env LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get --no-install-recommends install -q -y \
     checkpolicy libapol4 libqpol1 policycoreutils gdisk memtester \
     python-ipy python-selinux python-semanage python-sepolgen python-sepolicy python-setools \
     selinux-utils pxz xorriso jq curl gawk libsigsegv2 && \
    env LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get download selinux selinux-policy-ubuntu && \
    dpkg -i --ignore-depends=grub-pc /selinux_*.deb && \
    dpkg -i /selinux-*.deb && \
    rm -rf /selinux*.deb && \
    rm /usr/sbin/update-grub && dpkg-divert --rename --remove /usr/sbin/update-grub && \
    rm /usr/sbin/update-selinux-policy && dpkg-divert --rename --remove /usr/sbin/update-selinux-policy && \
    apt-get -q -y clean && rm -rf /var/lib/apt/lists/* && \
    touch /etc/selinux/ubuntu/contexts/files/file_contexts.local && update-selinux-policy && \
    rm /.autorelabel

# udev/dracut rules for identifying cdroms by label
ADD 61-blkid-cdroms.rules /etc/udev/rules.d/61-blkid-cdroms.rules
ADD dracut-modules/blkid-cdrom /usr/lib/dracut/modules.d/49blkid-cdrom

# we use fstab-sys for making tmpfs to unpack livecd into
ADD fstab.sys /etc/fstab.sys
ADD dracut-modules/livecd /usr/lib/dracut/modules.d/50livecd
ADD dracut.conf /etc/dracut.conf

# grab memtest86+
RUN curl -L -o /tmp/memtest-cd.tar.gz https://www.memtest86.com/downloads/memtest86-iso.tar.gz && \
    tar xf /tmp/memtest-cd.tar.gz -C /tmp Memtest86-7.5.iso && \
    mkdir -p /EFI/MEMTEST && \
    xorriso -osirrox on -indev /tmp/Memtest86-7.5.iso -extract / /tmp/memtest86 && \
    cp -R /tmp/memtest86/EFI/BOOT /EFI/MEMTEST && \
    rm -rf /tmp/memtest86 /tmp/memtest-cd.tar.gz /tmp/Memtest86-7.5.iso

# create EFI images and directories
RUN truncate -s 12M /boot/efiboot.img && mkfs.vfat -F16 /boot/efiboot.img && \
      mmd -i /boot/efiboot.img efi && mmd -i /boot/efiboot.img efi/boot && \
      mcopy -i /boot/efiboot.img /usr/lib/shim/shimx64.efi.signed ::efi/boot/bootx64.efi && \
      mcopy -i /boot/efiboot.img /usr/lib/grub/x86_64-efi-signed/gcdx64.efi.signed ::efi/boot/grubx64.efi && \
      mcopy -i /boot/efiboot.img /usr/lib/grub/i386-efi/gcdia32.efi ::efi/boot/bootia32.efi && \
      mcopy -i /boot/efiboot.img -s /EFI/MEMTEST ::efi/memtest && \
      mmd -i /boot/efiboot.img efi/boot/i386-efi && mcopy -i /boot/efiboot.img /usr/lib/grub/i386-efi/*.mod ::efi/boot/i386-efi && \
      mkdir -p /EFI/BOOT/i386-efi && cp /usr/lib/grub/i386-efi/*.mod /EFI/BOOT/i386-efi && \
      echo "insmod linux" >> "/EFI/BOOT/grub.cfg" && echo "configfile /boot/grub/grub.cfg" >> "/EFI/BOOT/grub.cfg"

## mac boot madness is just pilfered from fedora ;)
RUN wget -o /boot/macboot.img http://mirrors.kernel.org/fedora/releases/28/Server/x86_64/os/images/macboot.img && rm -f /macboot.img

# generate initrds before breaking fstab
RUN bash -c 'for f in /boot/vmlinuz-*-generic ; do v="${f#/boot/vmlinuz-}" ; dracut -f "/boot/initrd.img-${v}" "${v}" ; done'

# fstab _here_ does bind trickery
ADD fstab /etc/fstab
RUN touch /var/hostname

RUN mkdir -p /cdroot/var /cdroot/tmp /cdroot/home /cdroot/etc/ssh /cdroot/dev /cdroot/proc /cdroot/sys /cdroot/run /cdroot/root
RUN ln -sf /run/systemd/resolve/resolv.conf /cdroot/etc/resolv.conf

# pack and remove r/w dirs
RUN tar cpf /cdroot/var.tar  -C /var .  && pxz /cdroot/var.tar  && \
    tar cpf /cdroot/tmp.tar  -C /tmp .  && pxz /cdroot/tmp.tar  && \
    tar cpf /cdroot/home.tar -C /home . && pxz /cdroot/home.tar && \
    tar cpf /cdroot/root.tar -C /root . && pxz /cdroot/root.tar && \
    tar cpf /cdroot/ssh.tar  -C /etc/ssh '--exclude=ssh_host*' . && \
     pxz /cdroot/ssh.tar && \
    rm -rf /var /home /etc/ssh


# override cloud.d resize module
ADD cloud.cfg.d/* /etc/cloud/cloud.cfg.d/
RUN sed -i -e '/ - apt-.*/d' /etc/cloud/cloud.cfg

# replace apparmor cache
RUN mkdir -p /etc/apparmor.d && rm -rf /etc/apparmor.d/cache && ln -sf /var/run/apparmor-cache /etc/apparmor.d/cache

# service to start a console on _any_ serial port
ADD all-console-setup/addcons.service /etc/systemd/system/addcons.service
ADD all-console-setup/startcons.sh    /usr/local/sbin/startcons.sh
RUN ln -s /etc/systemd/system/addcons.service /etc/systemd/system/multi-user.target.wants/addcons.service

# replace pam login file with one that stops asking for passwords.
ADD pam-login /etc/pam.d/login

# update tmpfiles.d
ADD tmpfiles.d/* /etc/tmpfiles.d
RUN ln -sf /dev/null /etc/tmpfiles.d/home.conf && ln -sf ../proc/self/mounts /cdroot/etc/mtab

# tpl files for iso9660 booting and copy kernel/initrd to /isolinux
# isoloinux doesn't do symlinks
RUN bash -c 'd="" ; c="/isolinux/syslinux.cfg" ; g="/boot/grub/grub.cfg" ; \
             a="console=tty0 root=LABEL=xe_installer memhp_default_state=offline security=selinux selinux=1 enforcing=0 intel_iommu=on iommu=pt iommu=1 rw" ; \
             { echo "timeout 900" ; echo "prompt 1"; } > "${c}" ; \
             for i in /boot/initrd.img* ; do \
               v="${i%-generic*}" ; v="${v#*.img-}" ; \
               { [ ! -z "${d}" ] && d="${v}" ; echo "DEFAULT ${v}" >> "${c}" ; } ; \
               \
               echo "LABEL ${v}" >> "${c}" ; \
               echo " KERNEL vmlinuz-${v}-generic" >> "${c}" ; \
               echo " INITRD initrd.img-${v}-generic" >> "${c}" ; \
               echo " APPEND ${a}" >> "${c}" ; \
               \
               echo "menuentry '\''${v}'\'' {" >> "${g}" ; \
               echo "  linux /boot/vmlinuz-${v}-generic ${a}" >> "${g}" ; \
               echo "  initrd /boot/initrd.img-${v}-generic" >> "${g}" ; \
               echo "}" >> "${g}" ; \
               \
               cp "${i}" "/isolinux/${i/boot/}" ; \
               cp "/boot/vmlinuz-${v}-generic" "/isolinux/vmlinuz-${v}-generic" ; \
             done'

# dummy directory for iamges
RUN mkdir /images

# installation scripts
ADD scripts /scripts

# entrypoint will make an ISO
ENTRYPOINT /scripts/make-cdrom.sh
