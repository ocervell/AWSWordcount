file=$1
nprocs=$2
size=$(ls -l| grep $file | awk {'print $5'})
size=$((size/100))
size=$((size/nprocs))
sudo split -d -l "$size" $file input/data
