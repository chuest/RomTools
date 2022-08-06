#!/bin/bash

function main(){
	romName=${1}
	rootPath=`pwd`	#项目脚本
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
	unpackimg system_ext
	modify
	repackimg system
	repackimg vendor
	repackimg product
	repackimg system_ext
	super
	sudo rm -rf _pycache_ system vendor product system_ext system.img vendor.img product.img system_ext.img
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
	# if [ "$name" == "system" ];then mount_path="/" ;else mount_path="/$name" ;fi
	fileContexts="${rootPath}/out/${name}/config/${name}_file_contexts"
	fsConfig="${rootPath}/out/${name}/config/${name}_fs_config"
	imgSize=`echo "$(sudo du -sb ${rootPath}/out/${name} | awk {'print $1'}) + 104857600" | bc`
	outImg="${rootPath}/out/${name}.img"
	inFiles="${rootPath}/out/${name}/${name}"
	echo "正在打包${1}.img"
	sudo ${rootPath}/bin/make_ext4fs -J -T 1640966400 -S $fileContexts -l $imgSize -C $fsConfig -L $name -a $name $outImg $inFiles
}

function super(){
	${rootPath}/bin/lpmake --metadata-size 65536 --super-name super --metadata-slots 2 --device super:9126805504 --group main:$(echo $(stat -c "%s" system.img)+$(stat -c "%s" vendor.img)+$(stat -c "%s" system_ext.img)+$(stat -c "%s" product.img)+$(stat -c "%s" odm.img) | bc) --partition system_a:readonly:$(echo $(stat -c "%s" system.img) | bc):main --partition vendor_a:readonly:$(echo $(stat -c "%s" vendor.img) | bc):main --partition product_a:readonly:$(echo $(stat -c "%s" product.img) | bc) main --partition system_ext_a:readonly:$(echo $(stat -c "%s" system_ext.img) | bc):main --partition odm_a:readonly:$(echo $(stat -c "%s" odm.img) | bc):main --partition system_ext_b:readonly:0:main --partition system_b:readonly:0:main --partition vendor_b:readonly:0:main --partition product_b:readonly:0:main --partition odm_b:readonly:0:main -F --sparse --output super.img
}



