#!/bin/bash
############################################
# File Name: start.sh
# Version: v1.0
# Author: chuest
# Organization: NULL
# Github: https://github.com/chuest/RomTools
############################################

N='\033[0m'
R='\033[1;31m'
G='\033[1;32m'
B='\033[1;34m'

function main(){
	romName=${1}
	rootPath=`pwd`
	mkdir out
	echo -e "$(date "+%m/%d %H:%M:%S") [${G}NOTICE${N}] 正在解压刷机包"
	unzip -o $romName -d out
	rm -rf $romName
	cd out
	mkdir images
	rm -rf META-INF apex_info.pb care_map.pb payload_properties.txt
	echo -e "$(date "+%m/%d %H:%M:%S") [${G}NOTICE${N}] 正在解压 payload.bin"
	${rootPath}/bin/payload-dumper-go -o ${rootPath}/out/images payload.bin > /dev/null 2>&1
	rm -rf payload.bin
	unpackimg system
	unpackimg vendor
	unpackimg product
	vbmeta
	boot
	modify
	repackimg system
	repackimg vendor
	repackimg product
	mv images/system_ext.img system_ext.img
	mv images/odm.img odm.img
	super
	sudo rm -rf _pycache_ system vendor product system.img vendor.img product.img system_ext.img odm.img
	cp -rf ${rootPath}/files/META-INF ${rootPath}/out/META-INF
	sudo zip -q -r rom.zip images META-INF
}

function unpackimg(){
	### 解包
	mv images/${1}.img ${1}.img
	echo -e "$(date "+%m/%d %H:%M:%S") [${G}NOTICE${N}] 正在解压 ${1}.img"
	sudo python3 ${rootPath}/bin/imgextractor.py ${1}.img ${1}
	rm -rf ${1}.img
}

function repackimg(){
	### 打包 ext4
	name=${1}
	mount_path="/$name"
	fileContexts="${rootPath}/out/${name}/config/${name}_file_contexts"
	fsConfig="${rootPath}/out/${name}/config/${name}_fs_config"
	imgSize=`echo "$(sudo du -sb ${rootPath}/out/${name} | awk {'print $1'}) + 104857600" | bc`
	outImg="${rootPath}/out/${name}.img"
	inFiles="${rootPath}/out/${name}/${name}"
	echo -e "$(date "+%m/%d %H:%M:%S") [${G}NOTICE${N}] 正在打包 ${1}.img"
	sudo ${rootPath}/bin/make_ext4fs -J -T 1640966400 -S $fileContexts -l $imgSize -C $fsConfig -L $name -a $name $outImg $inFiles
}

function super(){
	### 打包 super
	sudo ${rootPath}/bin/lpmake --metadata-size 65536 --super-name super --device super:9126805504 --group main_a:9126805504 --group main_b:9126805504 --metadata-slots 3 --virtual-ab --partition system_a:readonly:$(echo $(stat -c "%s" system.img) | bc):main_a --image system_a=system.img --partition system_b:readonly:0:main_b --partition vendor_a:readonly:$(echo $(stat -c "%s" vendor.img) | bc):main_a --image vendor_a=vendor.img --partition vendor_b:readonly:0:main_b --partition product_a:readonly:$(echo $(stat -c "%s" product.img) | bc):main_a --image product_a=product.img --partition product_b:readonly:0:main_b --partition system_ext_a:readonly:$(echo $(stat -c "%s" system_ext.img) | bc):main_a --image system_ext_a=system_ext.img --partition system_ext_b:readonly:0:main_b --partition odm_a:readonly:$(echo $(stat -c "%s" odm.img) | bc):main_a --image odm_a=odm.img --partition odm_b:readonly:0:main_b --sparse --output images/super.img
}

function boot(){
	# 去除 AVB 验证
	mv images/boot.img boot.img
	mv images/vendor_boot.img vendor_boot.img
	echo -e "$(date "+%m/%d %H:%M:%S") [${G}NOTICE${N}] 正在使用 magisk 修补 boot"
	sudo ${rootPath}/bin/magiskboot unpack boot.img >/dev/null 2>&1
	sudo ${rootPath}/bin/magiskboot cpio ramdisk.cpio patch
	for dt in dtb kernel_dtb extra; do
		[ -f $dt ] && sudo ${rootPath}/bin/magiskboot dtb $dt patch
	done
	sudo ${rootPath}/bin/magiskboot repack boot.img >/dev/null 2>&1
	sudo rm -rf *kernel* *dtb* ramdisk.cpio*
	[ -f new-boot.img ] && cp -rf new-boot.img ${rootPath}/out/images/boot.img
	sudo rm -rf new-boot.img

	echo -e "$(date "+%m/%d %H:%M:%S") [${G}NOTICE${N}] 正在使用 magisk 修补 vendor_boot"
	sudo ${rootPath}/bin/magiskboot unpack vendor_boot.img >/dev/null 2>&1
	sudo ${rootPath}/bin/magiskboot cpio ramdisk.cpio patch
	for dt in dtb kernel_dtb extra; do
        [ -f $dt ] && sudo ${rootPath}/bin/magiskboot dtb $dt patch
	done
	sudo ${rootPath}/bin/magiskboot repack vendor_boot.img >/dev/null 2>&1
	sudo rm -rf *kernel* *dtb* ramdisk.cpio*
	[ -f new-boot.img ] && cp -rf new-boot.img ${rootPath}/out/images/vendor_boot.img
	sudo rm -rf new-boot.img

	# buil twrp recovery for vab devices
	#${rootPath}/bin/magiskboot unpack boot.img >/dev/null 2>&1
	#echo "正在刷入TWRP"
	#cp -rf ${rootPath}/files/ramdisk.cpio ramdisk.cpio
	#${rootPath}/bin/magiskboot repack boot.img >/dev/null 2>&1
	#mv new-boot.img boot.img
	#bash bin/Universal/Magisk/boot_patch.sh boot.img
	#rm boot.img
	#cp -rf new-boot.img tmp/boot_twrp.img
	#rm -rf *kernel* *dtb* ramdisk.cpio* new-boot.img

}

