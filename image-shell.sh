#!/bin/sh
#  CreateAppIcon.sh
#  Created by SuperlightBaby on 2017/4/30.
#  Copyright © 2017年 SuperlightBaby. All rights reserved.

# 全局的临时变量，储存用户选择
user_select=""
# 全局的临时变量，储存图片名称
global_image_name=""
# 默认启动图片名称
lauch_image_name="LaunchImage.png"
# 默认icon图片名称
icon_image_name="AppIcon.png"

# --------------------读取文件名或者参数的方法--------------------
JudgeFileIsExist() {
	temp_file_name=$1
	if [ -f "$temp_file_name" ]; then
	    # 文件存在
		echo "*** 文件名称:$temp_file_name ***"
		global_image_name=$temp_file_name
	else
	    # 文件不存在
		echo "*** 文件不存在:$temp_file_name ***"
		echo "*** 请输入文件全名称或者路径，eg：LaunchImage.png ***"
		read -r file_name_para
		sleep 0.5
		# 递归调用
		JudgeFileIsExist "$file_name_para"
	fi
}

#>>>>>>>>>>>>>>>>>>>>>>>先判断是否是图片,是返回0，否返回-1<<<<<<<<<<<<<<<<<<<<<<<<
JudgeIsImage() {
	#format string jpeg | tiff | png | gif | jp2 | pict | bmp | qtif | psd | sgi | tga
	#获取输入的图形文件类型
	imgType=$(sips -g format "$1" | awk -F: '{print $2}')
	#转换为字符串格式
	imgStr="echo $imgType"
	# 去除空格和换行
	typeStr=$($imgStr | xargs echo -n)
	if [ "$typeStr" = "png" ] || [ "$typeStr" = "jpg" ] || [ "$typeStr" = "jpeg" ] || [ "$typeStr" = "tiff" ] || [ "$typeStr" = "gif" ] || [ "$typeStr" = "jp2" ] || [ "$typeStr" = "pict" ] || [ "$typeStr" = "bmp" ] || [ "$typeStr" = "qtif" ] || [ "$typeStr" = "psd" ] || [ "$typeStr" = "sgi" ] || [ "$typeStr" = "tga" ]; then
		return 0
	else
		echo "$1非图片格式,无法转换"
		return 1
	fi
}

#>>>>>>>>>>>>>>>>>>>>>>>自动生成1x，2x，3x图片<<<<<<<<<<<<<<<<<<<<<<<<
#自动生成1x，2x，3x图片，只对png图形有效
ScalePic() {
	#获取文件尺寸，像素值
	imageHeight=$(sips -g pixelHeight "$1" | awk -F: '{print $2}')
	imageWidth=$(sips -g pixelWidth "$1" | awk -F: '{print $2}')
	height=$((imageHeight))
	width=$((imageWidth))
	#2x图形比例
	height2x=$((height * 2 / 3))
	width2x=$((width * 2 / 3))
	#1x图形尺寸
	# height1x=$((height / 3))
	# width1x=$((width / 3))
	#文件名称
	imageFile=$1
	#分别获取文件名和文件类型
	#截取文件名称，最后一个.号前面的字符
	filehead=${imageFile%.*}

	#获取输入的图形文件类型
	imgType=$(sips -g format "$1" | awk -F: '{print $2}')
	imgStr="echo $imgType"
	# 去除空格和换行
	typeStr=$($imgStr | xargs echo -n)

	#fileName1x="$filehead""@1x.""$typeStr"
	fileName2x="$filehead""@2x.""$typeStr"
	fileName3x="$filehead""@3x.""$typeStr"

	#原图像默认为3X
	cp "$imageFile" "XXFolder/$fileName3x"
	#缩放2X图形
	sips -z $height2x $width2x "$1" --out "XXFolder/$fileName2x"
	#缩放1x图形，需要的打开
	# sips -z $height1x $width1x "$1" --out "XXFolder/$fileName1x"
}

