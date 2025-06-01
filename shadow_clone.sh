# == Warlord's Arch Installer == #
# Part 1 - shadow_clone
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

echo "Welcome To  ${SKY_BLUE}Warlord's${RESET} ${RED}Arch Installer${RESET}\n\n"

# Increase parallel downloads from 5 to 15
echo -e "\n${INFO} Increasing parallel downloads in pacman . . ."
sleep 1
sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads =15/" /etc/pacman.conf
echo -e "\n${OK} DONE"
sleep 1

# Download the latest keyring
printf '\033c'
echo -e "\n${INFO} Downloading latest arch-keyring \n"
sleep 1
pacman --noconfirm -Sy archlinux-keyring
loadkeys us
echo -e "\n${OK} DONE"
sleep 1

# Sync Time and Date
printf '\033c'
echo -e "\n${INFO} Setting up Network Time Protocol"
timedatectl set-ntp true
echo -e "\n${OK} DONE"
sleep 1

# Partitions
printf '\033c'
echo -e "\n\n${YELLOW}MAKE PARTITIONS${RESET}\n"
lsblk
echo -e "\n${NOTE} Enter the drive: "
read drive

echo -e "\n${NOTE} Make ${BLUE}EFI${RESET}, ${BLUE}ROOT${RESET} and ${BLUE}STORAGE${RESET} paritions\n${GREEN}[OPTIONAL] : SWAP${RESET}"
cfdisk $drive

# Format root partition
echo -e "\n${NOTE} Enter the ${YELLOW}ROOT${RESET} parition: "
read root
mkfs.ext4 $root
echo -e "${OK} root formatted"

# Format EFI parition
echo -e "\n${NOTE} Enter the ${YELLOW}EFI${RESET} partition: "
read efi 
mkfs.vfat -F 32 $efi
echo -e "${OK} efi formatted"
echo -e "${INFO} Peronal storage will be setup after installing btrfs inside the acutal fs [ chroot ]"

# Create SWAP // if it is created
read -p "Did you create a SWAP parition? [y/n]: " swapc
if [[ $swapc = y ]] ; then
  echo "Enter Swap partition: "
  read swap
  mkswap $swap
  swapon $swap
  echo -e "${OK} Swapped on $swap"
fi

# Mount partitions
mount $root /mnt 
mkdir -p /mnt/boot
mount $efi /mnt/boot
echo -e"${OK} Mounted ${MAGENTA}ROOT${RESET} and ${MAGENTA}EFI${RESET}"

# Base Install [ESSENTIALS]
printf '\033c'
echo -e"${INFO} Installing base"
sleep 1
pacstrap -K /mnt base base-devel linux-lts linux-zen linux-firmware networkmanager efibootmgr grub btrfs-progs ntfs-3g wget gvfs foremost dosfstools kitty bluez reflector git grub
echo -e"${OK} Base installed"
sleep 1

# Remaining packages are installed in the chroot environment

# genfstab
printf '\033c'
echo -e "${INFO} Generating fstab"
genfstab -U  /mnt > /mnt/etc/fstab
echo -e"${OK} fstab generated"

# chrooting [ and directing to a different file | for a new shell ]
echo -e "${OK}${SKY_BLUE} Base Arch Installed${RESET}"
sleep 1
echo -e "${INFO}${RESET} chrooting into the actual system"
sleep 2
sed '1,/^# actualSystem$/d' `basename $0` > /mnt/shadow_clone2.sh
chmod +x /mnt/shadow_clone2.sh
arch-chroot /mnt  ./shadow_clone2.sh
exit

# actualSystem
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

echo -e "\n${INFO} Inside the chroot [ actual root directory ]"

# 5 to 15 concurrency downloads
echo -e "\n${INFO} Increasing parallel downloads in pacman AND setting up mirrors . . ."
sleep 1
sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 15/" /etc/pacman.conf
reflector --country "india" --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
echo -e "\n${OK} DONE"
sleep 1

# setting timezone + system clock
echo -e "\n${INFO} Setting timezone and system clock"
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc
echo -e "\n${OK} Done"
sleep 1 

# setting locale
echo -e "${INFO} Setting locale"
sleep 1
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo -e "\n${OK} Done"
sleep 1

# setting keyboard layout
echo -e "\n${INFO} Setting keyboard layout"
echo "KEYMAP=us" > /etc/vconsole.conf
echo -e "\n${OK} Done"
sleep 1

# setting up Host 
printf '\033c'
echo -e "\n${INFO} Setting up Host"
sleep 1
echo -e "Enter Hostname: "
read hostname
echo $hostname > /etc/hostname

echo "127.0.0.1       localhost" >> /etc/hosts 
echo "::1             localhost" >> /etc/hosts 
echo "127.0.1.1       $hostname.localdomain $hostname" >> /etc/hosts
echo -e "\n${OK} Done"

