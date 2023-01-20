#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

sh_ver="1.0.8"
file="/root/BaiduPCSWeb"
Folder="/usr/local/BaiduPCSWeb"
BaiduPCS_Go="/usr/bin/BaiduPCS-Go"

red='\e[91m'
green='\e[92m'
yellow='\e[93m'
magenta='\e[95m'
cyan='\e[96m'
none='\e[0m'

BaiduPCS_port=$(cat ${Folder}/port)
#MMP这里的cat居然是这样的

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"

check_root(){
	[[ $EUID != 0 ]] && echo -ne "${Error} 当前非ROOT账号(或没有ROOT权限)，无法继续操作，请更换ROOT账号或使用 ${Green_background_prefix}sudo su${Font_color_suffix} 命令获取临时ROOT权限（执行后可能会提示输入当前账号的密码）。" && exit 1
}
#检查系统
check_sys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -qEi "debian"; then
		release="debian"
	elif cat /etc/issue | grep -qEi "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -qEi "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -qEi "debian"; then
		release="debian"
	elif cat /proc/version | grep -qEi "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -qEi "centos|red hat|redhat"; then
		release="centos"
    fi
	bit=`uname -m`
}
check_installed_status(){
	[[ ! -e ${Folder} ]] && echo -e "${Error} BaiduPCS-Web 没有安装，请检查 !" && exit 1
}
check_pid(){
	PID=$(ps -ef| grep "BaiduPCS-Go"| grep -v grep| grep -v "BDW.sh"| grep -v "init.d"| grep -v "service"| awk '{print $2}')
}

Set_BaiduPCS_port(){
	echo
	while :; do
		echo -e "请输入 "$yellow"BaiduPCS"$BaiduPCS" 端口 ["$magenta"1-65535"$none"]"
		echo -e "官方默认端口["$magenta"5299"$none"]"
		read -e -p "$(echo -e "(当前端口: ${cyan}${BaiduPCS_port}$none):")" BaiduPCS_port_opt
		case "$BaiduPCS_port_opt" in
		$BaiduPCS_port)
			echo
			echo " 哎呀...跟当前端口一毛一样呀...修改个鸡鸡哦"
			break
			;;
		[1-9] | [1-9][0-9] | [1-9][0-9][0-9] | [1-9][0-9][0-9][0-9] | [1-5][0-9][0-9][0-9][0-9] | 6[0-4][0-9][0-9][0-9] | 65[0-4][0-9][0-9] | 655[0-3][0-5])
			echo "$BaiduPCS_port_opt" > ${Folder}/port
			ReStart_BaiduPCS_Web
			##卧槽TM，一个break让我找半天，没有这个，根本跳转不出来！;;是摆设吗？MMP！
			break
			;;
		*)
			echo "输入错误请重新输入"
			;;
		esac

	done

}

check_new_ver(){
	echo -e "${Info} 请输入 BaiduPCS-Web 版本号，格式如：[ 3.5.9 ]，获取地址：[ https://github.com/qjfoidnh/BaiduPCS-Go/releases ]"
	read -e -p "默认回车自动获取最新版本号:" BaiduPCS_Web_new_ver
	if [[ -z ${BaiduPCS_Web_new_ver} ]]; then
		BaiduPCS_Web_new_ver="$(curl -H 'Cache-Control: no-cache' -s "https://api.github.com/repos/qjfoidnh/BaiduPCS-Go/releases/latest" | grep 'tag_name' | cut -d\" -f4)"
		if [[ -z ${BaiduPCS_Web_new_ver} ]]; then
			echo -e "${Error} BaiduPCS-Web 最新版本获取失败，请手动获取最新版本号[ https://github.com/qjfoidnh/BaiduPCS-Go/releases ]"
			read -e -p "请输入版本号 [ 格式如 3.5.9 ] :" BaiduPCS_Web_new_ver
			[[ -z "${BaiduPCS_Web_new_ver}" ]] && echo "取消..." && exit 1
		else
			echo -e "${Info} 检测到 BaiduPCS-Web 最新版本为 [ ${BaiduPCS_Web_new_ver} ]"
		fi
	else
		echo -e "${Info} 即将准备下载 BaiduPCS-Web 版本为 [ ${BaiduPCS_Web_new_ver} ]"
	fi
}
check_ver_comparison(){
	BaiduPCS_Web_now_ver=$(${Folder}/BaiduPCS-Go -v|head -n 1|awk '{print $3}')
	[[ -z ${BaiduPCS_Web_now_ver} ]] && echo -e "${Error} BaiduPCS_Web 当前版本获取失败 !" && exit 1
	if [[ "${BaiduPCS_Web_now_ver}" != "${BaiduPCS_Web_new_ver}" ]]; then
		echo -e "${Info} 发现 BaiduPCS-Web 已有新版本 [ ${BaiduPCS_Web_new_ver} ](当前版本：${BaiduPCS_Web_now_ver})"
		read -e -p "是否更新(会中断当前下载任务，请注意) ? [Y/n] :" yn
		[[ -z "${yn}" ]] && yn="y"
		if [[ $yn == [Yy] ]]; then
			check_pid
			[[ ! -z $PID ]] && kill -9 ${PID}
			Download_BaiduPCS_Web
		fi
	else
		echo -e "${Info} 当前 BaiduPCS-Web 已是最新版本 [ ${BaiduPCS_Web_new_ver} ]" && exit 1
	fi
}