function vbmeta(){
	# 替换 vbmeta 镜像
	echo -e "$(date "+%m/%d %H:%M:%S") [${G}NOTICE${N}] 正在去除 vbmeta 验证"
	cp -rf ${rootPath}/files/images/vbmeta.img ${rootPath}/out/images/vbmeta.img
	cp -rf ${rootPath}/files/images/vbmeta_system.img ${rootPath}/out/images/vbmeta_system.img

	# sed -i 's/\x00\x00\x00\x00\x00\x61\x76\x62\x74\x6F\x6F\x6C\x20\x31\x2E\x31\x2E\x30/\x02\x00\x00\x00\x00\x61\x76\x62\x74\x6F\x6F\x6C\x20\x31\x2E\x31\x2E\x30/g' files/vbmeta.img

}

function modify(){

	##### system
	### Modify config
	sudo sed -i '0,/[a-z]\+\/lost\\+found/{/[a-z]\+\/lost\\+found/d}' system/config/system_file_contexts
	sudo sh -c "cat ${rootPath}/files/config/systemContextsAdd >> system/config/system_file_contexts"
	sudo sh -c "cat ${rootPath}/files/config/systemConfigAdd >> system/config/system_fs_config"

	### Repalce files
	# Analytics
	sudo cp -rf ${rootPath}/files/app/AnalyticsCore.apk system/system/system/app/AnalyticsCore/AnalyticsCore.apk

	# 系统更新
	sudo mv system/system/system/app/Updater/Updater.apk system/system/system/app/Updater/Updater.apk.bak

	### Add files
	# theme
	sudo cp -rf ${rootPath}/files/config/com.android.settings system/system/system/media/theme/default/com.android.settings
	sudo cp -rf ${rootPath}/files/config/com.android.systemui system/system/system/media/theme/default/com.android.systemui
	# 酷安
	sudo mkdir system/system/system/data-app/CoolApk
	sudo cp ${rootPath}/files/app/CoolApk.apk system/system/system/data-app/CoolApk/CoolApk.apk
	# via浏览器
	sudo mkdir system/system/system/data-app/via
	sudo cp ${rootPath}/files/app/via.apk system/system/system/data-app/via/via.apk
	# Magisk
	# sudo mkdir system/system/system/data-app/Magisk
	# sudo cp ${rootPath}/files/app/Magisk.apk system/system/system/data-app/Magisk/Magisk.apk

	### Remove files
	for file in $(cat ${rootPath}/files/config/removeFiles) ; do
		if [ -f "${file}" ] || [ -d "${file}" ] ;then
			echo -e "$(date "+%m/%d %H:%M:%S") [${G}NOTICE${N}] Delete ${file}"
			sudo rm -rf "${file}"
		fi
	done


	##### vendor

	sudo sed -i '0,/[a-z]\+\/lost\\+found/{/[a-z]\+\/lost\\+found/d}' vendor/config/vendor_file_contexts

	# 去除 AVB
	# 顺序很重要
	sudo sed -i 's/,avb_keys=\/avb\/q-gsi.avbpubkey:\/avb\/r-gsi.avbpubkey:\/avb\/s-gsi.avbpubkey//g' vendor/vendor/etc/fstab.qcom
	sudo sed -i 's/,avb=vbmeta_system//g' vendor/vendor/etc/fstab.qcom
	sudo sed -i 's/,avb//g' vendor/vendor/etc/fstab.qcom

	##### product

	sudo sed -i '0,/[a-z]\+\/lost\\+found/{/[a-z]\+\/lost\\+found/d}' product/config/product_file_contexts

	# DC调光
	sudo sed -i 's/<bool name=\"support_dc_backlight\">false<\/bool>/<bool name=\"support_dc_backlight\">true<\/bool>/g' product/product/etc/device_features/*xml
	sudo sed -i 's/<bool name=\"support_secret_dc_backlight\">true<\/bool>/<bool name=\"support_secret_dc_backlight\">false<\/bool>/g' product/product/etc/device_features/*xml

	# 智能护眼
	# sudo sed -i '/<\/features>/i\    <bool name=\"support_smart_eyecare\">true<\/bool>' product/product/etc/device_features/*xml

	# HiFi
	# sudo sed -i 's/<bool name=\"support_hifi\">false<\/bool>/<bool name=\"support_hifi\">true<\/bool>/g' product/product/etc/device_features/*xml

	# 杜比
	# sudo sed -i 's/<bool name=\"support_dolby\">false<\/bool>/<bool name=\"support_dolby\">true<\/bool>/g' product/product/etc/device_features/*xml

	# Ai键
	#sudo sed -i 's/<bool name=\"support_ai_task\">false<\/bool>/<bool name=\"support_ai_task\">true<\/bool>/g' product/product/etc/device_features/*xml

	# 呼吸灯
	# sudo sed -i 's/<bool name=\"support_led_color\">false<\/bool>/<bool name=\"support_led_color\">true<\/bool>/g' product/product/etc/device_features/*xml
	# sudo sed -i 's/<bool name=\"support_led_light\">false<\/bool>/<bool name=\"support_led_light\">true<\/bool>/g' product/product/etc/device_features/*xml

	# 游戏英雄死亡倒计时
	#sudo sed -i '/<\/features>/i\    <bool name=\"support_mi_game_countdown\">true<\/bool>' product/product/etc/device_features/*xml

}

main ${1}