# build initramfs 
printf '\033c'
echo -e "\n${INFO} Building initramfs . . ."
mkinitcpio -P 
printf '\033c'
echo -e "\n${OK} Done"
# I need both my lts and zen to be ready always

# set password for root 
printf '\033c'
echo -e "\n${WARN} Enter root password: "
passwd 

# Format storage partition
printf '\033c'
sleep 1
echo -e "\n${INFO} Setting up personal storage"
echo -e "Enter the ${YELLOW}storage${RESET} parition: "
read storage 
mkfs.btrfs -f $storage
echo -e "\n${OK} $storage format with btrfs fs"

# setting up BTRFS 


# mount Btrfs storage partition
echo -e "\n${INFO} Creating mount point and subvolumes"
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
echo -e "\n${OK} Mounted"

# add a user
printf '\033c'
echo -e "\n${INF0} Creating new user"
echo "Enter user: "
read user 
useradd -mG wheel,storage,audio,video,power,kvm,input -s /bin/sh $user

# set password for the user 
echo "Enter password: "
passwd $user

echo "${OK} User created"
echo "${GREEN} Setting up user${RESET}"

# setting up user
printf '\033c'
echo "${OK} Root fs built."
sleep 2
shadow_clone3=/home/$user/shadow_clone3.sh
sed '1,/^# userSetup$/d' shadow_clone2.sh > $shadow_clone3
chown $user:$user $shadow_clone3
chmod +x $shadow_clone3
su -c $shadow_clone3 -s /bin/sh 
exit


# userSetup
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
echo -e "${INFO} Building user environment"
sleep 2

# setting up grub 
echo -e "\n${INF0} Setting up GRUB"
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
echo -e "\n${OK} GRUB setup complete"
sleep 1

# X11
print '\033c'
echo -e "${INFO} Setting up X11 . . ."
sleep 1
pacman -Syu --noconfirm xorg xorg-server xorg-xinit xorg-xsetroot xclip xcompmgr xdotool xwallpaper xorg-xrandr
print '\033c'
echo -e "${OK} X11 setup complete"

# Dev Tools
print '\033c'
echo -e "${INFO} Setting up Dev Tools . . ."
sleep 1
pacman -S --noconfirm rsync syncthing tailscale scrcpy scrot tmux tree neovim vim git-lfs arch-install-scripts gcc npm imagemagick inxi jq mosh openbsd-netcat qemu-base qemu-full zram-generator zsh ripgrep unzip p7zip vde2 virt-manager virt-viewer tigervnc umockdev w3m sed feh ffmpeg mariadb 
print '\033c'
echo -e "${OK} Dev Tools setup complete"

# Security Tools
print '\033c'
echo -e "${INFO} Setting up Security tools . . ."
sleep 1
pacman -S --noconfirm nginx nmap nmon tlp ufw whois wipe metasploit
print '\033c'
echo -e "${OK} Security Tools setup complete."

# Libraries
print '\033c'
echo -e "${INFO} Setting up Libraries . . ."
sleep 1
pacman -S --noconfirm calcurse openssh libxft libxinerama openssl
print '\033c'
echo -e "${OK} Libraries setup complete."

# Sys Monitor
print '\033c'
echo -e "${INFO} Setting up System Monitoring . . ."
sleep 1
pacman -S --noconfirm at duf dust cpupower hwinfo nvtop htop btop atop powertop smartmontools radeontop
print '\033c'
echo -e "${OK} System Monitoring setup Complete."

# Applications
print '\033c'
echo -e "${INFO} Setting up Applications . . ."
sleep 1
pacman -S --noconfirm ranger slurp viu bc fzf gnome-calculator gnome-disk-utility mpv blueman nautilus thunar nemo eog cheese gimp asciiquarium sxiv zathura qutebrowser firefox kdenlive obs-studio 
print '\033c'
echo -e "${OK} Applications setup complete."

# Miscellaneous
print '\033c'
echo -e "${INFO} Setting up Miscellaneous . . ."
sleep 1
pacman -S --noconfirm sl cava fastfetch cowsay figlet lolcat uwufetch pamixer pavucontrol 
print '\033c'
echo -e "${OK} Miscellaneous setup complete."

# Fonts
print '\033c'
echo -e "${INFO} Setting up Fonts . . ."
sleep 1
pacman -S --noconfirm ttf-jetbrains-mono ttf-jetbrains-mono-nerd ttf-fira-code noto-fonts noto-fonts-emoji ttf-droid ttf-font-awesome
print '\033c'
echo -e "${OK} Fonts setup complete."

# since you have arch-install-scripts which includes genfstab 
print '\033c'
echo -e "${INFO} generating fstab . . ."
sleep 1
genfstab -U / >> /etc/fstab 
echo -e "${OK} fstab setup complete."
echo -e "${ERROR} check fstab now${RESET}"
sleep 1
vim /etc/fstab 

# now that you have libvert installed
usermod -aG libvert $user 
sleep 10
echo -e "${OK} added $user to libvert"