# 将文件内所有图片转2x，3x
CreateXXImage() {
	#先删除旧的
	rm -rf XXFolder
	# 再创建CEB文件夹
	mkdir XXFolder
	for file in ./*; do
			#判断是否为文件，排除文件夹
			if [ -f "$file" ]; then
				imageFile=$(basename "$file")
				#判断是否是图片格式
				JudgeIsImage "$imageFile"
				boolIsImg=$?
				if [ $boolIsImg -eq 0 ]; then
					ScalePic "$imageFile"
				else
					echo "非图片文件：$imageFile"
				fi
			fi
	done
}

#>>>>>>>>>>>>>>>>>>>>>>>图片转为PNG<<<<<<<<<<<<<<<<<<<<<<<<
#如果图片不是PNG，则转换为png
ConvertToPng() {
	#format string jpeg | tiff | png | gif | jp2 | pict | bmp | qtif | psd | sgi | tga
	#获取输入的图形文件类型
	imgType=$(sips -g format "$1" | awk -F: '{print $2}')
	#转换为字符串格式
	typeStr="echo $imgType"
	if [ "$typeStr" = "png" ]; then
		echo "$1为PNG图片，不需要转换"
		#拷贝过去即可
		cp "$1" PngFolder/"$1"
	else
		echo "$1格式需要转换"
		#文件全名称
		filename=$1
		#截取文件名称，最后一个.号前面的字符
		filehead=${filename%.*}
		#截取文件后缀名称，删除最后一个.前面的字符
		#filelast=${filename##*.}
		#转换为PNG格式图片
		sips -s format png "$1" --out PngFolder/"${filehead}".png
	fi
 }

# 将文件内所有图片转2x，3x
ConvertAllToPng() {
	#先删除旧的
	rm -rf PngFolder
	# 再创建PngFolder文件夹
	mkdir PngFolder
	for file in ./*; do
		#判断是否为文件，排除文件夹JudgeIsImage
		if [ -f "$file" ]; then
			imageFile=$(basename "$file")
			#判断是否是图片格式
			JudgeIsImage "$imageFile"
			boolIsImg=$?
			if [ $boolIsImg -eq 0 ]; then
				ConvertToPng "$imageFile"
			else
				echo "非图片文件：$imageFile"
			fi
		fi
	done
}

#>>>>>>>>>>>>>>>>>>>>>>>一键生成App图标<<<<<<<<<<<<<<<<<<<<<<<<
#自动生成icon
CreateIconImage() {
	iconRootFolder='IconFolder'
	iconiOSFolder='IconFolder/AppIcon.appiconset'
	#-Z 等比例按照给定尺寸缩放最长边。
	#先删除旧的
	rm -rf ${iconRootFolder}
	# 再创建CEB文件夹
	mkdir ${iconRootFolder}
	mkdir ${iconiOSFolder}

	icon_image_name=$1
#	# icon图片尺寸数组
# 	icon_array=(20 29 40 58 60 76 80 87 120 152 167 180 1024)
# 	# 遍历
# 	for item in "${icon_array[@]}";
# 	do 
# 		sips -Z "$item" "$icon_image_name" --out IconFolder/AppIcon_"$item"x"$item".png
# 	done
	
	# 此处尺寸数组和命名数组一一对应；
# 	icon_array=(20 40 60 29 58 87 40 80 120 57 114 60 120 180 72 144 76 152 228 167 50 100 1024)
	# 以数字开头的命名，前面要加前缀："Icon-App-";非数字开头的直接命名	
# 	icon_nameArray=(20x20@1x 20x20@2x 20x20@3x 29x29@1x 29x29@2x 29x29@3x 40x40@1x 40x40@2x 40x40@3x 57x57@1x 57x57@2x 60x60@1x 60x60@2x 60x60@3x 72x72@1x 72x72@2x 76x76@1x 76x76@2x 76x76@3x 83.5x83.5@2x Icon-Small-50x50@1x Icon-Small-50x50@2x iTunesArtwork@2x)
	
# 	先处理@1x @2x(其中50需单独命名)；再处理@3x；最后处理特殊；

	# @1x @2x
	iOSIconSizeList='20 29 40 50 57 60 72 76 83.5 512'
	iOSIconTypeList='1 2'
	for iconType in ${iOSIconTypeList} ;do
		for iconSize in ${iOSIconSizeList} ;do
			iconActualSize=$iconSize;
			destFolder=${iconiOSFolder}
			if [ ${iconSize} == '83.5' ] && [ ${iconType} == '1' ] ;then
				echo 不需要这个文件:Icon-App-${iconSize}x${iconSize}@${iconType}x.png
				continue;
			else
				iconActualSize=`echo "scale=0;${iconSize} * ${iconType}" | bc `		#按小数相乘，得到实际尺寸(值可能有小数)
				iconActualSize=`echo ${iconActualSize}|sed "s/\..*//g"`				#去掉小数,取整
				iconName=Icon-App-${iconSize}x${iconSize}@${iconType}x
				
				if [ $iconSize == '50' ] ;then	#这个size文件的源文件名不一样
					iconName=Icon-Small-${iconSize}x${iconSize}@${iconType}x
				elif [ $iconSize == '512' ] ;then	#这个size文件的源文件名不一样
					iconName=iTunesArtwork@${iconType}x
					destFolder=${iconRootFolder}
				fi
				
				echo iconType:$iconType	iconActualSize:$iconActualSize	iconName:$iconName
				sips -Z "$iconActualSize" "$icon_image_name" --out ${destFolder}/${iconName}.png
			fi
		done
	done
	
	# @3x
	iOSIconSize3List='20 29 40 60 76 512'
	iOSIconType3='3'
	for iconType in ${iOSIconType3} ;do
		for iconSize in ${iOSIconSize3List} ;do
			iconActualSize=$iconSize;
			destFolder=${iconiOSFolder}
			
			iconActualSize=$iconSize;
			iconActualSize=`echo "scale=0;${iconSize} * ${iconType}" | bc `		#按小数相乘，得到实际尺寸(值可能有小数)
			iconActualSize=`echo ${iconActualSize}|sed "s/\..*//g"`				#去掉小数，取整
			iconName=Icon-App-${iconSize}x${iconSize}@${iconType}x
			echo iconType:$iconType	iconActualSize:$iconActualSize	iconName:$iconName
			if [ ${iconSize} == '512' ];then
				iconName=iTunesArtwork@${iconType}x
				destFolder=${iconRootFolder}
			fi
			sips -Z "$iconActualSize" "$icon_image_name" --out ${destFolder}/${iconName}.png
			
		done
	done
	
	# @特殊 1024 iTunesArtwork@2x
	sips -Z "1024" "$icon_image_name" --out ${iconiOSFolder}/iTunesArtwork@2x.png
	
}

