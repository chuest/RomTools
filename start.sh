#!/bin/bash

function main(){
	romName=${1}
	rootPath=`pwd`
	mkdir out
	echo "正在解压刷机包"
	unzip -o $romName -d out
	rm -rf $romName
	cd out
	rm -rf META-INF apex_info.pb care_map.pb payload_properties.txt
	echo "正在解压payload.bin"
	${rootPath}/bin/payload-dumper-go -o ${rootPath}/out payload.bin > /dev/null
	rm -rf payload.bin
	unpackimg system
	unpackimg vendor
	unpackimg product
	modify
	repackimg system
	repackimg vendor
	repackimg product
	super
	sudo rm -rf _pycache_ system vendor product system.img vendor.img product.img system_ext.img odm.img
	sudo zip -q -r rom.zip *.img
	sudo rm -rf *.img
}

function unpackimg(){
	echo "正在解压${1}.img"
	sudo python3 ${rootPath}/bin/imgextractor.py ${1}.img ${1}
	rm -rf ${1}.img
}

function repackimg(){
	name=${1}
	mount_path="/$name"
	fileContexts="${rootPath}/out/${name}/config/${name}_file_contexts"
	fsConfig="${rootPath}/out/${name}/config/${name}_fs_config"
	imgSize=`echo "$(sudo du -sb ${rootPath}/out/${name} | awk {'print $1'}) + 104857600" | bc`
	outImg="${rootPath}/out/${name}.img"
	inFiles="${rootPath}/out/${name}/${name}"
	echo "正在打包${1}.img"
	sudo ${rootPath}/bin/make_ext4fs -J -T 1640966400 -S $fileContexts -l $imgSize -C $fsConfig -L $name -a $name $outImg $inFiles
}

function super(){
	${rootPath}/bin/lpmake --metadata-size 65536 --super-name super --device super:9126805504 --group main_a:9126805504 --group main_b:9126805504 --metadata-slots 3 --virtual-ab --partition system_a:readonly:$(echo $(stat -c "%s" system.img) | bc):main_a --image system_a=system.img --partition system_b:readonly:0:main_b --partition vendor_a:readonly:$(echo $(stat -c "%s" vendor.img) | bc):main_a --image vendor_a=vendor.img --partition vendor_b:readonly:0:main_b --partition product_a:readonly:$(echo $(stat -c "%s" product.img) | bc):main_a --image product_a=product.img --partition product_b:readonly:0:main_b --partition system_ext_a:readonly:$(echo $(stat -c "%s" system_ext.img) | bc):main_a --image system_ext_a=system_ext.img --partition system_ext_b:readonly:0:main_b --partition odm_a:readonly:$(echo $(stat -c "%s" odm.img) | bc):main_a --image odm_a=odm.img --partition odm_b:readonly:0:main_b --sparse --output super.img
}

