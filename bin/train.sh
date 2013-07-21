#!/bin/bash

CURPATH=`pwd`
BINDIR=$1
ALIGNDIR=$2
DBDIR=$3
rm -f $DBDIR/levels.txt
rm -f $DBDIR/all_eval.txt
LEVEL=$4
let NEWLEVEL=$LEVEL+1
TRAIN_ALIGN=$5
TRAIN_SOURCE=$6
TRAIN_TARGET=$7
RULEKEYS=$8
TRAIN_LINGUA=$9
RULES_LIST=${10}
END=0
BEGINLEVEL=$LEVEL

rm -f $RULES_LIST

date

echo "Level	Rule number	Rule	Rule type	Times rule applied	Correct	Correct-Incorrect" >> $RULES_LIST

#echo "DATADIR: $DATADIR"
#echo "NEWLEVEL: $NEWLEVEL"
#echo "DATADIR/NEWLEVEL: $DATADIR/$NEWLEVEL"
#echo "ALIGNDIR: $ALIGNDIR"

if [[ ! -d "$ALIGNDIR" ]]; then
	mkdir $ALIGNDIR
	if [[ ! -d "$ALIGNDIR/$LEVEL" ]]; then
		mkdir $ALIGNDIR/$LEVEL
	fi
fi
#cp $TRAIN_ALIGN $ALIGNDIR/$LEVEL
#cp $TRAIN_LINGUA $ALIGNDIR/$LEVEL
#cp $TRAIN_SOURCE $ALIGNDIR/$LEVEL
#cp $TRAIN_TARGET $ALIGNDIR/$LEVEL

if [[ ! -d "$DBDIR" ]]; then
        mkdir $DBDIR
        if [[ ! -d "$DBDIR/$LEVEL" ]]; then
                mkdir $DBDIR/$LEVEL
        fi
fi

echo "Precision (all)	Recall (all)	Recall (good)	Recall (fuzzy)	F-score (P_all & R_all)	F-score (P_all & R_good)" >> $DBDIR/all_eval.txt

while [ $END -eq 0 ]
do
  let NEWLEVEL=$LEVEL+1
TRAIN_MAN_ALIGNSTATSFILE=$DBDIR/$LEVEL/train_man_alignstats.txt
TEST_MAN_ALIGNSTATSFILE=$DBDIR/$LEVEL/test_man_alignstats.txt
TRAIN_LINGUA_ALIGNSTATSFILE=$DBDIR/$LEVEL/train_ling_alignstats.txt
TEST_LINGUA_ALIGNSTATSFILE=$DBDIR/$LEVEL/test_ling_alignstats.txt
TRAIN_SRCTREESTATSFILE=$DBDIR/$LEVEL/train_srctreestats.txt
TEST_SRCTREESTATSFILE=$DBDIR/$LEVEL/test_srctreestats.txt
TRAIN_TRGTREESTATSFILE=$DBDIR/$LEVEL/train_trgtreestats.txt
TEST_TRGTREESTATSFILE=$DBDIR/$LEVEL/test_trgtreestats.txt
TRAIN_RULESTATSFILE=$DBDIR/$LEVEL/train_rulestats.txt
TEST_RULESTATSFILE=$DBDIR/$LEVEL/test_rulestats.txt
FOUNDRULESFILE=$DBDIR/$LEVEL/foundrules.txt
BESTRULEFILE=$DBDIR/$LEVEL/bestrule.txt

