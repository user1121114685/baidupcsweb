#!/bin/bash

red='\e[91m'
green='\e[92m'
yellow='\e[93m'
magenta='\e[95m'
cyan='\e[96m'
none='\e[0m'

# Root
[[ $(id -u) != 0 ]] && echo -e " 哎呀……请使用 ${red}root ${none}用户运行 ${yellow}~(^_^) ${none}" && exit 1

_version="v1.0.0"

cmd="apt-get"

sys_bit=$(uname -m)

if [[ $sys_bit == "i386" || $sys_bit == "i686" ]]; then
	BaiduPCS-Web_bit="86"
elif [[ $sys_bit == "x86_64" ]]; then
	BaiduPCS-Web_bit="amd64"
else
	echo -e " 哈哈……这个 ${red}辣鸡脚本${none} 不支持你的系统。 ${yellow}(-_-) ${none}" && exit 1
fi

# 笨笨的检测方法
if [[ -f /usr/bin/apt-get ]] || [[ -f /usr/bin/yum && -f /bin/systemctl ]]; then

	if [[ -f /usr/bin/yum ]]; then

		cmd="yum"

	fi
	if [[ -f /bin/systemctl ]]; then
		systemd=true
	fi

else

	echo -e " 哈哈……这个 ${red}辣鸡脚本${none} 不支持你的系统。 ${yellow}(-_-) ${none}" && exit 1

fi


BaiduPCS-Web_pid=$(ps ux | grep "/usr/bin/BaiduPCS-Web/BaiduPCS-Go" | grep -v grep | awk '{print $2}')
_BaiduPCS-Web_sh="/usr/local/sbin/BaiduPCS-Web"

if [[ ! -f $_BaiduPCS-Web_sh ]]; then
	mv -f /usr/local/bin/BaiduPCS-Web $_BaiduPCS-Web_sh
	chmod +x $_BaiduPCS-Web_sh
	echo -e "\n $yellow 警告: 请重新登录 SSH 以避免出现 BaiduPCS-Web 命令未找到的情况。$none  \n" && exit 1
fi

if [ $BaiduPCS-Web_pid ]; then
	BaiduPCS-Web_status="$green正在运行$none"
else
	BaiduPCS-Web_status="$red未在运行$none"
fi


start_BaiduPCS-Web() {
	if [[ $BaiduPCS-Web_pid ]]; then
		echo
		echo -e "${green} BaiduPCS-Web 正在运行...无需再启动$none"
		echo
	else

		# systemctl start BaiduPCS-Web
		service BaiduPCS-Web start >/dev/null 2>&1
		local is_BaiduPCS-Web_pid=$(ps ux | grep "/usr/bin/BaiduPCS-Web/BaiduPCS-Go" | grep -v grep | awk '{print $2}')
		if [[ $is_BaiduPCS-Web_pid ]]; then
			echo
			echo -e "${green} BaiduPCS-Web 已启动$none"
			echo
		else
			echo
			echo -e "${red} BaiduPCS-Web 启动失败！$none"
			echo
		fi

	fi
}
stop_BaiduPCS-Web() {
	if [[ $BaiduPCS-Web_pid ]]; then
		# systemctl stop BaiduPCS-Web
		service BaiduPCS-Web stop >/dev/null 2>&1
		echo
		echo -e "${green} BaiduPCS-Web 已停止$none"
		echo
	else
		echo
		echo -e "${red} BaiduPCS-Web 没有在运行$none"
		echo
	fi
}
restart_BaiduPCS-Web() {
	# systemctl restart BaiduPCS-Web
	service BaiduPCS-Web restart >/dev/null 2>&1
	local is_BaiduPCS-Web_pid=$(ps ux | grep "/usr/bin/BaiduPCS-Web/BaiduPCS-Go" | grep -v grep | awk '{print $2}')
	if [[ $is_BaiduPCS-Web_pid ]]; then
		echo
		echo -e "${green} BaiduPCS-Web 重启完成 $none"
		echo
	else
		echo
		echo -e "${red} BaiduPCS-Web 重启失败！$none"
		echo
	fi
}

