file=$1
cat output/foo* | sort | awk '{a[$1]+=$2} END {for(x in a) print x, a[x]}' | sort -k2nr -k1 | awk '{ print $1 "\t " $2}' > output/$file.txt
rm output/foo*