echo "Generating statistics and finding best rule..."

  if [[ ! -s "$DBDIR/$LEVEL/DONE" ]]; then
	rm -f $DBDIR/$LEVEL/*.*
	rm -f $DBDIR/$LEVEL/DONE
  fi
#  echo "perl $BINDIR/generate-iterate.pl -a $TRAIN_ALIGN -s $TRAIN_SOURCE -t $TRAIN_TARGET -A $TRAIN_LINGUA -r $RULEKEYS -M $TRAIN_MAN_ALIGNSTATSFILE -L $TRAIN_LINGUA_ALIGNSTATSFILE -S $TRAIN_SRCTREESTATSFILE -T $TRAIN_TRGTREESTATSFILE -R $TRAIN_RULESTATSFILE -u $FOUNDRULESFILE -b $BESTRULEFILE -g"
  perl $BINDIR/generate-iterate.pl -a $TRAIN_ALIGN -s $TRAIN_SOURCE -t $TRAIN_TARGET -A $TRAIN_LINGUA -r $RULEKEYS -M $TRAIN_MAN_ALIGNSTATSFILE -L $TRAIN_LINGUA_ALIGNSTATSFILE -S $TRAIN_SRCTREESTATSFILE -T $TRAIN_TRGTREESTATSFILE -R $TRAIN_RULESTATSFILE -u $FOUNDRULESFILE -b $BESTRULEFILE -g
  echo "DONE" >> $DBDIR/$LEVEL/DONE
  if [[ -s $BESTRULEFILE ]]; then
	cat $BESTRULEFILE >> $RULES_LIST
      if [[ ! -d $ALIGNDIR/$NEWLEVEL ]]; then
	  echo "Creating $ALIGNDIR/$NEWLEVEL"
	  mkdir $ALIGNDIR/$NEWLEVEL
      fi
      if [[ ! -d $DBDIR/$NEWLEVEL ]]; then
          echo "Creating $DBDIR/$NEWLEVEL"
          mkdir $DBDIR/$NEWLEVEL
      fi
      echo "Applying best rule and writing new alignment file to $ALIGNDIR/$NEWLEVEL/align.xml"
#  echo "perl $BINDIR/apply-best-rule.pl -s $TRAIN_SOURCE -t $TRAIN_TARGET -a $TRAIN_LINGUA -A $ALIGNDIR/$NEWLEVEL/align.xml -b $BESTRULEFILE -n $TRAIN_RULESTATSFILE -l $TRAIN_LINGUA_ALIGNSTATSFILE"
  perl $BINDIR/apply-best-rule.pl -s $TRAIN_SOURCE -t $TRAIN_TARGET -a $TRAIN_LINGUA -A $ALIGNDIR/$NEWLEVEL/align.xml -b $BESTRULEFILE -n $TRAIN_RULESTATSFILE -l $TRAIN_LINGUA_ALIGNSTATSFILE

if [[ -s $BESTRULEFILE ]]; then
	echo "$LEVEL" >> $DBDIR/levels.txt
	rm -f $DBDIR/$NEWLEVEL/eval.txt
      echo "Evaluation score after iteration $LEVEL" > $DBDIR/$NEWLEVEL/eval.txt
      echo "Evaluating new alignment file and writing it to $DBDIR/$NEWLEVEL/eval.txt"
      perl $BINDIR/eval-nonterms.pl -a $ALIGNDIR/$NEWLEVEL/align.xml -g $TRAIN_ALIGN >> $DBDIR/$NEWLEVEL/eval.txt
      echo "Evaluation output:"
      tail -n +2 $DBDIR/$NEWLEVEL/eval.txt
      echo "Writing these last results to $DBDIR/all_eval.txt"
      tail -n +2 $DBDIR/$NEWLEVEL/eval.txt >> $DBDIR/all_eval.txt
      TRAIN_LINGUA=$ALIGNDIR/$NEWLEVEL/align.xml
      echo "TRAIN_LINGUA is now updated to be $ALIGNDIR/$NEWLEVEL/align.xml"
      let LEVEL=$LEVEL+1
      echo "LEVEL is now increased to be $LEVEL"
      if [[ ! -d $DBDIR/$LEVEL ]]; then
	  echo "Creating $DBDIR/$LEVEL"
	  mkdir $DBDIR/$LEVEL
      fi
      if [[ ! -d $ALIGNDIR/$LEVEL ]]; then
	  echo "Creating $ALIGNDIR/$LEVEL"
          mkdir $ALIGNDIR/$LEVEL
      fi
  else
	echo "No best rule exists! Training is complete."
	END=1
  fi

  else
      echo "No best rule exists! Training is complete."
      END=1
  fi
done

date

