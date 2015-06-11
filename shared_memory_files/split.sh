file=$1
size=$(du $file | awk {'print $1'})
size=$((size/16))
size=$((size/4))
sudo split -d --bytes="$size"k $file inputs/data


