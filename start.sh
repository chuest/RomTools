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
	${rootPath}/bin/make_ext4fs -J -T 1640966400 -S $fileContexts -l $imgSize -C $fsConfig -L $name -a $name $outImg $inFiles
}

function modify(){
	# system
	sed -i '0,/[a-z]\+\/lost\\+found/{/[a-z]\+\/lost\\+found/d}' system/config/system_file_contexts

	# Analytics
	sudo rm -rf system/system/system/app/AnalyticsCore
	sed -i '/app/AnalyticsCore/d' system/config/system_file_contexts
	sed -i '/app/AnalyticsCore/d' system/config/system_fs_config
	# 电商助手
	sudo rm -rf system/system/system/app/mab
	sed -i '/app/mab/d' system/config/system_file_contexts
	sed -i '/app/mab/d' system/config/system_fs_config
	#
	sudo rm -rf system/system/system/app/MiuiBugReport
	sed -i '/app/MiuiBugReport/d' system/config/system_file_contexts
	sed -i '/app/MiuiBugReport/d' system/config/system_fs_config
	#
	sudo rm -rf system/system/system/app/MIUISuperMarket
	sed -i '/app/MIUISuperMarket/d' system/config/system_file_contexts
	sed -i '/app/MIUISuperMarket/d' system/config/system_fs_config
	#
	sudo rm -rf system/system/system/app/MSA
	sed -i '/app/MSA/d' system/config/system_file_contexts
	sed -i '/app/MSA/d' system/config/system_fs_config
	#
	sudo rm -rf system/system/system/app/SougouInput
	sed -i '/app/SougouInput/d' system/config/system_file_contexts
	sed -i '/app/SougouInput/d' system/config/system_fs_config
	#
	sudo rm -rf system/system/system/app/Stk
	sed -i '/app/Stk/d' system/config/system_file_contexts
	sed -i '/app/Stk/d' system/config/system_fs_config

	sudo rm -rf system/system/system/data-app/com.ss.android.article.video_154
	sed -i '/data-app/com\.ss\.android\.article\.video_154/d' system/config/system_file_contexts
	sed -i '/data-app/com.ss.android.article.video_154/d' system/config/system_fs_config

	sudo rm -rf system/system/system/data-app/com.ss.android.ugc.aweme_15
	sed -i '/data-app/com\.ss\.android\.ugc\.aweme_15/d' system/config/system_file_contexts
	sed -i '/data-app/com.ss.android.ugc.aweme_15/d' system/config/system_fs_config

	sudo rm -rf system/system/system/data-app/com.taobao.taobao_24
	sed -i '/data-app/com\.taobao\.taobao_24/d' system/config/system_file_contexts
	sed -i '/data-app/com.taobao.taobao_24/d' system/config/system_fs_config

	sudo rm -rf system/system/system/data-app/com.youku.phone_136
	sed -i '/data-app/com\.youku\.phone_136/d' system/config/system_file_contexts
	sed -i '/data-app/com.youku.phone_136/d' system/config/system_fs_config

	sudo rm -rf system/system/system/data-app/com.zhihu.android_28
	sed -i '/data-app/com\.zhihu\.android_28/d' system/config/system_file_contexts
	sed -i '/data-app/com.zhihu.android_28/d' system/config/system_fs_config

	sudo rm -rf system/system/system/data-app/MiDrive
	sed -i '/data-app/MiDrive/d' system/config/system_file_contexts
	sed -i '/data-app/MiDrive/d' system/config/system_fs_config

	sudo rm -rf system/system/system/data-app/MIGalleryLockscreen
	sed -i '/data-app/MIGalleryLockscreen/d' system/config/system_file_contexts
	sed -i '/data-app/MIGalleryLockscreen/d' system/config/system_fs_config

	sudo rm -rf system/system/system/data-app/MIShop
	sed -i '/data-app/MIShop/d' system/config/system_file_contexts
	sed -i '/data-app/MIShop/d' system/config/system_fs_config

	sudo rm -rf system/system/system/data-app/MIUICalculator
	sed -i '/data-app/MIUICalculator/d' system/config/system_file_contexts
	sed -i '/data-app/MIUICalculator/d' system/config/system_fs_config

	sudo rm -rf system/system/system/data-app/MIUIDuokanReader
	sed -i '/data-app/MIUIDuokanReader/d' system/config/system_file_contexts
	sed -i '/data-app/MIUIDuokanReader/d' system/config/system_fs_config

	sudo rm -rf system/system/system/data-app/MIUIGameCenter
	sed -i '/data-app/MIUIGameCenter/d' system/config/system_file_contexts
	sed -i '/data-app/MIUIGameCenter/d' system/config/system_fs_config

	sudo rm -rf system/system/system/data-app/MIUIHuanji
	sed -i '/data-app/MIUIHuanji/d' system/config/system_file_contexts
	sed -i '/data-app/MIUIHuanji/d' system/config/system_fs_config

	sudo rm -rf system/system/system/data-app/MIUINewHome
	sed -i '/data-app/MIUINewHome/d' system/config/system_file_contexts
	sed -i '/data-app/MIUINewHome/d' system/config/system_fs_config

	sudo rm -rf system/system/system/data-app/MIUIYoupin
	sed -i '/data-app/MIUIYoupin/d' system/config/system_file_contexts
	sed -i '/data-app/MIUIYoupin/d' system/config/system_fs_config

	sudo rm -rf system/system/system/data-app/SmartHome
	sed -i '/data-app/SmartHome/d' system/config/system_file_contexts
	sed -i '/data-app/SmartHome/d' system/config/system_fs_config

	sudo rm -rf system/system/system/data-app/wps-lite
	sed -i '/data-app/wps-lite/d' system/config/system_file_contexts
	sed -i '/data-app/wps-lite/d' system/config/system_fs_config

	sudo rm -rf system/system/system/priv-app/MIService
	sed -i '/priv-app/MIService/d' system/config/system_file_contexts
	sed -i '/priv-app/MIService/d' system/config/system_fs_config

	sudo rm -rf system/system/system/priv-app/MIUIBrowser
	sed -i '/priv-app/MIUIBrowser/d' system/config/system_file_contexts
	sed -i '/priv-app/MIUIBrowser/d' system/config/system_fs_config

	# 传送门
	sudo rm -rf system/system/system/priv-app/MIUIContentExtension
	sed -i '/priv-app/MIUIContentExtension/d' system/config/system_file_contexts
	sed -i '/priv-app/MIUIContentExtension/d' system/config/system_fs_config

	# 搜索
	sudo rm -rf system/system/system/priv-app/MIUIQuickSearchBox
	sed -i '/priv-app/MIUIQuickSearchBox/d' system/config/system_file_contexts
	sed -i '/priv-app/MIUIQuickSearchBox/d' system/config/system_fs_config

	# 音乐
	# sudo rm -rf system/system/system/priv-app/Music
	# sed -i '/priv-app/Music/d' system/config/system_file_contexts
	# sed -i '/priv-app/Music/d' system/config/system_fs_config

	# system_ext
	sed -i '0,/[a-z]\+\/lost\\+found/{/[a-z]\+\/lost\\+found/d}' system_ext/config/system_ext_file_contexts

	# vendor
	sed -i '0,/[a-z]\+\/lost\\+found/{/[a-z]\+\/lost\\+found/d}' vendor/config/vendor_file_contexts

	# product
	sed -i '0,/[a-z]\+\/lost\\+found/{/[a-z]\+\/lost\\+found/d}' product/config/product_file_contexts

	sudo rm -rf product/product/data-app/BaiduIME
	sed -i '/data-app/BaiduIME/d' product/config/product_file_contexts
	sed -i '/data-app/BaiduIME/d' product/config/product_fs_config

	# DC调光
	sed -i 's/<bool name=\"support_dc_backlight\">false<\/bool>/<bool name=\"support_dc_backlight\">true<\/bool>/g' product/product/etc/device_features/*xml
	sed -i 's/<bool name=\"support_secret_dc_backlight\">true<\/bool>/<bool name=\"support_secret_dc_backlight\">false<\/bool>/g' product/product/etc/device_features/*xml

}

main ${1}