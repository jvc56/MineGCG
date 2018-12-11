#! /bin/bash

pause() {
	sleep .05
}

type_number() {
	foo=$1
	for (( i=0; i<${#foo}; i++ )); do
	  pause
	  xte 'key '"${foo:$i:1}"
	done
}



wmctrl -a Zyzzyva

xte 'key Alt_L' 'key f'
pause
xte 'key Down'
pause
xte 'key Down'
pause
xte 'key Return'
for (( i = 0; i < 7; i++ )); do
	xte 'key Tab'
	pause
done
xte 'key space'
for (( i = 0; i < 9; i++ )); do
	xte 'key Down'
	pause
done
xte 'key Return'
xte 'key Tab'
xte 'key Tab'
xte 'key Tab'
xte 'key Tab'
xte 'key space'

for (( i = 0; i < 7; i++ )); do
	xte 'key Tab'
	pause
done
export x=0

for (( y = 0; y < 2249; y++ )); do
	((x++))
	xte 'keydown Control_L' 'keydown a'
	pause
	xte 'keyup Control_L' 'keyup a'
	pause
	type_number "$x"
	pause
	((x+=13))
	xte 'key Tab'
	pause
	type_number "$x"
	pause
	xte 'key Tab'
	pause
	xte 'key Tab'
	pause
	xte 'key Tab'
	pause
	xte 'key Return'
	pause
	sleep 6
	xte 'keydown Control_L' 'keydown s'
	pause
	xte 'keyup Control_L' 'keyup s'
	if [[ "$(wmctrl -l)" != *"Save Word List"* ]]; then
		break 2
	fi

	wmctrl -a "Save Word List"

	for (( i = 0; i < 8; i++ )); do
		xte 'key Tab'
		xte 'key space'
		xte 'key Tab'
		xte 'key space'
		xte 'key Tab'
		xte 'key Tab'
		xte 'key Tab'
	done
	pause
	xte 'key Return'
	pause
	xte 'str ='
	type_number "$x"
	pause
	xte 'key Return'
	pause
	if [[ "$(wmctrl -l)" == *"File Exists"* ]]; then
		xte 'key Tab'
		pause
		xte 'key Return'
		pause
	fi
done

# cd /home/jvc/.collinszyzzyva/words/saved
# cat =* | sort > America.txt