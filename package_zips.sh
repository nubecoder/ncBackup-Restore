#!/bin/bash
#
# package_zips.sh
#
#
# 2011 nubecoder
# http://www.nubecoder.com/
#

#defines
TOOLS_PATH="$PWD/installer-zip/tools"
UPDATER_PATH="$PWD/installer-zip/META-INF/com/google/android"
BACKUP_FILE="doBackup"
RESTORE_FILE="doRestore"
UPDATER_FILE="updater-script"

#functions
SPACER()
{
	echo "*"
}
START_SCRIPT()
{
	TIME_START=$(date +%s)
	echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
}
SHOW_COMPLETED()
{
	echo "Script completed."
	TIME_END=$(date +%s)
	echo "Total time: $(($TIME_END - $TIME_START)) seconds."
	SPACER
	echo "=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]=]"
	exit
}
REPLACE_TEXT()
{
	sed -i s/$1/$2/g "$3"
}
REMOVE_FILES()
{
	rm -f "$TOOLS_PATH/$BACKUP_FILE"
	rm -f "$TOOLS_PATH/$RESTORE_FILE"
	rm -f "$UPDATER_PATH/$UPDATER_FILE"
}
PREPARE_ZIP_FOLDER()
{
	local FILE="$1"
	REMOVE_FILES
	cp "$PWD/$FILE" "$TOOLS_PATH/$FILE"
	cp "$PWD/$UPDATER_FILE" "$UPDATER_PATH/$UPDATER_FILE"
}
PATCH_FOR_ZIP()
{
	local FILE="$TOOLS_PATH/$1"
	sed -i 's/#!\/system\/bin\/sh/#!\/data\/local\/tmp\/busybox sh/g' $FILE
}
PATCH_FOR_DATA_WIPE()
{
	local FILE="$TOOLS_PATH/$1"
	local PATTERN="#\tWIPE_DATA_FOLDER"
	local REPLACEMENT="\tWIPE_DATA_FOLDER"
	REPLACE_TEXT $PATTERN $REPLACEMENT $FILE
}
PATCH_FOR_RESTORE()
{
	local FILE="$UPDATER_PATH/$UPDATER_FILE"
	local PATTERN=$BACKUP_FILE
	local REPLACEMENT=$RESTORE_FILE
	REPLACE_TEXT $PATTERN $REPLACEMENT $FILE
	local PATTERN="backup"
	local REPLACEMENT="restore"
	REPLACE_TEXT $PATTERN $REPLACEMENT $FILE
	sed -i 's/show_progress(1.0, 120)/show_progress(1.0, 60)/g' $FILE
	sed -i 's/=]               Android Backup               =]/=]               Android Restore              =]/g' $FILE
}
PATCH_FOR_EVO()
{
	local FILE="$UPDATER_PATH/$UPDATER_FILE"
	local PATTERN="SPH-D700"
	local REPLACEMENT="supersonic"
	REPLACE_TEXT $PATTERN $REPLACEMENT $FILE
	local PATTERN="\/dev\/block\/stl9"
	local REPLACEMENT="\/dev\/block\/mtdblock4"
	REPLACE_TEXT $PATTERN $REPLACEMENT $FILE
	local PATTERN="\/dev\/block\/stl10"
	local REPLACEMENT="\/dev\/block\/mtdblock6"
	REPLACE_TEXT $PATTERN $REPLACEMENT $FILE
}
CREATE_ZIP()
{
	local T1=$(date +%s)
	local FILE_NAME="android_$1.zip"
	echo "Begin $FILE_NAME creation"
	local IS_BACKUP="backup"
	if [ "$FILE_NAME" != "${FILE_NAME/$IS_BACKUP/}" ] ; then
		PREPARE_ZIP_FOLDER "$BACKUP_FILE"
		PATCH_FOR_ZIP "$BACKUP_FILE"
	else
		PREPARE_ZIP_FOLDER "$RESTORE_FILE"
		PATCH_FOR_ZIP "$RESTORE_FILE"
		local IS_WIPE="Data_Wipe"
		if [ "$FILE_NAME" != "${FILE_NAME/$IS_WIPE/}" ] ; then
			PATCH_FOR_DATA_WIPE "$RESTORE_FILE"
		fi
		PATCH_FOR_RESTORE
	fi
	local FIND_EVO="EVO"
	if [ "$FILE_NAME" != "${FILE_NAME/$FIND_EVO/}" ] ; then
		PATCH_FOR_EVO
	fi
	local OUTFILE=$PWD/$FILE_NAME
	rm -f "$OUTFILE"
	local MKZIP='7z -mx9 -mmt=1 a "$OUTFILE" .'
	pushd "installer-zip" > /dev/null
		eval "$MKZIP" > /dev/null
	popd > /dev/null
	local T2=$(date +%s)
	echo "Done: creation took $(($T2 - $T1)) seconds."
}

#main
START_SCRIPT

SPACER
echo "Packaging EPIC zips:"
CREATE_ZIP "backup_EPIC"
CREATE_ZIP "restore_EPIC"
CREATE_ZIP "restore_EPIC_Data_Wipe"

SPACER
echo "Packaging EVO zips:"
CREATE_ZIP "backup_EVO"
CREATE_ZIP "restore_EVO"
CREATE_ZIP "restore_EVO_Data_Wipe"

SPACER
REMOVE_FILES
SHOW_COMPLETED

