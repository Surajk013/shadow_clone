# == Warlord's Arch Installer == #
#part1

OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
NOTE="$(tput setaf 3)[NOTE]$(tput sgr0)"
INFO="$(tput setaf 4)[INFO]$(tput sgr0)"
WARN="$(tput setaf 1)[WARN]$(tput sgr0)"
CAT="$(tput setaf 6)[ACTION]$(tput sgr0)"
MAGENTA="$(tput setaf 5)"
ORANGE="$(tput setaf 214)"
WARNING="$(tput setaf 1)"
YELLOW="$(tput setaf 3)"
GREEN="$(tput setaf 2)"
BLUE="$(tput setaf 4)"
RED="$(tput setaf 1)"
SKY_BLUE="$(tput setaf 6)"
RESET="$(tput sgr0)"


printf '\033c'
echo "Welcome To  ${SKY_BLUE}Warlord's${RESET} ${RED}Arch Installer${RESET}"

# Increase parallel downloads from 5 to 15
echo -e "${NOTE}[NOTE]${NOTE} increasing parallel downloads in pacman"
sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads =15/" /etc/pacman.conf


# Download the latest keyring
echo -e "${NOTE}[NOTE]${NOTE} downloading latest arch-keyring"
pacman --noconfirm -Sy archlinux-keyring
loadkeys us

# Sync Time and Date
echo -e "${NOTE}[NOTE]${NOTE} setting up date and time"
timedatectl set-ntp true

# Partitions
echo -e "\n ${YELLOW}MAKE PARTITIONS${RESET}\n"
lsblk
echo -e "\n Enter the drive: "
read drive

echo -e "\n make ${BLUE}EFI${RESET}, ${BLUE}ROOT${RESET} and ${BLUE}STORAGE${RESET} paritions ${GREEN}[OPTIONAL]: SWAP${RESET}"
cfdisk $drive

# Format root partition
echo -e "Enter the ${YELLOW}root${RESET} parition: "
read root
mkfs.ext4 $root

# Format EFI parition
echo -e "Enter ${YELLOW}EFI${RESET} partition: "
read efi 
mkfs.vfat -F 32 $efi

# Create SWAP // if it is created
read -p "Did you create a SWAP parition? [y/n]: " swapc
if [[ $swapc = y ]] ; then
  echo "Enter Swap partition: "
  read swap
  mkswap $swap
  swapon $swap
fi

# Mount partitions
mount $root /mnt 
mkdir -p /mnt/boot
mount $efi /mnt/boot

# Base Install [ESSENTIALS]
pacstrap -K /mnt base base-devel linux-lts linux-zen linux-firmware networkmanager efibootmgr grub btrfs-progs ntfs-3g wget gvfs foremost dosfstools kitty bluez reflector git grub

# Remaining packages are installed in the chroot environment

# genfstab
genfstab -U  /mnt > /mnt/etc/fstab

# chrooting [ and directing to a different file | for a new shell ]
sed '1,/^# actualSystem$/d' `basename $0` > /mnt/shadow_clone2.sh
chmod +x /mnt/shadow_clone2.sh
arch-chroot /mnt  ./shadow_clone2.sh
exit

# actualSystem
# 5 to 15 concurrency downloads
echo -e "\n\n\n\n${RED}$(pwd)${RESET}\n\n\n\n"
sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 15/" /etc/pacman.conf
reflector --country "india" --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

# setting timezone + system clock
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc

# setting locale
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# setting keyboard layout
echo "KEYMAP=us" > /etc/vconsole.conf

# setting us Host in the Network
echo -e "Enter Hostname: "
read hostname
echo $hostname > /etc/hostname

echo "127.0.0.1       localhost" >> /etc/hosts 
echo "::1             localhost" >> /etc/hosts 
echo "127.0.1.1       $hostname.localdomain $hostname" >> /etc/hosts

# build initramfs 
mkinitcpio -P 
# I need both my lts and zen to be ready always

# set password for root 
passwd 

echo -e "${ERROR} check if EFI is mounted${RESET} "

# Format storage partition
echo -e "Enter the ${YELLOW}storage${RESET} parition: "
read storage 
mkfs.btrfs -f $storage

# setting up BTRFS 


# mount Btrfs storage partition
mount -t btrfs $storage /mnt/KSS
btrfs subv create /mnt/KSS/Media
btrfs subv create /mnt/KSS/Documents
btrfs subv create /mnt/KSS/Learnings
btrfs subv create /mnt/KSS/backUps
mkdir -p /mnt/KSS/.btrfssnapshots/

mount $storage /mnt/KSS/Media 
mount $storage /mnt/KSS/Documents
mount $storage /mnt/KSS/backUps
mount $storage /mnt/KSS/Learnings




# add a user
echo "Enter user: "
read user 
useradd -mG wheel,storage,audio,video,power,kvm,input -s /bin/sh $user

# set password for the user 
echo "Enter password: "
passwd $user

echo "${INFO}System setup finished"
echo "${GREEN}Setting up user"