update() {
	while :; do
		echo
		echo -e "$yellow 1. $none更新 BaiduPCS-Web 主程序"
		echo
		echo -e "$yellow 2. $none更新 BaiduPCS-Web 管理脚本"
		echo
		read -p "$(echo -e "请选择 [${magenta}1-2$none]:")" _opt
		if [[ -z $_opt ]]; then
			error
		else
			case $_opt in
			1)
				update_BaiduPCS-Web
				break
				;;
			2)
				update_BaiduPCS-Web.sh
				exit
				break
				;;
			*)
				error
				;;
			esac
		fi
	done
}

install_BaiduPCS-Web() {
	$cmd update -y
	# if [[ $cmd == "apt-get" ]]; then
	# 	$cmd install -y lrzsz git zip unzip curl wget qrencode dnsutils
	# else
	# 	$cmd install -y lrzsz git zip unzip curl wget qrencode bind-utils iptables-services
	# fi
	if [[ $cmd == "apt-get" ]]; then
		$cmd install -y git zip unzip curl wget
	else
		$cmd install -y  git zip unzip curl wget
	fi


		mkdir -p /etc/BaiduPCS-Web/shaoxia/BaiduPCS-Web
		git clone https://github.com/user1121114685/baidupcsweb.git /etc/BaiduPCS-Web/shaoxia/BaiduPCS-Web
## 这里还需修改

	if [[ ! -d /etc/BaiduPCS-Web/shaoxia/BaiduPCS-Web ]]; then
		echo
		echo -e "$red 哎呀呀...克隆脚本仓库出错了...$none"
		echo
		echo -e " 温馨提示..... 请尝试自行安装 Git: ${green}$cmd install -y git $none 之后再安装此脚本"
		echo
		exit 1
	fi

}

