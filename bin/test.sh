#!/bin/bash

CURPATH=`pwd`
BINDIR=$1
LEVELS=$2
DBDIR=$3
ALIGNDIR=$4
DEVTEST_GOLD=$5
DEVTEST_SOURCE=$6
DEVTEST_TARGET=$7
DEVTEST_AUTO=$8
TEST_GOLD=$9
TEST_SOURCE=${10}
TEST_TARGET=${11}
TEST_AUTO=${12}
RULEKEYS=${13}

## devtest set
echo "$BINDIR/./correct-test.sh $BINDIR $LEVELS $DBDIR $ALIGNDIR dev_output $DEVTEST_GOLD $DEVTEST_SOURCE $DEVTEST_TARGET $DEVTEST_AUTO $RULEKEYS"
$BINDIR/./correct-test.sh $BINDIR $LEVELS $DBDIR $ALIGNDIR dev_output $DEVTEST_GOLD $DEVTEST_SOURCE $DEVTEST_TARGET $DEVTEST_AUTO $RULEKEYS

## processing for test set
echo "perl $BINDIR/choose-cutoff.pl -l $DBDIR/cutoff_levels.txt -d $DBDIR/cutoff_scores.txt $DBDIR/dev_output/all_correct_eval.txt"
perl $BINDIR/choose-cutoff.pl -l $DBDIR/cutoff_levels.txt -d $DBDIR/cutoff_scores.txt $DBDIR/dev_output/all_correct_eval.txt

## test set
echo "$BINDIR/./correct-test.sh $BINDIR $DBDIR/cutoff_levels.txt $DBDIR $ALIGNDIR test_output_Europarl $TEST_GOLD $TEST_SOURCE $TEST_TARGET $TEST_AUTO $RULEKEYS"
$BINDIR/./correct-test.sh $BINDIR $DBDIR/cutoff_levels.txt $DBDIR $ALIGNDIR test_output_Europarl $TEST_GOLD $TEST_SOURCE $TEST_TARGET $TEST_AUTO $RULEKEYS