check_ver_comparison_fix(){
	BaiduPCS_Web_now_ver=$(${Folder}/BaiduPCS-Go -v|head -n 1|awk '{print $3}')
	[[ -z ${BaiduPCS_Web_now_ver} ]] && echo -e "${Error} BaiduPCS_Web 当前版本获取失败 !" && exit 1
	if [[ "${BaiduPCS_Web_now_ver}" != "${BaiduPCS_Web_new_ver}" ]]; then
		echo -e "${Info} 发现 BaiduPCS-Web 已有新版本 [ ${BaiduPCS_Web_new_ver} ](当前版本：${BaiduPCS_Web_now_ver})"
		read -e -p "是否更新(会中断当前下载任务，请注意) ? [Y/n] :" yn
		[[ -z "${yn}" ]] && yn="y"
		if [[ $yn == [Yy] ]]; then
			check_pid
			[[ ! -z $PID ]] && kill -9 ${PID}
			Download_BaiduPCS_Web
		fi
	else
		echo -e "${Info} 正在重新下载最新版本 [ ${BaiduPCS_Web_new_ver} ]"
		check_pid
		[[ ! -z $PID ]] && kill -9 ${PID}
		Download_BaiduPCS_Web
	fi
}

Download_BaiduPCS_Web(){
	cd "/usr/local"
	#echo -e "${bit}"
	bit=`uname -m`
	if [[ ${bit} == "x86_64" ]]; then
		bit="amd64"
	elif [[ ${bit} == "i386" || ${bit} == "i686" ]]; then
		bit="86"
	else
		bit="arm64"
	fi
	wget -N --no-check-certificate "https://github.com/qjfoidnh/BaiduPCS-Go/releases/download/${BaiduPCS_Web_new_ver}/BaiduPCS-Go-${BaiduPCS_Web_new_ver}-linux-${bit}.zip"
	BaiduPCS_Web_Name="BaiduPCS-Go-${BaiduPCS_Web_new_ver}-linux-${bit}"
	[[ ! -s ${BaiduPCS_Web_Name}.zip ]] && echo -e "${Error} BaiduPCS-Web 压缩包下载失败 !" && exit 1
	unzip ${BaiduPCS_Web_Name}.zip
	[[ ! -e "/usr/local/${BaiduPCS_Web_Name}" ]] && echo -e "${Error} BaiduPCS-Web 解压失败 !" && rm -rf ${BaiduPCS_Web_Name}.zip && exit 1
	rm -rf "${Folder}/BaiduPCS-Go"
	cp -f "/usr/local/${BaiduPCS_Web_Name}/BaiduPCS-Go" "${Folder}/BaiduPCS-Go"
	if [[ ! -e "${Folder}" ]]; then 
		echo -e "${Error} ${Folder}/BaiduPCS-Go 复制失败 !首次安装请忽略此信息！" 
		mv "/usr/local/${BaiduPCS_Web_Name}" "${Folder}"	
	fi
	[[ ! -e "${Folder}" ]] && echo -e "${Error} BaiduPCS-Web 文件夹重命名失败 !" && rm -rf "/usr/local/${BaiduPCS_Web_Name}.zip" && rm -rf "/usr/local/${BaiduPCS_Web_Name}" && exit 1
	rm -rf "/usr/local/${BaiduPCS_Web_Name}.zip"
	rm -rf "/usr/local/${BaiduPCS_Web_Name}"
	cd "${Folder}"
	chmod a+x BaiduPCS-Go
	echo -e "${Info} BaiduPCS-Web 主程序安装完毕！..."
}

