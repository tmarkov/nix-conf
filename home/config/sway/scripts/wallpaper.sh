find /home/todor/Pictures/wallpapers -name '*' -exec file {} \; | grep -o -P '^.+: \w+ image' | cut -d':' -f1 | sort -R | tail -1