update_BaiduPCS-Web() {
	[ -d /tmp/BaiduPCS-Web ] && rm -rf /tmp/BaiduPCS-Web
	mkdir -p /tmp/BaiduPCS-Web

	BaiduPCS-Web_tmp_file="/tmp/BaiduPCS-Web/BaiduPCS-Go.zip"
	BaiduPCS-Web_latest_ver="$(curl -H 'Cache-Control: no-cache' -s "https://api.github.com/repos/liuzhuoling2011/baidupcs-web/releases/latest" | grep 'tag_name' | cut -d\" -f4)"

	if [[ ! $BaiduPCS-Web_latest_ver ]]; then
		echo
		echo -e " $red获取 BaiduPCS-Web 最新版本失败!!!$none"
		echo
		echo -e " 请检查网络配置！"
		echo
		echo " 然后再继续...."
		echo
		exit 1
	fi

	if [[ $BaiduPCS-Web_ver != $BaiduPCS-Web_latest_ver ]]; then
		echo
		echo -e " $green 咦...发现新版本耶....正在拼命更新.......$none"
		echo
		BaiduPCS-Web_download_link="http://qiniu.zoranjojo.top/BaiduPCS-Go-${BaiduPCS-Web_latest_ver}-linux-${BaiduPCS-Web_bit}.zip"

		if ! wget --no-check-certificate -O "$BaiduPCS-Web_tmp_file" $BaiduPCS-Web_download_link; then
			echo -e "
			$red 下载 BaiduPCS-Web 文件失败啦..可能是你的小鸡鸡的网络太辣鸡了...重新尝试更新也许能解决$none
			" && exit 1
		fi

		unzip $BaiduPCS-Web_tmp_file -d "/tmp/BaiduPCS-Web/"
		mkdir -p /usr/bin/BaiduPCS-Web
		cp -f "/tmp/BaiduPCS-Web/BaiduPCS-Go" "/usr/bin/BaiduPCS-Web/BaiduPCS-Go"
		chmod +x "/usr/bin/BaiduPCS-Web/BaiduPCS-Go"
		# systemctl restart BaiduPCS-Web
		# service BaiduPCS-Web restart >/dev/null 2>&1
		do_service restart BaiduPCS-Web
		echo
		echo -e " $green 更新成功啦...当前 BaiduPCS-Web 版本: ${cyan}$BaiduPCS-Web_latest_ver$none"
		echo
		echo
		rm -rf /tmp/BaiduPCS-Web
	else
		echo
		echo -e " $green 木有发现新版本....$none"
		echo
	fi
}
update_BaiduPCS-Web.sh() {
	local latest_version=$(curl -H 'Cache-Control: no-cache' -s -L "https://raw.githubusercontent.com/user1121114685/baidupcsweb/master/baidupcs.sh" | grep '_version' -m1 | cut -d\" -f2)

	if [[ ! $latest_version ]]; then
		echo
		echo -e " $red获取 BaiduPCS-Web 最新版本失败!!!$none"
		echo
		echo -e " 请检查网络配置！"
		echo
		echo " 然后再继续...."
		echo
		exit 1
	fi

	if [[ $latest_version == $_version ]]; then
		echo
		echo -e "$green 木有发现新版本 $none"
		echo
	else
		echo
		echo -e " $green 咦...发现新版本耶....正在拼命更新.......$none"
		echo
		cd /etc/BaiduPCS-Web/shaoxia/BaiduPCS-Web
		git pull
		cp -f /etc/BaiduPCS-Web/shaoxia/BaiduPCS-Web/baidupcs.sh $_BaiduPCS-Web_sh
		chmod +x $_BaiduPCS-Web_sh
		echo
		echo -e "$green 更新成功啦...当前 BaiduPCS-Web 管理脚本 版本: ${cyan}$latest_version$none"
		echo
	fi

}
## 这里的卸载也需修改
uninstall_BaiduPCS-Web() {
	while :; do
		echo
		read -p "$(echo -e "是否卸载 ${yellow}BaiduPCS-Web$none [${magenta}Y/N$none]:")" uninstall_BaiduPCS-Web_ask
		if [[ -z $uninstall_BaiduPCS-Web_ask ]]; then
			error
		else
			case $uninstall_BaiduPCS-Web_ask in
			Y | y)
				is_uninstall_BaiduPCS-Web=true
				echo
				echo -e "$yellow 卸载 BaiduPCS-Web = ${cyan}是${none}"
				echo
				break
				;;
			N | n)
				echo
				echo -e "$red 卸载已取消...$none"
				echo
				break
				;;
			*)
				error
				;;
			esac
		fi
	done


	if [[ $is_uninstall_BaiduPCS-Web]]; then
		pause
		echo
		# [ $BaiduPCS-Web_pid ] && systemctl stop BaiduPCS-Web
		[ $BaiduPCS-Web_pid ] && do_service stop BaiduPCS-Web

		rm -rf /usr/bin/BaiduPCS-Web
		rm -rf $_BaiduPCS-Web_sh

		if [[ $systemd ]]; then
			systemctl disable BaiduPCS-Web >/dev/null 2>&1
			rm -rf /lib/systemd/system/BaiduPCS-Web.service
		else
			update-rc.d -f BaiduPCS-Web remove >/dev/null 2>&1
			rm -rf /etc/init.d/BaiduPCS-Web
		fi
		# clear
		echo
		echo -e "$green BaiduPCS-Web 卸载完成啦 ....$none"
		echo
		echo "如果你觉得这个脚本有哪些地方不够好的话...请告诉我"
		echo
		echo "反馈问题: https://github.com/user1121114685/baidupcsweb/issues/new"
		echo

}
get_ip() {
	ip=$(curl -s https://ipinfo.io/ip)
}

error() {

	echo -e "\n$red 输入错误！$none\n"

}

pause() {

	read -rsp "$(echo -e "按$green Enter 回车键 $none继续....或按$red Ctrl + C $none取消.")" -d $'\n'
	echo
}
do_service() {
	if [[ $systemd ]]; then
		systemctl $1 $2
	else
		service $2 $1
	fi
}
## 帮助还需修改
_help() {
	echo
	echo "........... BaiduPCS-Web 管理脚本帮助信息 by BaiduPCS-Web66.com .........."
	echo -e "
	${green}BaiduPCS-Web menu $none管理 BaiduPCS-Web (同等于直接输入 BaiduPCS-Web)

	${green}BaiduPCS-Web info $none查看 BaiduPCS-Web 配置信息

	${green}BaiduPCS-Web config $none修改 BaiduPCS-Web 配置

	${green}BaiduPCS-Web status $none查看 BaiduPCS-Web 运行状态

	${green}BaiduPCS-Web start $none启动 BaiduPCS-Web

	${green}BaiduPCS-Web stop $none停止 BaiduPCS-Web

	${green}BaiduPCS-Web restart $none重启 BaiduPCS-Web

	${green}BaiduPCS-Web update $none更新 BaiduPCS-Web

	${green}BaiduPCS-Web update.sh $none更新 BaiduPCS-Web 管理脚本

	${green}BaiduPCS-Web uninstall $none卸载 BaiduPCS-Web
"
}
menu() {
	clear
	while :; do
		echo
		echo "........... BaiduPCS-Web 管理脚本 $_version by 联盟少侠 .........."
		echo
		echo -e "## BaiduPCS-Web 版本: $cyan$BaiduPCS-Web_ver$none  /  BaiduPCS-Web 状态: $BaiduPCS-Web_status ##"
		echo
		echo "反馈问题: https://github.com/user1121114685/baidupcsweb/issues/new"
		echo
		echo "捐赠脚本作者: 没有开通捐赠通道"
		echo
		echo
		echo -e "$yellow 1. $none查看 BaiduPCS-Web 配置"
		echo
		echo -e "$yellow 2. $none修改 BaiduPCS-Web 配置"
		echo
		echo -e "$yellow 3. $none启动 / 停止 / 重启 / 查看日志"
		echo
		echo -e "$yellow 4. $none更新 BaiduPCS-Web / 更新 BaiduPCS-Web 管理脚本"
		echo
		echo -e "$yellow 5. $none卸载 BaiduPCS-Web"
		echo	
		echo -e "温馨提示...如果你不想执行选项...按$yellow Ctrl + C $none即可退出"
		echo
		read -p "$(echo -e "请选择菜单 [${magenta}1-9$none]:")" choose
		if [[ -z $choose ]]; then
			exit 1
		else
			case $choose in
			1)
				view_BaiduPCS-Web_config_info
				break
				;;
			2)
				change_BaiduPCS-Web_config
				break
				;;
			3)
				BaiduPCS-Web_service
				break
				;;
			4)
				update
				break
				;;
			5)
				uninstall_BaiduPCS-Web
				break
				;;

			*)
				error
				;;
			esac
		fi
	done
}
args=$1
[ -z $1 ] && args="menu"
case $args in
menu)
	menu
	;;
