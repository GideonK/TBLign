# TBLign version 0.0.2b

**NOTE**: This is old software and untested on modern Perl and Bash. It is likely that you may experience some issues. Reimplementation using Python 3.x in the not too distant future is planned.

## INSTALLATION
This software was tested using Perl 5. It does not require external libraries.

After unzipping or untarring the download file, the software should be ready for use, with pre-constructed Dutch/English treebanks available in the following directories:

./data/align/nlen/trainset/auto
./data/align/nlen/trainset/gold
./data/align/nlen/cutoff/auto
./data/align/nlen/cutoff/gold
./data/align/nlen/devtest/auto
./data/align/nlen/devtest/gold
./data/align/nlen/testset/auto
./data/align/nlen/testset/gold
./data/align/nlen/all-ep/auto
./data/align/nlen/all-ep/gold

See the respective README files in:

./data/align/nlen/trainset
./data/align/nlen/cutoff
./data/align/nlen/devtest
./data/align/nlen/testset
./data/align/nlen/all-ep

for more information.

However, if you would like to use your own data, either update the Makefile variables with the correct paths or run the training and testing scripts (see Makefile) on your own. In the future, we might work on easier ways to incorporate your data.

## About
TBLign is a tool that can be used for the alignment of phrase-structure constituents between parallel texts, indicating equivalence. The output can be used for various purposes such as training machine translation systems. It is an implementation of Eric Brill's transformation-based learning algorithm for the problem of tree-to-tree alignment and alignment error correction.

A paper, as well as a (more detailed) thesis chapter have been written on the development and experiments done using this tool by the author:

Kotzé, Gideon. 2012. Transformation-based tree-to-tree alignment. _Computational Linguistics in The Netherlands Journal_. Vol. 2. pp. 71-96. http://www.clinjournal.org/node/30

Kotzé, Gideon. 2013. _Complementary approaches to tree alignment: Combining statistical and rule-based methods_. PhD Thesis. University of Groningen. Chapter 7, pp. 113-155. http://gideonkotze.co.za/downloads/GideonThesis_Electronic.pdf

All trees should be in TIGER-XML format and all alignment files in Stockholm TreeAligner XML, also used by the statistical tree aligning toolkit Lingua-Align. See:

* Stockholm TreeAligner: https://www.ling.su.se/english/nlp/tools/stockholm-treealigner
* Lingua-Align: https://bitbucket.org/tiedemann/lingua-align/wiki/Home

A Makefile is included that performs all the operations necessary for a full training and testing phase of the software.

The basic phases are:
* **make train**: The rule-learning phase. A set of rules is applied to the output of an called "initial state annotator", which is any kind of pre-alignment phase. This can range from simple word-aligned data to the output of a tree aligner. Once the rules are applied, the output is compared to a gold standard. The rules that lead to the best scores are kept aside - this is the model, so to speak.
* **make cutoff**: Applies the learned rules to a held-out data set. The rule that, when applied, leads to the highest score in that set is selected as the last rule in the new set of rules. Any rules following that rule will not be applied in future. It therefore functions as a cutoff point. This phase is introduced in order to counteract overtraining.
* **make devtest**: Tests the set of learned rules (refined during the cutoff phase) against a development test set. This is meant to be used in the process of refining an existing model.
* **make testset**: Tests the set of learned rules (refined during the cutoff phase) against a test set. This is only meant to be used once a model has been refined and is to be tested for reporting its performance in e.g. an academic publication.
* **make traintest**: Trains and tests. Essentially, this runs 'make train', 'make cutoff' and 'make devtest' in sequence.

For training, we need to specify a number of template-like structures that we call "rule keys". They function like a combination of features where each feature, for a given node pair, can be either true or false, resulting in a binary value. During training, every node pair is assigned such a profile of true or false values according to the rule keys specified. Examples of rule key lists can be found under data/db/nlen. The optimal list that we used for our thesis experiments can be found in rulekeys.txt.

The syntax of the rule keys will be explained in more detail in the future. For those proficient in Perl, the script generate-iterate.pl provides more clues on how the rule keys are processed and the extent to which you can change the values.

We have also included a number of useful Perl scripts under ./bin/. They are:

* **remove-align-ids.pl**: Removes sentences with specific IDs in an alignment file as specified in a text file. This may be used, for example, during manual training data construction - one may find that certain sentence pairs that one has extracted from parallel treebanks are not fit for use in training data construction. This enables the user to remove them.

* **merge-STA-training.pl**: Merges two alignment sets. For example, one may wish to increase the size of the training data set by merging two separate sets from different domains.

* **get-rootcombo-freqs.pl**: Takes as input an alignment set and displays the frequencies of category label combinations of aligned nodes. This may be used to inspect the consistency of alignments. For example, there may be many NP-NP alignments and PP-PP, but NP-PP is rare. This may indicate that the NP-PP alignments are either wrong or should receive fuzzy (less confident) links.

* **get-n-align.pl**: Extracts a specified number of sentence pairs from an alignment set. This is useful if, for example, one decides to use only a set number of sentence pairs for training, or if one wishes to extract training and test sets separately from a single set (for example: 300 training data sentence pairs and 50 test data sentence pairs from a set of 350 sentence pairs).

* **count-nt-combos.pl**: Displays some basic alignment statistics of an alignment set.

* **choose-cutoff.pl**: This is used by TBLign, which uses a held-out data set to choose a cutoff point in the learned model, in order to counteract overtraining.

* **check-STA-links.pl**: This is used to check if all the alignments specified in an alignment file are valid. More specifically, all alignment IDs specified by the alignment file should point to actually existing nodes with the same IDs in the treebank files. This script checks whether this is true or not.

* **apply-best-rule.pl**: This is used by TBLign to apply the best learned rule in an iteration to a data set. In training, the updated data set is then used in the next iteration.

* **write-wordalign.pl**: This script takes as input an alignment file and writes only the word alignments to output, ignoring any constituent alignments. This may be useful, for example, if a set of parallel sentences is extracted from an already aligned parallel treebank, with the purpose of creating a gold standard or training data set, or if you would like to apply the aligner to an unaligned version of a gold standard for later comparison.

* **eval-nonterms.pl**: This script compares an automatically produced alignment set to a gold standard and calculates the precision and recall of all alignments between non-terminal nodes. Two balanced F-scores are provided as a result: One of them takes only the recall of confident links into account and the other one takes the recall of all links into account. See the above papers for an explanation.

For more information on how to use these scripts, run perldoc. For example: perldoc bin/check-STA-links.pl.

**COPYRIGHT AND LICENCE**: See LICENSE

**ACKNOWLEDGMENT**

The software was developed within the framework of the STEVIN project Parse and Corpus-Based Machine Translation (2008-2011) sponsored by the Dutch Language Union.

## SOURCES
The data sets found under the aforementioned directories are modified (annotated) versions of corpora that are freely available online. They are to be used under the same terms as the corpora that can be found at the websites where they are distributed. At the time of writing, they can be found here:

Europarl: http://www.statmt.org/europarl
OPUS: http://opus.lingfil.uu.se
DGT: https://ec.europa.eu/jrc/en/language-technologies/dgt-translation-memory

Feel free to contact the author at dr.gideon.kotze@gmail.com with any questions.

Gideon Kotzé
24 January 2014 (UPDATED 30 June 2020)
www.gideonkotze.co.za
