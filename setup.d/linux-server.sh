#!/bin/bash
# setup.d/linux-server.sh — Linux 服务器专属配置
# 需要 root 权限，通过 --full 标志触发

[ "$(id -u)" -ne 0 ] && {
  _err "linux-server.sh 需要 root 权限"
  exit 1
}

# ─── Swap ───
_echo "creating swap"
if [[ ! -f /swapmeet ]]; then
  dd if=/dev/zero of=/swapmeet bs=128M count=32
  chmod 600 /swapmeet
  mkswap /swapmeet
  swapon /swapmeet
  swapon -s
  echo "/swapmeet swap swap defaults 0 0" >> /etc/fstab
  echo "vm.swappiness=0" >> /etc/sysctl.conf
  sysctl vm.swappiness=0
fi
_ok "swap 就绪"

# ─── Locale ───
_echo "setting up locales and console"
locale-gen "en_US.UTF-8"
localectl set-locale en_US.UTF-8
dpkg-reconfigure -f noninteractive locales
dpkg-reconfigure -f noninteractive console-setup
systemctl daemon-reload
systemctl restart console-setup.service
_ok "locale 已配置"

# ─── 时区和主机名 ───
_echo "setting up timezone and hostname"
timedatectl set-timezone "${TIMEZONE:-America/New_York}"
if [[ -n "${HOSTNAME_SET:-}" ]]; then
  hostname "$HOSTNAME_SET"
  hostnamectl set-hostname "$HOSTNAME_SET"
  sed -i '/^127\.0\.0\.1\s/s/$/ '"$HOSTNAME_SET"'/' /etc/hosts
fi
_ok "时区和主机名已配置"

# ─── 创建用户 ───
if [[ -n "${CREATE_USER:-}" ]]; then
  _echo "creating local user: $ME"
  if ! id "$ME" &>/dev/null; then
    adduser --uid "${X_UID:-1000}" --shell "$(which zsh)" "$ME"
    echo "${ME} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$ME"
  fi
  _ok "用户 $ME 已创建"
fi

# ─── SSH 密钥 ───
_echo "setting up ssh keys"
ensure_dir "$MYHOME/.ssh" "$ME:$ME"
if [[ -d /home/admin/.ssh ]]; then
  cp /home/admin/.ssh/authorized_keys "$MYHOME/.ssh/authorized_keys" 2>/dev/null
elif [[ -d /root/.ssh ]]; then
  cp /root/.ssh/authorized_keys "$MYHOME/.ssh/authorized_keys" 2>/dev/null
fi
ssh-keyscan -p 22 -H github.com gist.github.com >> "$MYHOME/.ssh/known_hosts" 2>/dev/null
chown -R "$ME:$ME" "$MYHOME/.ssh"
chmod 700 "$MYHOME/.ssh"
chmod 600 "$MYHOME/.ssh/"* 2>/dev/null
_ok "ssh 已配置"

# ─── systemd ───
_echo "systemd housekeeping"
systemctl enable clamav-freshclam.service 2>/dev/null
_ok "systemd 服务已配置"

# ─── SSH 端口 ───
_echo "setting up ssh port"
if [[ -n "${SSH_PORT:-}" ]]; then
  if ! grep -q "^Port $SSH_PORT" /etc/ssh/sshd_config; then
    echo "Port $SSH_PORT" >> /etc/ssh/sshd_config
    systemctl restart ssh.service
    systemctl restart sshd 2>/dev/null
  fi
  _ok "SSH 端口已设为 $SSH_PORT"
fi

# ─── fail2ban ───
_echo "setting up fail2ban"
if [[ -f /etc/fail2ban/jail.conf ]]; then
  cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
  fail2ban-client reload 2>/dev/null
fi
_ok "fail2ban 已配置"