function modify(){
	# system
	sudo sed -i '0,/[a-z]\+\/lost\\+found/{/[a-z]\+\/lost\\+found/d}' system/config/system_file_contexts

	# Analytics
	sudo rm -rf system/system/system/app/AnalyticsCore
	sudo sed -i '/app\/AnalyticsCore/d' system/config/system_file_contexts
	sudo sed -i '/app\/AnalyticsCore/d' system/config/system_fs_config
	# 电商助手
	sudo rm -rf system/system/system/app/mab
	sudo sed -i '/app\/mab/d' system/config/system_file_contexts
	sudo sed -i '/app\/mab/d' system/config/system_fs_config
	#
	sudo rm -rf system/system/system/app/MiuiBugReport
	sudo sed -i '/app\/MiuiBugReport/d' system/config/system_file_contexts
	sudo sed -i '/app\/MiuiBugReport/d' system/config/system_fs_config
	#
	sudo rm -rf system/system/system/app/MIUISuperMarket
	sudo sed -i '/app\MIUISuperMarket/d' system/config/system_file_contexts
	sudo sed -i '/app\/MIUISuperMarket/d' system/config/system_fs_config
	#
	sudo rm -rf system/system/system/app/MSA
	sudo sed -i '/app\/MSA/d' system/config/system_file_contexts
	sudo sed -i '/app\/MSA/d' system/config/system_fs_config
	#
	sudo rm -rf system/system/system/app/SougouInput
	sudo sed -i '/app\/SougouInput/d' system/config/system_file_contexts
	sudo sed -i '/app\/SougouInput/d' system/config/system_fs_config
	#
	sudo rm -rf system/system/system/app/Stk
	sudo sed -i '/app\/Stk/d' system/config/system_file_contexts
	sudo sed -i '/app\/Stk/d' system/config/system_fs_config

	sudo rm -rf system/system/system/data-app/com.ss.android.article.video_154
	sudo sed -i '/data-app\/com\\\.ss\\\.android\\\.article\\\.video_154/d' system/config/system_file_contexts
	sudo sed -i '/data-app\/com\.ss\.android\.article\.video_154/d' system/config/system_fs_config

	sudo rm -rf system/system/system/data-app/com.ss.android.ugc.aweme_15
	sudo sed -i '/data-app\/com\\\.ss\\\.android\\\.ugc\\\.aweme_15/d' system/config/system_file_contexts
	sudo sed -i '/data-app\/com\.ss\.android\.ugc\.aweme_15/d' system/config/system_fs_config

	sudo rm -rf system/system/system/data-app/com.taobao.taobao_24
	sudo sed -i '/data-app\/com\\\.taobao\\\.taobao_24/d' system/config/system_file_contexts
	sudo sed -i '/data-app\/com\.taobao\.taobao_24/d' system/config/system_fs_config

	sudo rm -rf system/system/system/data-app/com.youku.phone_136
	sudo sed -i '/data-app\/com\\\.youku\\\.phone_136/d' system/config/system_file_contexts
	sudo sed -i '/data-app\/com\.youku\.phone_136/d' system/config/system_fs_config

	sudo rm -rf system/system/system/data-app/com.zhihu.android_28
	sudo sed -i '/data-app\/com\\\.zhihu\\\.android_28/d' system/config/system_file_contexts
	sudo sed -i '/data-app\/com\.zhihu\.android_28/d' system/config/system_fs_config

	sudo rm -rf system/system/system/data-app/MiDrive
	sudo sed -i '/data-app\/MiDrive/d' system/config/system_file_contexts
	sudo sed -i '/data-app\/MiDrive/d' system/config/system_fs_config

	sudo rm -rf system/system/system/data-app/MIGalleryLockscreen
	sudo sed -i '/data-app\/MIGalleryLockscreen/d' system/config/system_file_contexts
	sudo sed -i '/data-app\/MIGalleryLockscreen/d' system/config/system_fs_config

	sudo rm -rf system/system/system/data-app/MIShop
	sudo sed -i '/data-app\/MIShop/d' system/config/system_file_contexts
	sudo sed -i '/data-app\/MIShop/d' system/config/system_fs_config

	sudo rm -rf system/system/system/data-app/MIUICalculator
	sudo sed -i '/data-app\/MIUICalculator/d' system/config/system_file_contexts
	sudo sed -i '/data-app\/MIUICalculator/d' system/config/system_fs_config

	sudo rm -rf system/system/system/data-app/MIUIDuokanReader
	sudo sed -i '/data-app\/MIUIDuokanReader/d' system/config/system_file_contexts
	sudo sed -i '/data-app\/MIUIDuokanReader/d' system/config/system_fs_config

	sudo rm -rf system/system/system/data-app/MIUIGameCenter
	sudo sed -i '/data-app\/MIUIGameCenter/d' system/config/system_file_contexts
	sudo sed -i '/data-app\/MIUIGameCenter/d' system/config/system_fs_config

	sudo rm -rf system/system/system/data-app/MIUIHuanji
	sudo sed -i '/data-app\/MIUIHuanji/d' system/config/system_file_contexts
	sudo sed -i '/data-app\/MIUIHuanji/d' system/config/system_fs_config

	sudo rm -rf system/system/system/data-app/MIUINewHome
	sudo sed -i '/data-app\/MIUINewHome/d' system/config/system_file_contexts
	sudo sed -i '/data-app\/MIUINewHome/d' system/config/system_fs_config

	sudo rm -rf system/system/system/data-app/MIUIYoupin
	sudo sed -i '/data-app\/MIUIYoupin/d' system/config/system_file_contexts
	sudo sed -i '/data-app\/MIUIYoupin/d' system/config/system_fs_config

	sudo rm -rf system/system/system/data-app/SmartHome
	sudo sed -i '/data-app\/SmartHome/d' system/config/system_file_contexts
	sudo sed -i '/data-app\/SmartHome/d' system/config/system_fs_config

	sudo rm -rf system/system/system/data-app/wps-lite
	sudo sed -i '/data-app\/wps-lite/d' system/config/system_file_contexts
	sudo sed -i '/data-app\/wps-lite/d' system/config/system_fs_config

	sudo rm -rf system/system/system/priv-app/MIService
	sudo sed -i '/priv-app\/MIService/d' system/config/system_file_contexts
	sudo sed -i '/priv-app\/MIService/d' system/config/system_fs_config

	sudo rm -rf system/system/system/priv-app/MIUIBrowser
	sudo sed -i '/priv-app\/MIUIBrowser/d' system/config/system_file_contexts
	sudo sed -i '/priv-app\/MIUIBrowser/d' system/config/system_fs_config

	# 传送门
	#sudo rm -rf system/system/system/priv-app/MIUIContentExtension
	#sudo sed -i '/priv-app\/MIUIContentExtension/d' system/config/system_file_contexts
	#sudo sed -i '/priv-app\/MIUIContentExtension/d' system/config/system_fs_config

	# 搜索
	sudo rm -rf system/system/system/priv-app/MIUIQuickSearchBox
	sudo sed -i '/priv-app\/MIUIQuickSearchBox/d' system/config/system_file_contexts
	sudo sed -i '/priv-app\/MIUIQuickSearchBox/d' system/config/system_fs_config

	# 音乐
	# sudo rm -rf system/system/system/priv-app/Music
	# sed -i '/priv-app/Music/d' system/config/system_file_contexts
	# sed -i '/priv-app/Music/d' system/config/system_fs_config


	# system_ext
	sudo sed -i '0,/[a-z]\+\/lost\\+found/{/[a-z]\+\/lost\\+found/d}' system_ext/config/system_ext_file_contexts


	# vendor
	sudo sed -i '0,/[a-z]\+\/lost\\+found/{/[a-z]\+\/lost\\+found/d}' vendor/config/vendor_file_contexts

	# 去除 AVB
	# sudo sed -i "s/fileencryption=/encryptable=/g" vendor/vendor/etc/fastab.qcom
	# sudo sed -i 's/ro,/ro,noatime,/g' vendor/vendor/etc/fastab.qcom
	sudo sed -i 's/,avb//g' vendor/vendor/etc/fastab.qcom
	sudo sed -i 's/,avb=vbmeta_system//g' vendor/vendor/etc/fastab.qcom
	sudo sed -i 's/,avb_keys=\/avb\/q-gsi.avbpubkey:\/avb\/r-gsi.avbpubkey:\/avb\/s-gsi.avbpubkey//g' vendor/vendor/etc/fastab.qcom


	# product
	sudo sed -i '0,/[a-z]\+\/lost\\+fou#nd/{/[a-z]\+\/lost\\+found/d}' product/config/product_file_contexts

	sudo rm -rf product/product/data-app/BaiduIME
	sudo sed -i '/data-app\/BaiduIME/d' product/config/product_file_contexts
	sudo sed -i '/data-app\/BaiduIME/d' product/config/product_fs_config

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
	sudo sed -i 's/<bool name=\"support_ai_task\">false<\/bool>/<bool name=\"support_ai_task\">true<\/bool>/g' product/product/etc/device_features/*xml

	# 呼吸灯
	# sudo sed -i 's/<bool name=\"support_led_color\">false<\/bool>/<bool name=\"support_led_color\">true<\/bool>/g' product/product/etc/device_features/*xml
	# sudo sed -i 's/<bool name=\"support_led_light\">false<\/bool>/<bool name=\"support_led_light\">true<\/bool>/g' product/product/etc/device_features/*xml

	# 游戏英雄死亡倒计时
	sudo sed -i '/<\/features>/i\    <bool name=\"support_mi_game_countdown\">true<\/bool>' product/product/etc/device_features/*xml


}

main ${1}