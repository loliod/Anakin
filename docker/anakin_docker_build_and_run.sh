#!/bin/bash

#################################################
#
# Usage: anakin_docker_build_and_run.sh -p -o -m 
#
#################################################

ANAKIN_DOCKER_ROOT="$( cd "$(dirname "$0")" ; pwd -P)"

# help_anakin_docker_run() to print help msg.
help_anakin_docker_run() {
	echo "Usage: $0 -p -o -m"
    echo ""
	echo "Options:"
    echo ""
	echo " -p Hardware Place where docker will running [ NVIDIA-GPU / AMD_GPU / X86-ONLY / ARM ] "
	echo " -o Operating system docker will reside on [ Centos / Ubuntu ] "
	echo " -m Script exe mode [ Build / Run / All] default mode is build and run"
	exit 1
}

# building and running docker for nvidia gpu
building_and_run_nvidia_gpu_docker() {
	if [ ! $# -eq 2 ]; then
		exit 1
	fi
	DockerfilePath=$1
	MODE=$2
	tag="$(echo $DockerfilePath | awk -F/ '{print tolower($(NF-3) "_" $(NF-1))}')"
    echo "Setting env nvidia-docker2 in background ..."
	echo "Building nvidia docker ... [ docker_image_name: Anakin image_tag: $tag ]" 
	if [ ! $MODE = "Run" ]; then
		sudo docker build --network=host -t anakin:$tag"-base" . -f $DockerfilePath
        sudo docker run --network=host --runtime=nvidia --rm -it anakin:$tag"-base"  Anakin/tools/gpu_build.sh
        container_id=$(sudo docker ps -l | sed -n 2p | awk '{print $1}')
        sudo docker commit $container_id anakin:$tag
	else
		sudo docker run --network=host --runtime=nvidia --rm -it anakin:$tag  /bin/bash
	fi
}

# buiding and running docker for amd gpu
building_and_run_amd_gpu_docker() {
	echo "not support yet" 
	read 
	exit 1
}

# building and running docker for x86
building_and_run_x86_docker() { 
	echo "not support yet"
	read
	exit 1
}

# building docker for arm
building_and_arm_docker() { 
	echo "not support yet, Press any key to continue ..."
	read
	exit 1
}

# dispatch user args to target docker path
dispatch_docker_path() {
	# declare associative map from place to relative path
	declare -A PLACE2PATH
	PLACE2PATH["NVIDIA-GPU"]=NVIDIA
	PLACE2PATH["AMD_GPU"]=AMD
	PLACE2PATH["X86-ONLY"]=X86
	PLACE2PATH["ARM"]=ARM
	# declare associative map from os to relative path
	declare -A OS2PATH
	OS2PATH["Centos"]=centos
	OS2PATH["Ubuntu"]=ubuntu

	if [ $# -eq 2 ]; then
		place=$1
		os=$2
		if [ ${PLACE2PATH[$place]+_} ]; then
			echo "+ Found ${PLACE2PATH[$place]} path..."
		else
			echo "+ Error: -p place: $place is not support yet !"
			exit 1
		fi
		if [ ${OS2PATH[$os]+_} ]; then
			echo "+ Found ${OS2PATH[$os]} path..."
		else
			echo "+ Error: -o os: $os is not support yet !"
			exit 1
		fi
		PlaceRelativePath=${PLACE2PATH[$place]}
		OSRelativePath=${OS2PATH[$os]}
	else
		exit 1
	fi
	tag_info="$( ls $ANAKIN_DOCKER_ROOT/$PlaceRelativePath/$OSRelativePath/ )"
	SupportDockerFilePath=$ANAKIN_DOCKER_ROOT/$PlaceRelativePath/$OSRelativePath/$tag_info/Dockerfile
	if [ ! -f $SupportDockerFilePath ];then
		echo "Error: can't find Dockerfile in path: $ANAKIN_DOCKER_ROOT/$PlaceRelativePath/$OSRelativePath/$tag_info"
		exit 1
	fi
}

# get args
if [ $# -lt 2 ]; then
	help_anakin_docker_run
	exit 1
fi

place=0
os=0
mode=All
while getopts p:o:m:hold opt
do
	case $opt in
		p) place=$OPTARG;;
		o) os=$OPTARG;;
		m) mode=${OPTARG};;
		*) help_anakin_docker_run;;
	esac
done

echo "User select place:             $place"
echo "User select operating system:  $os"
echo "User select mode:              $mode"

dispatch_docker_path $place $os
#echo $SupportDockerFilePath

if [ $place = "NVIDIA-GPU" ]; then
	building_and_run_nvidia_gpu_docker $SupportDockerFilePath $mode
elif [ $place = "AMD_GPU" ]; then
	building_and_run_amd_gpu_docker $SupportDockerFilePath $mode
elif [ $place = "X86-ONLY" ]; then
	building_and_run_x86_docker $SupportDockerFilePath $mode
elif [ $place = "ARM" ]; then
	building_and_arm_docker $SupportDockerFilePath $mode
else
	echo "Error: target place is unknown! " 
fi