# download DWM
printf '\033c'
echo -e "${INFO} Downloading DWM . . ."
sleep 1
mkdir -p /mnt/KSS/backUps/archinstall/dwm/ 
cd /mnt/KSS/backUps/archinstall/dwm/ 
dwm_package=(dwm st dwmblocks dmenu)
myGithub=https://github.com/surajk013/

for repo in "${dwm_package[@]}"; do 
  git clone "$myGithub$repo"
done

echo -e "${OK} DWM successfully downloaded"


homeDir=/home/$user/
cd $homeDir
sleep 2 

# setup scripts 
printf '\033c'
echo -e "${INFO} Downloading scripts . . ."
sleep 1
git clone "${myGithub}scripts" 
cp -r ${homeDir}/scripts/*  /bin/
cp -r /bin/cpu/* /bin/ 
rm -rf /bin/cpu
cp ${homeDir}/scripts/cpu/* /bin/
echo -e "${OK} Scripts updated."
sleep 1


printf '\033c'
echo -e "${OK} Base user setup done."
sleep 2


finalFile=/home/$user/final.sh
echo -e "${OK} Reboot your machine and run $finalFile as $user with sudo privleges to finish setup !"
sed '1,/^# final$/d' `basename $0`> $finalFile
chmod +x $finalFile
exit

# final
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
echo -e "${INFO} Final build for the user [FINISHING TOUCH]"
myGithub=https://github.com/surajk013/

# setting up AUR
printf '\033c'
echo -e "${INFO} setting YAY aur"
sleep 1
git clone https://aur.archlinux.org/aur.git
cd aur 
makepkg -fsri
echo -e "${OK} YAY aur setup complete."

# Downloading AUR packages
printf '\033c'
echo -e "${INFO} Downloading aur packages"
sleep 1
yay -S --noconfirm tty-clock wtf cbonsai neofetch pfetch secure-delete hollywood ani-cli steghide auto-cpufreq barrier vimv magnus transmission google-chrome-stable onlyoffice-bin upscyal-bin android-studio 
echo -e "${OK} aur packages BUILT."

# setting up DWM 
printf '\033c'
echo -e "${INFO} Installing DWM"
sleep 1
cd /mnt/KSS/backUps/archinstall/dwm/ 
cd dwm && make clean install && 
cd ../st && make clean install && 
cd ../dmenu && make clean install && 
cd ../dwmblocks && make clean install 
echo -e "${OK} DWM installation done"

# setting up Hyprland
printf '\033c'
echo -e "${INFO} Installing Hyprland in 10 seconds \n 
         Please fill prompts \n 
         ${RED}DO NOT REBOOT${RESET} even on prompt"


printf '\033c'
echo -e "${INFO} Cloning Jakoolit's Arch-Hyprland . . ."
git clone https://github.com/Jakoolit/arch-hyprland
cd arch-hyprland
echo -e "${OK} Cloned."
sleep 1 
for ((i=0;i<10;i++)); do 
  echo "${RED}ENTER PROMPT${RESET}"
done
sleep 1 
echo -e "${INFO} Installing now. . ."
./install.sh
echo -e "${OK} Hyprland Installation Complete."
sleep 1
cd $(home)/.config/hypr/UserScripts/
sed -i "s/INTERVAL=.*/INTERVAL=7200/" WallpaperAutoChange.sh
sed -i "s/wallDIR=.*/wallDIR=\/mnt\/KSS\/Media\/wallpapers\//" WallpaperRandom.sh WallpaperSelect.sh
echo -e "${OK} Wall dir + Interval updated."
cd $(home)/.config/hypr/scripts/ 
sed -i "s/^dir=.*/dir=\/mnt\/KSS\/backUps\/poco\/dcim\/screenshots\//" ScreenShot.sh
echo -e "${OK} Screenshot dir updated."

# setup myDots 
printf '\033c'
echo -e "${INFO} Downloading dots"
sleep 1
git clone "${myGithub}dot-files"
cd $(home)/dot-files/
mkdir -p "$(home)/.config/tmux" "$(home)/.config/qutebrowser" "$(home)/.config/kitty/"
cp .tmux.conf "$(home)/.config/tmux/"
cp config.py "$(home)/.config/qutebrowser/"
cp kitty.conf "$(home)/.config/kitty/"
cp .zshrc .vimrc "$(home)/"
mkdir -p $(home)/.config/nvim/
cp -r nvim "$(home)/.config/nvim/"
echo -e "${OK} dots updated"
sleep 1 
echo -e "${INFO} setup neovim"
sleep 1
nvim
echo -e "${NOTE} Setup Tailscale and Syncthing from archinstall/Syncthing/ filemangaer "
sleep 1
echo -e "${SKY_BLUE} ARCH INSTALL SUCCESSFULL ${RESET}"
sleep 2
echp -ne "${ORANGE} Welcome to Warlord's Arch Install${RESET}_"
sleep 3
Hyprland
sleep 2
