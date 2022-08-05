sudo apt update
sudo apt upgrade -y
sudo apt install zip unzip python3 python3-pip zipalign android-sdk-ext4-utils -y

romName=${1}
rootPath=`pwd`	#项目脚本
mkdir out
echo "正在解压刷机包"
unzip -o $romName -d out
rm -rf $romName
cd out
rm -rf META-INF apex_info.pb care_map.pb payload_properties.txt
${rootPath}/bin/payload-dumper-go payload.bin ${rootPath}/out
rm -rf payload.bin
unpackimg "system"
unpackimg "vendor"
unpackimg "product"
unpackimg "system_ext"
repackimg "system"
repackimg "vendor"
repackimg "product"
repackimg "system_ext"


function unpackimg(){
	echo "正在解压${1}.img"
	python3 ${rootPath}/bin/imgextractor.py ${1}.img ${1}
	rm -rf ${1}.img
}

function repackimg(){
	name=${1}
	mount_path="/$name"
	# if [ "$name" == "system" ];then mount_path="/" ;else mount_path="/$name" ;fi
	fileContexts = "${rootPath}/out/${name}/config/${name}_file_contexts"
	fsConfig = "${rootPath}/out/${name}/config/${name}_fs_config"
	imgSize = `echo "$(du -sb ${rootPath}/out/${name} | awk {'print $1'}) + 104857600" | bc`
	outImg = "${rootPath}/out/${name}.img"
	inFiles = "${rootPath}/out/${name}/${name}"
	echo "正在打包${1}.img"
	make_ext4fs -J -T 1640966400 -S $fileContexts -l $imgSize -C $fsConfig -L $name -a $name $outImg $inFiles
}
