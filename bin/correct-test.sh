#!/bin/bash

CURPATH=`pwd`
BINDIR=$1
LEVELS=$2
DBDIR=$3
ALIGNDIR=$4
OUTPUT_DIR=$5 ## either dev_output or test_output - no absolute paths!
TEST_GOLD=$6 ## can be either devtest or test, same with below
TEST_SOURCE=$7
TEST_TARGET=$8
TEST_LINGUA=$9
RULEKEYS=${10}

rm -f $DBDIR/$OUTPUT_DIR/all_correct_eval.txt

if [[ ! -d $ALIGNDIR/$OUTPUT_DIR ]]; then
	mkdir $ALIGNDIR/$OUTPUT_DIR
else
	rm -f $ALIGNDIR/$OUTPUT_DIR/*.*
fi

if [[ ! -d $DBDIR/$OUTPUT_DIR ]]; then
	mkdir $DBDIR/$OUTPUT_DIR
else
	rm -f $DBDIR/$OUTPUT_DIR/*.*
fi

cp $TEST_LINGUA $ALIGNDIR/$OUTPUT_DIR
cd $ALIGNDIR/$OUTPUT_DIR
TEST_LINGUA_DIR=`pwd`
cd $CURPATH
TEST_LINGUA_FILE=`echo $TEST_LINGUA | sed -r 's/.*\/([^/*])/\1/'`
#echo "testlinguafile: $TEST_LINGUA_FILE"
TEST_LINGUA=$TEST_LINGUA_DIR/$TEST_LINGUA_FILE
## copied the automatic output file to a working directory and changed the path name accordingly

if [[ ! -e "$LEVELS" ]]; then
	echo "File with rule numbers ($LEVELS) does not exist!"
	exit
fi

echo "Precision (all)	Recall (all)	Recall (good)	Recall (fuzzy)	F-score (P_all & R_all)	F-score (P_all & R_good)" >> $DBDIR/$OUTPUT_DIR/all_correct_eval.txt
while read line
do
	let LEVEL=$line
	echo "Applying rule $LEVEL..."
	if [[ ! -d "$ALIGNDIR/$OUTPUT_DIR/$LEVEL" ]]; then
		mkdir $ALIGNDIR/$OUTPUT_DIR/$LEVEL
	fi
        if [[ ! -d "$DBDIR/$OUTPUT_DIR/$LEVEL" ]]; then
               	mkdir $DBDIR/$OUTPUT_DIR/$LEVEL
	fi
	echo "Extracting statistics..."
## Extracting statistics of new input
	echo "perl $BINDIR/generate-iterate.pl -a $TEST_GOLD -s $TEST_SOURCE -t $TEST_TARGET -A $TEST_LINGUA -r $RULEKEYS -M $DBDIR/$OUTPUT_DIR/$LEVEL/man_alignstats.txt -L $DBDIR/$OUTPUT_DIR/$LEVEL/ling_alignstats.txt -S $DBDIR/$OUTPUT_DIR/$LEVEL/srctreestats.txt -T $DBDIR/$OUTPUT_DIR/$LEVEL/trgtreestats.txt -R $DBDIR/$OUTPUT_DIR/$LEVEL/rulestats.txt -g"
	perl $BINDIR/generate-iterate.pl -a $TEST_GOLD -s $TEST_SOURCE -t $TEST_TARGET -A $TEST_LINGUA -r $RULEKEYS -M $DBDIR/$OUTPUT_DIR/$LEVEL/man_alignstats.txt -L $DBDIR/$OUTPUT_DIR/$LEVEL/ling_alignstats.txt -S $DBDIR/$OUTPUT_DIR/$LEVEL/srctreestats.txt -T $DBDIR/$OUTPUT_DIR/$LEVEL/trgtreestats.txt -R $DBDIR/$OUTPUT_DIR/$LEVEL/rulestats.txt -g
## Looking for best rule that was found in training phase for this iteration level
	if [[ ! -e $DBDIR/$LEVEL/bestrule.txt ]]; then
		echo "bestrule.txt does not exist on $DBDIR/$LEVEL! Exiting..."
		exit
	fi
	let NEWLEVEL=$LEVEL+1
	if [[ ! -d $ALIGNDIR/$OUTPUT_DIR/$NEWLEVEL ]]; then
		mkdir $ALIGNDIR/$OUTPUT_DIR/$NEWLEVEL
	fi
	echo "perl $BINDIR/apply-best-rule.pl -s $TEST_SOURCE -t $TEST_TARGET -a $TEST_LINGUA -A $ALIGNDIR/$OUTPUT_DIR/$NEWLEVEL/align.xml -b $DBDIR/$LEVEL/bestrule.txt -n $DBDIR/$OUTPUT_DIR/$LEVEL/rulestats.txt -l $DBDIR/$OUTPUT_DIR/$LEVEL/ling_alignstats.txt"
	perl $BINDIR/apply-best-rule.pl -s $TEST_SOURCE -t $TEST_TARGET -a $TEST_LINGUA -A $ALIGNDIR/$OUTPUT_DIR/$NEWLEVEL/align.xml -b $DBDIR/$LEVEL/bestrule.txt -n $DBDIR/$OUTPUT_DIR/$LEVEL/rulestats.txt -l $DBDIR/$OUTPUT_DIR/$LEVEL/ling_alignstats.txt
	cp $ALIGNDIR/$OUTPUT_DIR/$NEWLEVEL/align.xml $ALIGNDIR/$OUTPUT_DIR
## this align.xml becomes the new current alignment file
	cd $ALIGNDIR/$OUTPUT_DIR
	TEST_LINGUA_DIR=`pwd`
	cd $CURPATH
	TEST_LINGUA=$TEST_LINGUA_DIR/align.xml
	if [[ ! -d $DBDIR/$OUTPUT_DIR/$NEWLEVEL ]]; then
		mkdir $DBDIR/$OUTPUT_DIR/$NEWLEVEL
	fi
	echo "Evaluating new alignment file after iteration $LEVEL and writing it to $DBDIR/$OUTPUT_DIR/$NEWLEVEL/eval.txt"
	rm -f $DBDIR/$OUTPUT_DIR/$NEWLEVEL/eval.txt
	perl $BINDIR/eval-nonterms.pl -a $ALIGNDIR/$OUTPUT_DIR/$NEWLEVEL/align.xml -g $TEST_GOLD >> $DBDIR/$OUTPUT_DIR/$NEWLEVEL/eval.txt
	perl $BINDIR/eval-nonterms.pl -h -a $ALIGNDIR/$OUTPUT_DIR/$NEWLEVEL/align.xml -g $TEST_GOLD
      	echo "Writing these last results to $DBDIR/$OUTPUT_DIR/all_correct_eval.txt"
      	tail -n +1 $DBDIR/$OUTPUT_DIR/$NEWLEVEL/eval.txt >> $DBDIR/$OUTPUT_DIR/all_correct_eval.txt
done < $LEVELS
