#!/bin/bash


# запуск sudo sh ./mos_postinstall.sh



# Проверка sudo
if [ "$EUID" -ne 0 ]; then
    echo -e "Теперь то же самое, только от \033[91mroot\033[0m\n\n"
    exit 1
fi

# Проверка подключения к интернету
wget -q --tries=10 --timeout=20 --spider http://ya.ru
if [ $? -ne 0 ]; then
    echo -e "А интернет-то будет? Без него никак :(\n\n"
	exit 1
fi

tmp_dir=/tmp/cpm
pruduct_name=`dmidecode -s system-product-name`
pc_name=`hostname`

# Переход во временныю папку
mkdir $tmp_dir && cd $_

echo -e "Модель компьютера -\033[91m" $pruduct_name "\033[0m\n"

# Переименовывание компа
echo -ne "Имя компа [\033[91m"$pc_name"\033[0m] :"
read new_pc_name
if [ -n "$new_pc_name" ]; then
    hostnamectl set-hostname $new_pc_name
    systemctl restart systemd-hostnamed
fi

echo -e "Этот компьютер для робототехники и программирования? [yes/No]:"
read robots


# Установка драйверов под конкретную модель компа
echo -e "Определение спецдров"
case $pruduct_name in
	"HP ProBook 455 G1")
		echo -e "Здесь надо поставить драйвер для bluetooth"
		echo -e "https://github.com/loimu/rtbth-dkms"
	;;
	"OptiPlex 7450 AIO")
		echo -e "Ниче не надо"
	;;
	"10BBS0L100")  # Моноблок Lenovo
		echo -e "Ниче не надо"
	;;
	"Latitude 3380")
		echo -e "Ниче не надо"
	;;
	*)
	echo -e "Ниче не надо"
	;;
esac

# Добавление репозитория AnyDesk
cat > /etc/yum.repos.d/AnyDesk.repo << "EOF"
[anydesk]
name=AnyDesk
baseurl=http://rpm.anydesk.com/centos/$basearch/
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://keys.anydesk.com/repos/RPM-GPG-KEY
EOF

# Добавление репозитория AlterOffice
cat > /etc/yum.repos.d/AlterOffice.repo << "EOF"
[AlterOffice]
name=AlterOffice Packages  - $basearch
baseurl=http://repo.alter-os.ru/alteroffice/$basearch
failovermethod=priority
enabled=1
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlterOffice
EOF

# Удаление LibreOffice
dnf remove -y libreoffice-*

# костыль с chromium
dnf -y reinstall chromium-browser

# Установка софта из репозиториев
# базовый комплект
dnf install -y \
	obs-studio \
	yandex-browser \
	vk-messenger \
#	anydesk \
	alteroffice

wget https://мойассистент.рф/%D1%81%D0%BA%D0%B0%D1%87%D0%B0%D1%82%D1%8C/Download/946

dnf install ./assistant*.rpm -y


#if [ $robots == grep -i -E "(y|yes)" ]; then
#
#fi


# Комплект для робототехники и программирования
# надо спрятать в диалог
dnf install -y \
	codeblocks \
	arduino-ide \
	vscode \
	git \
	make \
	fpc \
	lazarus \
	freebasic \
	basic256 \
	wing-{personal,101}

# Первичное обновление системы
dnf update -y

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

systemctl enable --now meshagent

dnf -y autoremove
cd /; rm -R $tmp_dir

exit 0