## 以后再修改
Service_BaiduPCS_Web(){
	if [[ ${release} = "centos" ]]; then
		if ! wget --no-check-certificate https://raw.githubusercontent.com/Wonderful-GW/baidupcsweb/master/BaiduPCSWeb_centos -O /etc/init.d/BaiduPCSWeb; then
			echo -e "${Error} BaiduPCS-Web服务 管理脚本下载失败 !" && exit 1
		fi
		Download_BaiduPCS_port
		chmod +x /etc/init.d/BaiduPCSWeb
		chkconfig --add BaiduPCSWeb
		chkconfig BaiduPCSWeb on
	else
		if ! wget --no-check-certificate https://raw.githubusercontent.com/Wonderful-GW/baidupcsweb/master/BaiduPCSWeb_debian -O /etc/init.d/BaiduPCSWeb; then
			echo -e "${Error} BaiduPCS-Web服务 管理脚本下载失败 !" && exit 1
		fi
		Download_BaiduPCS_port
		chmod +x /etc/init.d/BaiduPCSWeb
		update-rc.d -f BaiduPCSWeb defaults
	fi
	echo -e "${Info} BaiduPCS-Web服务 管理脚本下载完成 !"
}

Download_BaiduPCS_port(){
	if ! wget --no-check-certificate https://raw.githubusercontent.com/Wonderful-GW/baidupcsweb/master/port -O "${Folder}/port"; then
		echo -e "${Error} BaiduPCS-Web服务 prot下载失败 !" && exit 1
	fi
	echo -e "成功下载port文件..."
	chmod 777 ${Folder}/port
 }

Installation_dependency(){
 	if [[ ${release} = "centos" ]]; then
		yum update
 		yum install -y  git zip unzip curl wget
 	else
		apt-get update
		apt-get install -y git zip unzip curl wget
 	fi
 }
Install_BaiduPCS_Web(){
	check_root
	check_pid
	[[ ! -z $PID ]] && kill -9 ${PID}
	rm -rf "${BaiduPCS_Go}"
	rm -rf "${Folder}"
	rm -rf "${file}"
	rm -rf "${Folder}/port"
	[[ -e ${BaiduPCS_Go} ]] && echo -e "${Error} BaiduPCS-Web 已安装，请检查 !" && exit 1
	check_sys
	echo -e "${Info} 开始安装/配置 依赖..."
	Installation_dependency
	echo -e "${Info} 开始下载/安装 主程序..."
	check_new_ver
	Download_BaiduPCS_Web
	echo -e "${Info} 开始下载/安装 服务脚本(init)..."
	Service_BaiduPCS_Web
	echo -e "${Info} 设置端口..."
	Set_BaiduPCS_port
	echo -e "${Info} 所有步骤 安装完毕，开始启动..."
	Start_BaiduPCS_Web
}
Start_BaiduPCS_Web(){
	check_installed_status
	check_pid
	[[ ! -z ${PID} ]] && echo -e "${Error} BaiduPCS-Web 正在运行，请检查 !" && exit 1
	/etc/init.d/BaiduPCSWeb start
}
Stop_BaiduPCS_Web(){
	check_installed_status
	check_pid
	[[ -z ${PID} ]] && echo -e "${Error} BaiduPCS-Web 没有运行，请检查 !" && exit 1
	/etc/init.d/BaiduPCSWeb stop
}
ReStart_BaiduPCS_Web(){
	check_installed_status
	check_pid
	[[ ! -z ${PID} ]] && /etc/init.d/BaiduPCSWeb stop
	/etc/init.d/BaiduPCSWeb start
}

Update_BaiduPCS_Web(){
	check_installed_status
	check_new_ver
	check_ver_comparison
	Start_BaiduPCS_Web
}

Fix_BaiduPCS_Web(){
	check_installed_status
	check_new_ver
	check_ver_comparison_fix
}

UnInstall_BaiduPCS_Web(){
	check_installed_status "un"
	echo "确定要卸载 BaiduPCS-Web ? (y/N)"
	echo
	read -e -p "(默认: n):" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		check_pid
		[[ ! -z $PID ]] && kill -9 ${PID}
		rm -rf "${BaiduPCS_Go}"
		rm -rf "${Folder}"
		rm -rf "${file}"
		rm -rf "${Folder}/port"
		if [[ ${release} = "centos" ]]; then
			chkconfig --del BaiduPCSWeb
		else
			update-rc.d -f BaiduPCSWeb remove
		fi
		rm -rf "/etc/init.d/BaiduPCSWeb"
		echo && echo "BaiduPCS-Web 卸载完成 !" && echo
	else
		echo && echo "卸载已取消..." && echo
	fi
}