# ─── MOTD ───
_echo "updating motd"
rm -f /etc/motd /etc/update-motd.d/*
cat << 'X0' > /etc/update-motd.d/00-banner
#!/bin/bash
draw() {
  out=
  perc=$1
  size=$2
  inc=$(( perc * size / 100 ))
  color=36
  color2=95
  for v in $(seq 0 $(( size - 1 ))); do
    [ "$v" -le "$inc" ] && out="${out}\e[1;${color}m${FULL}" || out="${out}\e[0;${color2}m${EMPTY}"
  done
  printf "$out"
}

i=1
c=$(printf "\e[0m\e[31m░▒")
while [ $i -le 6 ];do
  c=${c}$(printf "\e[$((i+41))m\e[$((i+30))m█▓▒░")
  i=$((i+1))
done
COLORS=${c}$(printf "\e[37m█\e[0m▒░")

FULL=━
EMPTY=┄
HOST=$(hostname)
IP=$(curl -s icanhazip.com)
DISTRO=$(grep PRETTY </etc/os-release | sed 's/PRETTY_NAME=//;s/"//g;s/GNU.Linux / /')
KERNEL=$(uname -r)
PKGS=$(apt list --installed 2>/dev/null | grep -c 'installed')
UPTIME=$(uptime -p | cut -d " " -f2-)
[[ ${#UPTIME} -ge 22 ]] && UPTIME=$(echo "$UPTIME" | sed 's/ hours/hrs/;s/ minutes/mins/')

c_lvl=$(printf "%.0f" `grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage}'`)
CPU=$(printf "\e[0;36m%-4s \e[1;95m%-5s %-25s \n" "cpu" "$c_lvl%" `draw "$c_lvl" 18`)

ram_lvl=$(free | awk '/Mem:/ {print int($3/$2 * 100.0)}')
RAM=$(printf "\e[0;36m%-4s \e[1;95m%-5s %-25s \n" "ram" "$ram_lvl%" `draw "$ram_lvl" 18`)

disk_lvl=$(df -h | grep '/$' | tr -s ' ' | cut -d ' ' -f5 | sed 's/%//')
DISK=$(printf "\e[0;36m%-4s \e[1;95m%-5s %-25s \n" "disk" "$disk_lvl%" `draw "$disk_lvl" 18`)

PPID1=$(grep PPid <"/proc/$PPID/status" | awk '{ print $2 }')
PPID2=$(grep PPid <"/proc/$PPID1/status" | awk '{ print $2 }')
USERNAME=$(pgrep "$PPID2" | awk '{ print $6 }' | head -1)
[ -z "$USERNAME" ] && USERNAME=$USER

files=0
IFS=':' read -r -a PATHS <<<"$PATH"
mapfile -t DIRS <<<"$(printf "%s\n" "${PATHS[@]}" | sort -u)"
for d in "${DIRS[@]}"; do
  [ -d "$d" ] && { new=$(find "$d" -maxdepth 1 -type f -executable -print | wc -l); files=$(( files+new )); }
done

cat << EOF

 [37;40m [95;40m▄[95;45m██[95;40m██[37;40m  [37;40m [37;40m  [37;40m [95;40m▄█[95;40m██[95;40m▄[37;40m  [37;40m
 [90;40m▄▄[37;40m [95;45m▒▓[95;45m█[37;40m [90;40m▄▄[90;40m▀[37;40m [95;40m█[95;45m▓░[37;40m [95;45m░▓[95;40m█[37;40m [90;40m▀[90;40m▄▄[37;40m    welcome to [95;40m$HOST[37;40m, $USERNAME
 [36;40m▒▒[37;40m [95;45m░▒[95;45m▓[37;40m [36;40m▒▒[37;40m [95;45m▓▓[95;45m░[35;40m▌[90;40m▄[35;40m▐[95;45m░▓[95;45m▓[37;40m [36;40m▒▒ $COLORS
 [90;40m▀▀[37;40m [96;46m░[95;45m░▒[37;40m [90;40m▀▀[37;40m [95;45m▓▒[95;45m░[37;40m [90;40m▀[37;40m [96;46m░[95;45m▒▓[37;40m [90;40m▀▀[95;40m distro: $DISTRO
 [34;40m░░[37;40m [96;46m░░[95;45m░[37;40m [34;40m░░[34;40m▄▄[34;40m▄▄[37;40m [34;40m▀[37;40m [96;46m░░[95;45m░[37;40m [34;40m░░[37;40m kernel: $KERNEL
 [34;40m▒▒[37;40m [96;46m▒░[96;46m░[37;40m [34;40m▒▒[34;40m▓▓[34;40m▓▓[37;40m [96;46m░░[96;46m░░[96;46m▒[37;40m [34;40m▒▒[34;40m public address:  $IP
 [34;40m▓▓[37;40m [96;46m▒▒[96;46m░[37;40m [34;40m▓▓[34;40m▀▀[34;40m▀▀[37;40m [34;40m▄[37;40m [96;46m▒▒[96;46m▓[37;40m [34;40m▓▓[90;40m uptime:  $UPTIME
 [34;40m██[37;40m [96;46m▓▒[96;46m▒[37;40m [34;40m██[37;40m [96;46m▓▓[96;46m▓[37;40m [34;40m▓[37;40m [96;40m██[96;40m▓[37;40m [34;40m██ packages: $PKGS  [95;40m+  [34;40m bins: $files
 [90;40m▄▄[37;40m [96;46m█▓[96;46m▓[37;40m [90;40m▄▄[37;40m [96;40m█[96;46m▓▓[37;40m [90;40m▄[37;40m [96;46m▓█[96;46m█[37;40m [90;40m▄▄ $CPU
 [36;40m▒▒[37;40m [96;46m██[96;46m▓[37;40m [36;40m▒▒[37;40m [96;40m██[96;46m▓[37;40m [90;40m▀[37;40m [96;46m██[96;46m█[37;40m [36;40m▒▒ $RAM
 [90;40m▀▀[37;40m [96;46m██[96;46m█[37;40m [90;40m▀▀[90;40m▄[37;40m [96;40m█[96;46m██[37;40m [96;46m██[96;46m█[37;40m [90;40m▄[90;40m▀▀ $DISK
 [37;40m [96;40m██[96;40m██[96;40m██[96;40m█[37;40m [37;40m  [37;40m [96;40m▀[96;46m██[96;46m█[96;40m▀[37;40m  [37;40m [37;40m  [37;40m

EOF
X0
chmod +x /etc/update-motd.d/00-banner
_ok "MOTD 已更新"

# ─── 删除默认用户 ───
if [[ "${REMOVE_ADMIN:-}" == "true" ]]; then
  _echo "removing default user"
  userdel -rf admin 2>/dev/null
  rm -f /etc/sudoers.d/90-cloud-init-users
  _ok "默认用户已移除"
fi
