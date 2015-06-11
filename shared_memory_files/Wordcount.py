#!/usr/bin/env python

import sys
from datetime import datetime

def print_txt(sortedbyfrequency):
	for word in sortedbyfrequency:
		print word, wordcount[word]


if __name__ =='__main__':
	file =str(sys.argv[1])
	if len(sys.argv) != 2:
		print "Usage: Wordcount.py file ..."
		exit()
	things_to_strip = [".",",","?",")","(","\"",":",";","'s"]
	words_min_size = 4

	text = ""
	f = open(file,"rU")
	for line in f:
		text += line

	words = text.lower().split()
	wordcount = {}
	nb_words=0
	start = datetime.now()
	for word in words:
		nb_words += 1
		for thing in things_to_strip:
			if thing in word:
				word = word.replace(thing,"")
		if len(word) >= words_min_size:
			if word in wordcount:
				wordcount[word] += 1
			else:
				wordcount[word] = 1
	sortedbyfrequency =  sorted(wordcount,key=wordcount.get,reverse=True)
	print_txt(sortedbyfrequency)