Update_Shell(){
	local latest_version=$(curl -H 'Cache-Control: no-cache' -s -L "https://raw.githubusercontent.com/Wonderful-GW/baidupcsweb/master/BDW.sh" | grep 'sh_ver' -m1 | cut -d\" -f2)
	if [[ ! $latest_version ]]; then
		echo
		echo -e " $red获取 BaiduPCS_Web 最新版本失败!!!$none"
		echo
		echo -e " 请检查网络配置！"
		echo
		echo " 然后再继续...."
		echo
		exit 1
	fi

	if [[ $latest_version == $sh_ver ]]; then
		echo
		echo -e "$green 木有发现新版本 $none"
		echo
	else
		echo
		echo -e " $green 咦...发现新版本耶....正在拼命更新.......$none"
		echo
		wget -N --no-check-certificate "https://raw.githubusercontent.com/Wonderful-GW/baidupcsweb/master/BDW.sh" && chmod +x BDW.sh
		echo -e "脚本已更新为最新版本[ ${sh_new_ver} ] !(注意：因为更新方式为直接覆盖当前运行的脚本，所以可能下面会提示一些报错，无视即可)" && exit 0
	fi
}

Set_BaiduPCS_Advanced(){
	echo && echo -e " 你要做什么？
	
 ${Green_font_prefix} 0.${Font_color_suffix} 尝试修复（不用重装）
————————
 ${Green_font_prefix} 1.${Font_color_suffix} 显示已登录的账户
 ${Green_font_prefix} 2.${Font_color_suffix} 占位（暂时不知道做什么）
————————
 ${Green_font_prefix} 3.${Font_color_suffix} 清空所有账号信息（包括密码与登陆的账号）
 
 注意：部分操作会自动重启客户端！" && echo
	read -e -p "(默认: 取消):" set_num
	[[ -z "${set_num}" ]] && echo "已取消..." && exit 1
	if [[ ${set_num} == "0" ]]; then
	echo -e "$yellow 开始修复，请保证你目前使用的是最新脚本。$none"
	echo -e ""
	Fix_BaiduPCS_Web
	Service_BaiduPCS_Web
	ReStart_BaiduPCS_Web

	elif [[ ${set_num} == "1" ]]; then
	echo -e "$yellow您已登录以下账户"
	echo -e ""
	cat "${Folder}/pcs_config.json" | grep name | cut -d\" -f4
	echo -e "$yellow $none"

	elif [[ ${set_num} == "3" ]]; then
	rm -rf "${Folder}/pcs_config.json"
	echo -e "$yellow 配置文件已经删除，请重新登录账号！$none"
	ReStart_BaiduPCS_Web
	else
		echo -e "${Error} 请输入正确的数字[1-3]" && exit 1
	fi
}


echo && echo -e " BaiduPCS-Web 一键安装管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}

		by 联盟少侠 

>>>>>>管理地址:http://你的IP:${BaiduPCS_port}(支持外网访问)<<<<<<<

>>>>>>如果不能访问，请自行进行端口放行，或者端口映射<<<<<<<<<

BaiduPCS-Web项目地址：https://github.com/liuzhuoling2011/baidupcs-web

本脚本的项目地址：https://github.com/user1121114685/baidupcsweb


  
 ${Green_font_prefix} 0.${Font_color_suffix} 升级脚本
————————————————————————
 ${Green_font_prefix} 1.${Font_color_suffix} 安装 BaiduPCS-Web
 ${Green_font_prefix} 2.${Font_color_suffix} 更新 BaiduPCS-Web(可指定版本)
 ${Green_font_prefix} 3.${Font_color_suffix} 卸载 BaiduPCS-Web
————————————————————————
 ${Green_font_prefix} 4.${Font_color_suffix} 启动 BaiduPCS-Web
 ${Green_font_prefix} 5.${Font_color_suffix} 停止 BaiduPCS-Web
 ${Green_font_prefix} 6.${Font_color_suffix} 重启 BaiduPCS-Web
————————————————————————
 ${Green_font_prefix} 7.${Font_color_suffix} 修改 BaiduPCS-Web 端口
 ${Green_font_prefix} 8.${Font_color_suffix} 高级功能
————————————————————————" && echo
if [[ -e ${Folder} ]]; then
	check_pid
	if [[ ! -z "${PID}" ]]; then
		echo -e " 当前状态: ${Green_font_prefix}已安装${Font_color_suffix} 并 ${Green_font_prefix}已启动${Font_color_suffix}"
	else
		echo -e " 当前状态: ${Green_font_prefix}已安装${Font_color_suffix} 但 ${Red_font_prefix}未启动${Font_color_suffix}"
	fi
else
	echo -e " 当前状态: ${Red_font_prefix}未安装${Font_color_suffix}"
fi
echo
read -e -p " 请输入数字 [0-8]:" num
case "$num" in
	0)
	Update_Shell
	;;
	1)
	Install_BaiduPCS_Web
	;;
	2)
	Update_BaiduPCS_Web
	;;
	3)
	UnInstall_BaiduPCS_Web
	;;
	4)
	Start_BaiduPCS_Web
	;;
	5)
	Stop_BaiduPCS_Web
	;;
	6)
	ReStart_BaiduPCS_Web
	;;
	7)
	Set_BaiduPCS_port
	;;
	8)
	Set_BaiduPCS_Advanced
	;;
	*)
	echo "请输入正确数字 [0-8]"
	;;
esac
