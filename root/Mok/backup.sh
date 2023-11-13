# cat /boot/intel-ucode.img /boot/initramfs-linux-surface.img > /root/combined_initrd.img
# cat /boot/intel-ucode.img /boot/initramfs-linux-surface-fallback.img > /root/combined_initrd-fallback.img
# mv -bf /boot/initramfs-linux-surface.img /root/original-initramfs
# mv -bf /boot/initramfs-linux-surface-fallback.img /root/original-initramfs-fallback
# cp -rf /root/combined_initrd.img /boot/initramfs-linux-surface.img
# cp -rf /root/combined_initrd-fallback.img /boot/initramfs-linux-surface-fallback.img
osrel_offs=$(objdump -h "/usr/lib/systemd/boot/efi/linuxx64.efi.stub" | awk 'NF==7 {size=strtonum("0x"$3); offset=strtonum("0x"$4)} END {print size + offset}')
cmdline_offs=$((osrel_offs + $(stat -Lc%s "/usr/lib/os-release")))
splash_offs=$((cmdline_offs + $(stat -Lc%s "/etc/kernel/cmdline")))
linux_offs=$((splash_offs + $(stat -Lc%s "/usr/share/systemd/bootctl/splash-arch.bmp")))
initrd_offs=$((linux_offs + $(stat -Lc%s "/boot/vmlinuz-linux-surface")))
objcopy \
    --add-section .osrel="/usr/lib/os-release" --change-section-vma .osrel=$(printf 0x%x $osrel_offs) \
    --add-section .cmdline="/etc/kernel/cmdline" \
    --change-section-vma .cmdline=$(printf 0x%x $cmdline_offs) \
    --add-section .splash="/usr/share/systemd/bootctl/splash-arch.bmp" \
    --change-section-vma .splash=$(printf 0x%x $splash_offs) \
    --add-section .linux="/boot/vmlinuz-linux-surface" \
    --change-section-vma .linux=$(printf 0x%x $linux_offs) \
    --add-section .initrd="/boot/initramfs-linux-surface.img" \
    --change-section-vma .initrd=$(printf 0x%x $initrd_offs) \
    "/usr/lib/systemd/boot/efi/linuxx64.efi.stub" "linux-surface.efi"
sbsign --key MOK.key --cert MOK.crt --output /boot/EFI/EFI/shim/grubx64.efi linux-surface.efi