i | info)
	view_BaiduPCS-Web_config_info
	;;
c | config)
	change_BaiduPCS-Web_config
	;;
status)
	echo
	if [[ $BaiduPCS-Web_transport == "4" && $caddy_installed ]]; then
		echo -e " BaiduPCS-Web 状态: $BaiduPCS-Web_status  /  Caddy 状态: $caddy_run_status"
	else
		echo -e " BaiduPCS-Web 状态: $BaiduPCS-Web_status"
	fi
	echo
	;;
start)
	start_BaiduPCS-Web
	;;
stop)
	stop_BaiduPCS-Web
	;;
restart)
	[[ $BaiduPCS-Web_transport == "4" && $caddy_installed ]] && do_service restart caddy
	restart_BaiduPCS-Web
	;;
u | update)
	update_BaiduPCS-Web
	;;
U | update.sh)
	update_BaiduPCS-Web.sh
	exit
	;;
un | uninstall)
	uninstall_BaiduPCS-Web
	;;
reinstall)
	uninstall_BaiduPCS-Web
	if [[ $is_uninstall_BaiduPCS-Web ]]; then
		cd
		cd - >/dev/null 2>&1
		bash <(curl -s -L https://233blog.com/BaiduPCS-Web.sh)
	fi
	;;
v | version)
	echo
	echo -e " 当前 BaiduPCS-Web 版本: ${green}$BaiduPCS-Web_ver$none  /  当前 BaiduPCS-Web 管理脚本版本: ${cyan}$_version$none"
	echo
	;;
help | *)
	_help
	;;
esac
