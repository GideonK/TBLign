#!/bin/bash

CURPATH=`pwd`
BINDIR=$1
LEVELS=$2
DBDIR=$3
ALIGNDIR=$4
OUTPUT_DIR=$5
TEST_GOLD=$6 ## TEST can refer to any data set that is tested against the rules learned in the training phase (cutoff, development test set, final test set)
TEST_SOURCE=$7
TEST_TARGET=$8
TEST_AUTO=$9
RULEKEYS=${10}
PHASE=${11}

rm -f $DBDIR/$OUTPUT_DIR/all_correct_eval.txt

if [[ ! -d $DBDIR ]]; then
        mkdir $DBDIR
fi

if [[ ! -d $ALIGNDIR ]]; then
        mkdir $ALIGNDIR
else
        rm -f $ALIGNDIR/*.*
fi

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

cp $TEST_AUTO $ALIGNDIR/$OUTPUT_DIR
cd $ALIGNDIR/$OUTPUT_DIR
TEST_AUTO_DIR=`pwd`
cd $CURPATH
TEST_AUTO_FILE=`echo $TEST_AUTO | sed -E 's/.*\/([^/*])/\1/'`
#echo "cutoff auto file: $TEST_AUTO_FILE"
TEST_AUTO=$TEST_AUTO_DIR/$TEST_AUTO_FILE
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
## echo	"perl $BINDIR/generate-iterate.pl -a $TEST_GOLD -s $TEST_SOURCE -t $TEST_TARGET -A $TEST_AUTO -r $RULEKEYS -M $DBDIR/$OUTPUT_DIR/$LEVEL/man_alignstats.txt -L $DBDIR/$OUTPUT_DIR/$LEVEL/ling_alignstats.txt -S $DBDIR/$OUTPUT_DIR/$LEVEL/srctreestats.txt -T $DBDIR/$OUTPUT_DIR/$LEVEL/trgtreestats.txt -R $DBDIR/$OUTPUT_DIR/$LEVEL/rulestats.txt"
	perl $BINDIR/generate-iterate.pl -a $TEST_GOLD -s $TEST_SOURCE -t $TEST_TARGET -A $TEST_AUTO -r $RULEKEYS -M $DBDIR/$OUTPUT_DIR/$LEVEL/man_alignstats.txt -L $DBDIR/$OUTPUT_DIR/$LEVEL/ling_alignstats.txt -S $DBDIR/$OUTPUT_DIR/$LEVEL/srctreestats.txt -T $DBDIR/$OUTPUT_DIR/$LEVEL/trgtreestats.txt -R $DBDIR/$OUTPUT_DIR/$LEVEL/rulestats.txt
## Looking for best rule that was found in training phase for this iteration level
	if [[ ! -e $DBDIR/$LEVEL/bestrule.txt ]]; then
		echo "bestrule.txt does not exist on $DBDIR/$LEVEL! Exiting..."
		exit
	fi
	let NEWLEVEL=$LEVEL+1
	if [[ ! -d $ALIGNDIR/$OUTPUT_DIR/$NEWLEVEL ]]; then
		mkdir $ALIGNDIR/$OUTPUT_DIR/$NEWLEVEL
	fi
## echo	"perl $BINDIR/apply-best-rule.pl -s $TEST_SOURCE -t $TEST_TARGET -a $TEST_AUTO -A $ALIGNDIR/$OUTPUT_DIR/$NEWLEVEL/align.xml -b $DBDIR/$LEVEL/bestrule.txt -n $DBDIR/$OUTPUT_DIR/$LEVEL/rulestats.txt -l $DBDIR/$OUTPUT_DIR/$LEVEL/ling_alignstats.txt"
	perl $BINDIR/apply-best-rule.pl -s $TEST_SOURCE -t $TEST_TARGET -a $TEST_AUTO -A $ALIGNDIR/$OUTPUT_DIR/$NEWLEVEL/align.xml -b $DBDIR/$LEVEL/bestrule.txt -n $DBDIR/$OUTPUT_DIR/$LEVEL/rulestats.txt -l $DBDIR/$OUTPUT_DIR/$LEVEL/ling_alignstats.txt
	cp $ALIGNDIR/$OUTPUT_DIR/$NEWLEVEL/align.xml $ALIGNDIR/$OUTPUT_DIR
## this align.xml becomes the new current alignment file
	cd $ALIGNDIR/$OUTPUT_DIR
	TEST_AUTO_DIR=`pwd`
	cd $CURPATH
	TEST_AUTO=$TEST_AUTO_DIR/align.xml
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

if [ "$PHASE" == "cutoff" ]; then
#    echo "perl $BINDIR/choose-cutoff.pl -l $DBDIR/cutoff_levels.txt -d $DBDIR/cutoff_scores.txt $DBDIR/$OUTPUT_DIR/all_correct_eval.txt"
    perl $BINDIR/choose-cutoff.pl -l $DBDIR/cutoff_levels.txt -d $DBDIR/cutoff_scores.txt $DBDIR/$OUTPUT_DIR/all_correct_eval.txt
fi
