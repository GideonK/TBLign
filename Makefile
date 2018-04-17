TBL=$(HOME)/TBL
BINDIR=$(TBL)/bin
BASE_ALIGNDIR=$(TBL)/data/align/nlen
BASE_DBDIR=$(TBL)/data/db/nlen

ALIGNDIR=$(BASE_ALIGNDIR)/experiments
DBDIR=$(BASE_DBDIR)/experiments
TRAINDIR=$(BASE_ALIGNDIR)/trainset
CUTOFFDIR=$(BASE_ALIGNDIR)/cutoff
DEVTESTDIR=$(BASE_ALIGNDIR)/devtest
TESTDIR=$(BASE_ALIGNDIR)/testset

RULEKEYS=$(BASE_DBDIR)/rulekeys.txt
LEVEL=0

## training data set
TRAIN_GOLD=$(TRAINDIR)/gold/SEDE.250train.only-nts.sta.xml
TRAIN_AUTO=$(TRAINDIR)/auto/SEDE.250train.withalign.sta.xml
TRAIN_SOURCE=$(TRAINDIR)/gold/SEDE.250.s.tiger.xml
TRAIN_TARGET=$(TRAINDIR)/gold/SEDE.250.t.tiger.xml

## cutoff set
CUTOFF_DIRNAME=cutoff_output
CUTOFF_GOLD=$(CUTOFFDIR)/gold/SEDE.100cutoff.only-nts.sta.xml
CUTOFF_AUTO=$(CUTOFFDIR)/auto/SEDE.100cutoff.withalign.sta.xml
CUTOFF_SOURCE=$(CUTOFFDIR)/gold/SEDE.100.s.tiger.xml
CUTOFF_TARGET=$(CUTOFFDIR)/gold/SEDE.100.t.tiger.xml

## development test set
DEVTEST_DIRNAME=test_output_mixed
DEVTEST_GOLD=$(DEVTESTDIR)/gold/SEDE.250devtest.only-nts.sta.xml
DEVTEST_AUTO=$(DEVTESTDIR)/auto/SEDE.250devtest.withalign.sta.xml
DEVTEST_SOURCE=$(DEVTESTDIR)/gold/SEDE.250.s.tiger.xml
DEVTEST_TARGET=$(DEVTESTDIR)/gold/SEDE.250.t.tiger.xml

## test set
TEST_DIRNAME=test_output_Europarl
TEST_GOLD=$(TESTDIR)/gold/ep-96-07-17.200test.only-nts.sta.xml
TEST_AUTO=$(TESTDIR)/auto/ep-96-07-17.200test.withalign.sta.xml
TEST_SOURCE=$(TESTDIR)/gold/ep-96-07-17.200.s.tiger.xml
TEST_TARGET=$(TESTDIR)/gold/ep-96-07-17.200.t.tiger.xml

## statistics files - end users should not worry about this
TRAIN_MAN_ALIGNSTATSFILE=$(DBDIR)/$(LEVEL)/train_man_alignstats.txt
TEST_MAN_ALIGNSTATSFILE=$(DBDIR)/$(LEVEL)/test_man_alignstats.txt
TRAIN_LINGUA_ALIGNSTATSFILE=$(DBDIR)/$(LEVEL)/train_ling_alignstats.txt
TEST_LINGUA_ALIGNSTATSFILE=$(DBDIR)/$(LEVEL)/test_ling_alignstats.txt
TRAIN_SRCTREESTATSFILE=$(DBDIR)/$(LEVEL)/train_srctreestats.txt
TEST_SRCTREESTATSFILE=$(DBDIR)/$(LEVEL)/test_srctreestats.txt
TRAIN_TRGTREESTATSFILE=$(DBDIR)/$(LEVEL)/train_trgtreestats.txt
TEST_TRGTREESTATSFILE=$(DBDIR)/$(LEVEL)/test_trgtreestats.txt
TRAIN_RULESTATSFILE=$(DBDIR)/$(LEVEL)/train_rulestats.txt
TEST_RULESTATSFILE=$(DBDIR)/$(LEVEL)/test_rulestats.txt
BESTRULEFILE=$(DBDIR)/$(LEVEL)/bestrule.txt
FOUNDRULESFILE=$DBDIR/$LEVEL/foundrules.txt

## WARNING! This removes ALL files (database and alignment files) that have been created during training and testing.
clean:
	rm -rf $(ALIGNDIR)/*
	rm -rf $(DBDIR)/*

## This is to run a full training and testing phase in one go. Warning: Might take several hours!
traintest:
	make train
	make cutoff
	make devtest ## We assume that training and testing phases will only involve the devtest set, and that the test set will only be run occasionally to test an already refined model.

## This is to be run on the final test set. Use sparingly!
testset:
	$(BINDIR)/./test.sh $(BINDIR) $(DBDIR)/cutoff_levels.txt \
	$(DBDIR) $(ALIGNDIR) test_output $(TEST_GOLD) \
	$(TEST_SOURCE) $(TEST_TARGET) $(TEST_AUTO) $(RULEKEYS)

devtest:
	$(BINDIR)/./test.sh $(BINDIR) $(DBDIR)/cutoff_levels.txt \
	$(DBDIR) $(ALIGNDIR) devtest_output $(DEVTEST_GOLD) \
	$(DEVTEST_SOURCE) $(DEVTEST_TARGET) $(DEVTEST_AUTO) $(RULEKEYS)

cutoff:
	$(BINDIR)/./test.sh $(BINDIR) $(DBDIR)/levels.txt $(DBDIR) \
	$(ALIGNDIR) cutoff_output $(CUTOFF_GOLD) $(CUTOFF_SOURCE) \
	$(CUTOFF_TARGET) $(CUTOFF_AUTO) $(RULEKEYS) cutoff

train:
	$(BINDIR)/./train.sh $(BINDIR) $(ALIGNDIR) $(DBDIR) $(LEVEL) \
	$(TRAIN_GOLD) $(TRAIN_SOURCE) $(TRAIN_TARGET) $(RULEKEYS) \
	$(TRAIN_AUTO) $(DBDIR)/rules.csv
