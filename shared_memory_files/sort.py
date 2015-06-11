#!/usr/bin/python
import os
from datetime import datetime

def wordcount_sort(fname):
    cmd = 'sort -rnk 2 /home/ubuntu/hadoop-1.2.1/out > %s.txt' % fname
    start = datetime.now()
    os.system(cmd)
    stop = datetime.now()
    print 'Hadoop File sorted, Time Taken: %s secs' % (stop - start)
    return

if __name__ == '__main__':
    print 'Enter the File Name of the sorted file:'
    fname = raw_input()
    wordcount_sort(fname)
	

