bash split.sh $1
k=0
for i in $(ls inputs/ | awk {'print $1'});do
	python Wordcount.py inputs/$i > output/foo_$k.out
	k=$((k+1))
done;
bash regroup.sh $2
