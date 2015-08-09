#!/bin/bash

#TODO: If the file is > 250Mb split the file
#TODO: Mark as completed
#TODO: Clean up
#TODO: Avoid to execute backup if the folder is marked as finished.

EXTERNAL_DISK_PATH="/mnt/backup/Backups/"
SEARCH_PATTERN="/home/hector/"
PASS_FILE="/home/hector/Desarrollo/bash scripts/boxpass"
ENCRYPTED_PASS=""
USERNAME="hektor7@gmail.com"
WEBDAV_BASE_URL="https://dav.box.com/dav/"
GPG_RECIPIENT="hektor7@gmail.com"
REMOTE_HOST="www.box.com"

function write_log(){
	echo $message >> "/home/hector/box_backup.log"
}

function upload_file(){
	
	#Extract filename from full path
	filename=$(echo "$file" | sed -e 's/\/.*\///g')
	
	#Obtain encoded pass
	ENCRYPTED_PASS=$(cat "$PASS_FILE")
	#Obtain plain text pass from encoded pass
	pass=`echo "$ENCRYPTED_PASS" | base64 --decode`
	
	#Get an empty string if file exists
	result=$(curl -u $USERNAME:$pass -i -X PROPFIND "$WEBDAV_BASE_URL$destination_path$filename" | grep 404\ Not\ Found)
	
	if [ "$result" != "" ] #If file doesn't exists
	then
		message="Upload $file..."
		write_log $message
		
		curl -T "$file" "$WEBDAV_BASE_URL$destination_path" -u $USERNAME:$pass --ftp-create-dirs
	fi
}

function upload_dir (){

	if test "$(ls -A $SEARCH_PATTERN)"; then
		
		#Obtain encoded pass
		ENCRYPTED_PASS=$(cat "$PASS_FILE")
		pass=`echo "$ENCRYPTED_PASS" | base64 --decode`
		#curl -T $filename $WEBDAV_BASE_URL$destination_path$filename -u $USERNAME:$pass
		#find mydir -type f -exec curl -u xxx:psw --ftp-create-dirs -T {} ftp://192.168.1.158/public/demon_test/{} \;
		#find $source_dir -type f -exec curl -T {} $WEBSAV_BASE_URL$destination_path{} -u $USERNAME:$pass --ftp-create-dirs   \;
		
		curl -u $USERNAME:$pass -X MKCOL "$WEBDAV_BASE_URL$destination_path" #If this dir exists it's going to throw an exception but the execution continues. 
		
		for i in `find $source_dir -type f` #Obtain files from source dir
		do
			file=$i
			upload_file "$file"
			#curl -T $i $WEBDAV_BASE_URL$destination_path -u $USERNAME:$pass --ftp-create-dirs
		done
	else
		echo "The source directory $SOURCE_ROOT is empty '(or non-existent)'"
	fi
  
}

function compress_folder(){
	
	echo "Received dir ---> $directory"
	
	directory_wo_slash="${directory%/}" #Remove slash from directory
	
	echo "Removed slash ---> $directory_wo_slash"
	
	#dirname=$(echo "$directory_wo_slash" | sed -e 's/\/.*\///g')
	
	dirname=${directory_wo_slash##*/} #Obtain dirname from fullpath
	
	echo "Dirname ---> $dirname"
	
	#dirname=$(printf %q "$dirname") #escape spaces
	
	echo "tar -zcvf "$dirname.tar.gz" "$dirname""
	cd "$directory"
	cd ..
	
	
	if [ ! -f "$dirname.tar.gz" ]; then
		echo "Compressing..."
		tar -zcvf "$dirname.tar.gz" "$dirname"
	fi
	
}

function compress_subfolders(){
	cd $source_dir
	#for i in `find -mindepth 1 -type d`
	for i in */ #Directories...
	do
		echo "i value: $i"
		i=${i//.\/}
		directory="$(echo "$source_dir/$i")"
		echo "Directory to compress_folder $directory"
		compress_folder "$directory"
	done
}

function encrypt_file(){
	if [ ! -f "$source_file.gpg" ];then
		
		
		message="Encrypt $source_file..."
		write_log $message
		
		echo $message
		
		gpg -e -r $GPG_RECIPIENT "$source_file"
	fi
}

function mark_as_finished(){
	cd "$(dirname $file)"
	echo "Backup has been completed on $(date)" > "$file.backup.finished"
}

function clean_dir(){
	for i in `find $source_dir -type f -name "*.backup.finished"`
	do
		file="${i%.backup.finished}" #${var%.backup.finished}
		echo "rm -rf $file" >> "/home/hector/cleanup_script.sh"
		
		file="${i%.gpg.backup.finished}" #${var%.backup.finished}
		echo "rm -rf $file" >> "/home/hector/cleanup_script.sh"
		
		#rm -rf $file
		
		mark_as_finished "$file"
	done
}

function backup_dir(){
	
	#Check for availability of folder...
	
	if test "$(ls -A $source_dir)"; then
	
		message="Trying to compress subfolders from $source_dir"
		write_log $message
		
		compress_subfolders "$source_dir"
		
		message="Looking for .tar.gz files in order to encrypt"
		write_log $message
		
		#for i in `find $source_dir -type f -name "*.tar.gz"`
		for i in *.tar.gz
		do
			echo "File to encrypt_file ---> $i"
			source_file="$i"
			encrypt_file "$source_file"
		done
		
		message="Looking for .tar.gz.gpg files in order to upload them"
		write_log $message
		
		#for i in `find "$source_dir" -type f -name "*.tar.gz.gpg"`
		for i in *.tar.gz.gpg
		do
			file=$i
			upload_file "$file" "$destination_path"
			
			#mark_as_finished $file
		done
		
		#clean_dir $source_dir
		
	else
		message="Folder $source_dir is unavailable... External disk unplugged?"
		write_log $message
	fi	
	
	
}

function init(){
	
	message="Starting online backup at: $(date)"
	write_log $message
	
	#test for internet connection
	ping -c 1 $REMOTE_HOST > /dev/null
	
	if [ "$?" == 0 ]; then
		
		# Dir to be saved
		#destination_path="Fotos/"
		#source_dir="/mnt/backup/Backups/backup_medion/Imágenes/Fotos"
		destination_path="prueba/"
		source_dir="/home/hector/prueba"
		backup_dir "$source_dir" "$destination_path"
		
	else
		message="Host $REMOTE_HOST is unavailable..."
		write_log $message
	fi
	
	message="Finished online backup at: $(date)"
	write_log $message
}

init

#To encrypt file
#source_file="/home/hector/prueba/prueba aaa/asd"

#encrypt_file $source_file

#To compress folder
#directory="/home/hector/prueba/prueba aaa/"
#compress_folder $directory 

#To compress a dir that contains subdirs
#source_dir="/home/hector/prueba"

#compress_subfolders $directory

#To upload dir to box.com

#source_dir="/home/hector/prueba"
#destination_path="prueba/"

#upload_dir $source_dir $destination_path