#>>>>>>>>>>>>>>>>>>>>>>>一键生成App启动图片LaunchImage<<<<<<<<<<<<<<<<<<<<<<<<
#自动生成LaunchImage
CreateLaunchImage() {
	#iPhone 6Plus/6SPlus(Retina HD 5.5 @3x): 1242 x 2208
	#iPhone 6/6S/(Retina HD 4.7 @2x): 750 x 1334
	#iPhone 5/5S(Retina 4 @2x): 640 x 1136
	#iPhone 4/4S(@2x): 640 x 960
	#先删除旧的
	rm -rf LaunchImageFolder
	# 再创建CEB文件夹
	mkdir LaunchImageFolder
	image_name=$1
	# 图片高度
	h_array=(960 1024 1136 1334 1792 2048 2208 2436 2688)
	# 图片宽度
	w_array=(640 768  640  750  828  1536 1242 1125 1242)
	array_count=${#h_array[@]}
	for ((i=0; i<"$array_count"; i++))
	do
		sips -z "${h_array[i]}" "${w_array[i]}" "$image_name" --out LaunchImageFolder/"LaunchImage_${h_array[i]}x${w_array[i]}.png"
		# 个别图片需要横屏图片
		if [ "${h_array[i]}" = 1792 ] || [ "${h_array[i]}" = 2208 ] || [ "${h_array[i]}" = 2436 ] || [ "${h_array[i]}" = 2688 ]; then
			sips -z "${w_array[i]}" "${h_array[i]}" "$image_name" --out LaunchImageFolder/"LaunchImage_${w_array[i]}x${h_array[i]}.png"
		fi
	done
}

# 读取用户输入
ReadUserSelectPara() {
	# 判断用户选择的是否在数组内
	isContainPara="0"
	# 读取当前用户选择
	temp_slect=$1
	para_array=(1 2 3 4)
	for item in "${para_array[@]}";
	do 
		if [ "$item" = "$temp_slect" ]; then
			isContainPara="888888"
			break
		fi
	done

	if [ "$isContainPara" = "888888" ]; then
	    # 参数有效
		echo "*** 当前用户选择操作类型:$temp_slect ***"
		user_select="$select_para"
	else
	    # 参数无效
		echo "*** 请输入所选操作的对应数字 ***"
		read -r select_para
		sleep 0.5
		# 递归调用
		ReadUserSelectPara "$select_para"
	fi
}

# 程序主函数
Main() {
	#提示用户选择
	cd "$(dirname "$0")" || exit
	echo "~~~~~~~~~~~~~~~~~~ 输入数字操作(e.g. 输入：1) ~~~~~~~~~~~~~~~"
	echo "~~~~~~~~~ 1 一键生成AppIcon(图片名称需为AppIcon)      ~~~~~~~~"
	echo "~~~~~~~~~ 2 一键生成App启动图(图片名称需为LaunchImage) ~~~~~~~~"
	echo "~~~~~~~~~ 3 一键将所有PNG图片缩放为 2x,3x 图片        ~~~~~~~~"
	echo "~~~~~~~~~ 4 一键将所有图片转化为PNG格式                ~~~~~~~~"

	# 读取用户选择
	ReadUserSelectPara "$user_select"
	#当前方法
	method="$user_select"
	# 判读用户是否有输入
	if [ -n "$method" ]; then
		##########################################
		#一键生成App图标
		if [ "$method" = "1" ]; then
			# 判断默认文件是否存在
			JudgeFileIsExist "$icon_image_name"
			# 创建 icon 图片
			CreateIconImage "$global_image_name"
			##########################################
			#创建启动页图片
		elif [ "$method" = "2" ]; then
			# 判断默认文件是否存在
			JudgeFileIsExist "$lauch_image_name"
			# 生成启动图片
			CreateLaunchImage "$global_image_name"
			##########################################
			#自动生成1x，2x，3x图片
		elif [ "$method" = "3" ]; then
			# 当前目录下所有图片
			CreateXXImage
			##########################################
			#转换格式
		elif [ "$method" = "4" ]; then
			ConvertAllToPng
			##########################################
			#参数无效
		else
			echo "参数无效，重新输入"
		fi
	fi
}

cd "$(dirname "$0")" || exit 0

# 判断有无传递参数，Python脚本中传递有参数
if [ -z "$1" ]; then
    Main
fi