function modify(){
	# replace vbmeta images
	echo "正在去除vbmeta验证"
	cp -rf ${rootPath}/files/vbmeta.img ${rootPath}/out/vbmeta.img
	cp -rf ${rootPath}/files/vbmeta_system.img ${rootPath}/out/vbmeta_system.img
	# [ -f "$targetVbmetaVendorImage" ] && cp -rf files/vbmeta_vendor.img out/vbmeta_vendor.img

	# sed -i 's/\x00\x00\x00\x00\x00\x61\x76\x62\x74\x6F\x6F\x6C\x20\x31\x2E\x31\x2E\x30/\x02\x00\x00\x00\x00\x61\x76\x62\x74\x6F\x6F\x6C\x20\x31\x2E\x31\x2E\x30/g' files/vbmeta.img

	# remove avb parttn
	echo "正在使用magisk修补boot"
	sudo ${rootPath}/bin/magiskboot unpack boot.img >/dev/null 2>&1
	sudo ${rootPath}/bin/magiskboot cpio ramdisk.cpio patch
	for dt in dtb kernel_dtb extra; do
		[ -f $dt ] && sudo ${rootPath}/bin/magiskboot dtb $dt patch
	done
	sudo ${rootPath}/bin/magiskboot repack boot.img >/dev/null 2>&1
	sudo rm -rf *kernel* *dtb* ramdisk.cpio*
	[ -f new-boot.img ] && cp -rf new-boot.img boot.img
	sudo rm -rf new-boot.img

	echo "正在使用magisk修补vendor_boot"
	sudo ${rootPath}/bin/magiskboot unpack vendor_boot.img >/dev/null 2>&1
	sudo ${rootPath}/bin/magiskboot cpio ramdisk.cpio patch
	for dt in dtb kernel_dtb extra; do
        [ -f $dt ] && sudo ${rootPath}/bin/magiskboot dtb $dt patch
	done
	sudo ${rootPath}/bin/magiskboot repack vendor_boot.img >/dev/null 2>&1
	sudo rm -rf *kernel* *dtb* ramdisk.cpio*
	[ -f new-boot.img ] && cp -rf new-boot.img vendor_boot.img
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

	# system
	sudo sed -i '0,/[a-z]\+\/lost\\+found/{/[a-z]\+\/lost\\+found/d}' system/config/system_file_contexts
	sudo sh -c "cat ${rootPath}/files/system_file_contexts_add.txt >> system/config/system_file_contexts"
	sudo sh -c "cat ${rootPath}/files/system_fs_config_add.txt >> system/config/system_fs_config"

	sudo rm -rf system/system/verity_key
	sudo rm -rf system/system/system/media/theme/miui_mod_icons/com.google.android.apps.nbu
	sudo rm -rf system/system/system/media/theme/miui_mod_icons/dynamic/com.google.android.apps.nbu
	# Analytics
	sudo rm -rf system/system/system/app/AnalyticsCore/*
	sudo cp ${rootPath}/files/AnalyticsCore.apk system/system/system/app/AnalyticsCore/AnalyticsCore.apk
	# 酷安
	sudo mkdir system/system/system/data-app/CoolApk
	sudo cp ${rootPath}/files/CoolApk.apk system/system/system/data-app/CoolApk/CoolApk.apk
	# MT管理器
	sudo mkdir system/system/system/data-app/MTManager
	sudo cp ${rootPath}/files/MTManager.apk system/system/system/data-app/MTManager/MTManager.apk
	# Magisk
	sudo mkdir system/system/system/data-app/Magisk
	sudo cp ${rootPath}/files/Magisk.apk system/system/system/data-app/Magisk/Magisk.apk
	#
	sudo mv system/system/system/app/Updater/Updater.apk system/system/system/app/Updater/Updater.apk.bak
	#
	sudo mv system/system/system/app/PowerKeeper/PowerKeeper.apk system/system/system/app/PowerKeeper/PowerKeeper.apk.bak
	# 电商助手
	sudo rm -rf system/system/system/app/mab
	#
	sudo rm -rf system/system/system/app/MiuiBugReport
	# 应用商店
	sudo rm -rf system/system/system/app/MIUISuperMarket
	#
	sudo rm -rf system/system/system/app/MSA
	# 搜狗输入法
	sudo rm -rf system/system/system/app/SougouInput
	#
	sudo rm -rf system/system/system/app/Stk
	#
	sudo rm -rf system/system/system/data-app/com.ss.android.article.video_154
	#
	sudo rm -rf system/system/system/data-app/com.ss.android.ugc.aweme_15
	#
	sudo rm -rf system/system/system/data-app/com.taobao.taobao_24

	sudo rm -rf system/system/system/data-app/com.youku.phone_136

	sudo rm -rf system/system/system/data-app/com.zhihu.android_28
	# 小米云盘
	sudo rm -rf system/system/system/data-app/MiDrive
	# 锁屏画报
	sudo rm -rf system/system/system/data-app/MIGalleryLockscreen
	# 小米商城
	sudo rm -rf system/system/system/data-app/MIShop
	# 计算器
	sudo rm -rf system/system/system/data-app/MIUICalculator

	sudo rm -rf system/system/system/data-app/MIUIDuokanReader

	sudo rm -rf system/system/system/data-app/MIUIGameCenter

	sudo rm -rf system/system/system/data-app/MIUIHuanji

	sudo rm -rf system/system/system/data-app/MIUINewHome
	# 小米有品
	sudo rm -rf system/system/system/data-app/MIUIYoupin
	# 米家
	sudo rm -rf system/system/system/data-app/SmartHome
	# wps-lite
	sudo rm -rf system/system/system/data-app/wps-lite

	sudo rm -rf system/system/system/priv-app/MIService
	# 浏览器
	sudo rm -rf system/system/system/priv-app/MIUIBrowser
	# 传送门
	sudo rm -rf system/system/system/priv-app/MIUIContentExtension
	# 搜索
	sudo rm -rf system/system/system/priv-app/MIUIQuickSearchBox
	# 音乐
	# sudo rm -rf system/system/system/priv-app/Music

	# vendor
	sudo sed -i '0,/[a-z]\+\/lost\\+found/{/[a-z]\+\/lost\\+found/d}' vendor/config/vendor_file_contexts

	# 去除 AVB
	sudo sed -i 's/,avb//g' vendor/vendor/etc/fstab.qcom
	sudo sed -i 's/,avb=vbmeta_system//g' vendor/vendor/etc/fstab.qcom
	sudo sed -i 's/,avb_keys=\/avb\/q-gsi.avbpubkey:\/avb\/r-gsi.avbpubkey:\/avb\/s-gsi.avbpubkey//g' vendor/vendor/etc/fstab.qcom


	# product
	sudo sed -i '0,/[a-z]\+\/lost\\+fou#nd/{/[a-z]\+\/lost\\+found/d}' product/config/product_file_contexts
	# 百度输入法
	sudo rm -rf product/product/data-app/BaiduIME

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
