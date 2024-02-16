#!/bin/bash


# запуск sudo sh ./mos_postinstall.sh



# Проверка sudo
if [ "$EUID" -ne 0 ]; then
    echo -e "\nДавай то же самое, только через sudo\n\n"
    exit 1
fi

# Проверка подключения к интернету
wget -q --tries=10 --timeout=20 --spider http://yandex.ru
if [ $? -ne 0 ]; then
    echo -e "\nА интернет-то будет? Без него никак :(\n\n"
	exit 1
fi

pruduct_name=`dmidecode -s system-product-name`
echo -e "Модель компьютера -\033[91m" $pruduct_name "\033[0m\n"


# Переименовывание компа
pc_name=`hostname`
echo -ne "Имя компа [\033[91m"$pc_name"\033[0m] :"
read new_pc_name
if [[ $new_pc_name != '' ]]; then
    hostnamectl set-hostname $new_pc_name
    systemctl restart systemd-hostnamed
fi

# Добавление репозитория AnyDesk
cat > /etc/yum.repos.d/AnyDesk.repo << "EOF"
[anydesk]
name=AnyDesk
baseurl=http://rpm.anydesk.com/centos/$basearch/
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://keys.anydesk.com/repos/RPM-GPG-KEY
EOF

# Добавление репозитория AnyDesk
cat > /etc/yum.repos.d/AlterOffice.repo << "EOF"
[alteroffice]
name=AlterOffice Packages  - $basearch
baseurl=http://repo.alter-os.ru/alteroffice/$basearch
failovermethod=priority
enabled=1
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlterOffice
EOF


# Удаление LibreOffice
dnf remove -y libreoffice-*

# Установка софта из репозиториев
dnf install -y \
	obs-studio \
	codeblocks \
	yandex-browser \
	vk-messenger \
	anydesk \
	alteroffice \
	arduino-ide \
	git \
	make
	
# костыль с chromium
dnf -y reinstall chromium-browser

# Первичное обновление системы
dnf update -y

mkdir /tmp/cpm
cd /tmp/cpm

# Установка драйверов под конкретную модель компа
case $pruduct_name in
	"HP ProBook 455 G1")
		echo -e "Здесь надо поставить драйвер для bluetooth"
		echo -e "https://github.com/loimu/rtbth-dkms"
		;;
	"OptiPlex 7450 AIO")
		;;
	"10BBS0L100")  # Моноблок Lenovo
		echo - e "https://linux-hardware.org/?probe=fa37beed12"
	;;
	*)
	echo -e "Ниче не надо"
	;;
esac

# установка MeshAgent
wget "https://mesh.mccme.ru/meshagents?script=1" -O ./meshinstall.sh
sh ./meshinstall.sh https://mesh.mccme.ru '9bxKhSh@dmgtITh2PCYGqk0MYa0XYhawFe2bi5ppRJvezpbu9p62NPetRs7hvFhc'
mkdir /opt/meshagent
cp ./{meshagent,meshagent.msh} /opt/meshagent
chmod +x /opt/meshagent/meshagent

cat > /lib/systemd/system/meshagent.service << "EOF"
[Unit]
    Description=MeshAgent
    
[Service]
    ExecStart=/opt/meshagent/meshagent
    Type=idle
    KillMode=process

    SyslogIdentifier=meshagent
    SyslogFacility=daemon

    Restart=on-failure

[Install]
    WantedBy=multi-user.target
EOF

systemctl enable meshagent
systemctl start meshagent

dnf -y autoremove
dnf -y clean all

rm -R /tmp/cpm

exit 0




#
