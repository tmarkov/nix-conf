old_pid=$(pgrep swaybg)
swaybg -i $(/home/todor/.config/sway/scripts/wallpaper.sh) -m fill &
sleep 0.1
kill $old_pid

