#!/bin/bash

TEXT_FILE="/tmp/ocr.txt"
IMAGE_FILE="/tmp/ocr.png"

notify(){
	notify-send -i "$HOME"/.dotfiles/icons/ocr.png "Screenshot" "$1"
}

check_deps(){
	dependencies=(tesseract maim notify-send xclip trans)
	for dependency in "${dependencies[@]}"; do
	    type -p "$dependency" &>/dev/null || {
		notify "Could not find '${dependency}', is it installed?"
		echo "Could not find '${dependency}', is it installed?"
		exit 1
	    }
	done
}

do_ocr(){
	# Tesseract adds .txt to the given file path anyways. So if we were to
	# specify /tmp/ocr.txt as the file path, tesseract would out the text to 
	# /tmp/ocr.txt.txt
	tesseract "$IMAGE_FILE" "${TEXT_FILE//\.txt/}" 2> /dev/null

	# Remove the new page character.
	sed -i 's/\x0c//' "$TEXT_FILE"

	# Check if the text was detected by checking number
	# of lines in the file
	NUM_LINES=$(wc -l < $TEXT_FILE)
	if [ "$NUM_LINES" -eq 0 ]; then
	    notify "No text was detected"
	    exit 1
	fi

}

mode_copy(){
	xclip -selection clipboard -t image/png < "$IMAGE_FILE"
}

mode_save(){
	FILE_BASE=$(rofi -dmenu -p "Enter file name")
	FILE_PATH="/tmp/$FILE_BASE.png"
	cp "$IMAGE_FILE" "$FILE_PATH"
	
	notify "Saved to $FILE_PATH."
}

mode_ocr(){

	# Do OCR
	do_ocr

	# Copy text to clipboard
	xclip -selection clip < "$TEXT_FILE"

	# Send a notification with the text that was grabbed using OCR
	notify "$(cat $TEXT_FILE)"
}

mode_scholar(){
	do_ocr

	# search google scholar for it 
	sed -i 's/ /_/' "$TEXT_FILE"

	xdg-open "https://scholar.google.com/scholar?q=$(cat $TEXT_FILE)"
}

mode_translate(){
	do_ocr
	TRANS=$(trans -brief en:de "$(cat $TEXT_FILE)" || echo "Error translating.")
	notify "$(cat $TEXT_FILE):\n$TRANS"
}

main(){
	
	check_deps

	# Take screenshot by selecting the area, exit if aborted
	maim -s "$IMAGE_FILE" || exit 1

	MODE=$(printf " Copy image to clipboard\n Save image to file\n󰦨 Text recognition\n Google scholar search\n󰗊 Translate to german" | rofi -dmenu -p "Mode ")
	case $MODE in
		" Copy image to clipboard")
			mode_copy
			;;
		" Save image to file")
			mode_save
			;;
		"󰦨 Text recognition")
			mode_ocr
			;;
		" Google scholar search")
			mode_scholar
			;;
		"󰗊 Translate to german")
			mode_translate
			;;
	esac

	rm "$TEXT_FILE"
	rm "$IMAGE_FILE"
}

main