# setting up user
shadow_clone3=/home/$user/shadow_clone3.sh
sed '1,/^# userSetup$/d' shadow_clone2.sh > $shadow_clone3
chown $user:$user $shadow_clone3
chmod +x $shadow_clone3
su -c $shadow_clone3 -s /bin/sh 
exit


# userSetup
printf '\033c'
echo -e "\n\n\n\n$(whoami)\n\n\n\n"

# setting up grub 
echo -e "\n\n${INF0}[ INFO ]${RESET} setting up GRUB"
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
echo -e "\n\n${INFO}[ INFO ]${RESET} GRUB setup complete"

# X11
pacman -Syu --noconfirm xorg xorg-server xorg-xinit xorg-xsetroot xclip xcompmgr xdotool xwallpaper xorg-xrandr

# Dev Tools
pacman -S --noconfirm rsync syncthing tailscale scrcpy scrot tmux tree neovim vim git-lfs arch-install-scripts gcc npm imagemagick inxi jq mosh openbsd-netcat qemu-base qemu-full zram-generator zsh ripgrep unzip p7zip vde2 virt-manager virt-viewer tigervnc umockdev w3m sed feh ffmpeg mariadb 

# Security Tools
pacman -S --noconfirm nginx nmap nmon tlp ufw whois wipe metasploit

# Libraries
pacman -S --noconfirm calcurse openssh libxft libxinerama openssl

# Sys Monitor
pacman -S --noconfirm at duf dust cpupower hwinfo nvtop htop btop atop powertop smartmontools radeontop

# Applications
pacman -S --noconfirm ranger slurp viu bc fzf gnome-calculator gnome-disk-utility mpv blueman nautilus thunar nemo eog cheese gimp asciiquarium sxiv zathura qutebrowser firefox kdenlive obs-studio 

# Miscellaneous
pacman -S --noconfirm sl cava fastfetch cowsay figlet lolcat uwufetch pamixer pavucontrol 

# Fonts
pacman -S --noconfirm ttf-jetbrains-mono ttf-jetbrains-mono-nerd ttf-fira-code noto-fonts noto-fonts-emoji ttf-droid ttf-font-awesome

# since you have arch-install-scripts which includes genfstab 
genfstab -U / >> /etc/fstabdelete 
echo -e "${ERROR} check fstab now${RESET}"
cat /etc/fstab 
sleep 10

# setup DWM
echo -e "${INFO}[INFO]${RESET} Installing DWM"
mkdir -p /mnt/KSS/backUps/archinstall/dwm/ 
cd /mnt/KSS/backUps/archinstall/dwm/ 
dwm_package=(dwm st dwmblocks dmenu)
myGithub=https://github.com/surajk013/

for repo in "${dwm_package[@]}"; do 
  git clone "$myGithub$repo"
done

echo -e "${OK}[OK]${RESET} DWM successfully installed"


homeDir=/home/$user/
cd $homeDir
sleep 2 
echo -e "\n\nthe user variable holds: ${user}"
sleep 10

# setup scripts 
echo -e "${INFO}[INFO]${RESET} Downloading scripts"
git clone "${myGithub}scripts" 
cp -r ${homeDir}/scripts/*  /bin/
cp -r /bin/cpu/* /bin/ 
rm -rf /bin/cpu
cp ${homeDir}/scripts/cpu/* /bin/
echo -e "${OK}[OK]${RESET} scripts updated"



finalFile=/home/$user/final.sh
sed '1,/^# final$/d' `basename $0`> $finalFile
chmod +x $finalFile
echo -e "run $finalFile with sudo privleges to finish setup"
exit

# final
myGithub=https://github.com/surajk013/
# setting up AUR
git clone https://aur.archlinux.org/aur.git
cd aur 
makepkg -fsri
# Downloading AUR packages
yay -S --noconfirm tty-clock wtf cbonsai neofetch pfetch secure-delete hollywood ani-cli steghide auto-cpufreq barrier vimv magnus transmission google-chrome-stable onlyoffice-bin upscyal-bin android-studio 


# setting up Hyprland
echo -e "${INFO}[INFO]${RESET} Installing Hyprland in 10 seconds \n 
         Please fill prompts \n 
         ${RED}DO NOT REBOOT${RESET} even on prompt"

for ((i=0;i<1000;i++)); do 
  echo "${RED}ENTER PROMPT${RESET}"
done

sleep 10


git clone https://github.com/Jakoolit/arch-hyprland
cd arch-hyprland
./install.sh

# setup myDots 
echo -e "${INFO}[INFO]${RESET} Downloading dots"
git clone "${myGithub}dot-files"
cd ${home}/dot-files/
mkdir -p "${home}/.config/tmux" "${home}/.config/qutebrowser" "${home}/.config/kitty/"
cp .tmux.conf "${home}.config/tmux/"
cp config.py "${home}.config/qutebrowser/"
cp kitty.conf "${home}.config/kitty/"
cp .zshrc .vimrc "${home}/"
echo -e"${OK}[OK]${RESET} dots updated"
