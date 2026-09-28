set -e;
BT=${BT-../../bin/bedtools}
htsutil=${htsutil-../htsutil}

FAILURES=0;

check()
{
	if diff $1 $2; then
    	echo ok
	else
		FAILURES=$(expr $FAILURES + 1);
		echo fail
	fi
}

# cat a.bedpe
# chr1	100	200	chr1	5000	5100	bedpe_example1	30	+	-
# chr1	1000	1100	chr1	2000	2100	bedpe_example2	30	+	-
# chr1	100	200	chr2	300	400	bedpe_example3	30	+	-
#
# cat b.bed
# chr1	150	250	b1
# chr1	5050	5075	b2
# chr1	1500	1600	b3

###########################################################
#  Test default (-type either)
###########################################################
echo -e "    pairtobed.t1...\c"
echo \
"chr1	100	200	chr1	5000	5100	bedpe_example1	30	+	-	chr1	150	250	b1
chr1	100	200	chr1	5000	5100	bedpe_example1	30	+	-	chr1	5050	5075	b2
chr1	100	200	chr2	300	400	bedpe_example3	30	+	-	chr1	150	250	b1" > exp
$BT pairtobed -a a.bedpe -b b.bed > obs
check obs exp
rm obs exp

###########################################################
#  Test -type neither
###########################################################
echo -e "    pairtobed.t2...\c"
echo \
"chr1	1000	1100	chr1	2000	2100	bedpe_example2	30	+	-" > exp
$BT pairtobed -a a.bedpe -b b.bed -type neither > obs
check obs exp
rm obs exp

###########################################################
#  Test -type ospan
###########################################################
echo -e "    pairtobed.t3...\c"
echo \
"chr1	100	200	chr1	5000	5100	bedpe_example1	30	+	-	chr1	150	250	b1
chr1	100	200	chr1	5000	5100	bedpe_example1	30	+	-	chr1	5050	5075	b2
chr1	100	200	chr1	5000	5100	bedpe_example1	30	+	-	chr1	1500	1600	b3
chr1	1000	1100	chr1	2000	2100	bedpe_example2	30	+	-	chr1	1500	1600	b3" > exp
$BT pairtobed -a a.bedpe -b b.bed -type ospan > obs
check obs exp
rm obs exp

###########################################################
###########################################################
#                       BAM files                         #
###########################################################
###########################################################
$htsutil samtobam mates.sam mates.bam

# mates.sam is grouped by name. p1's fragment spans blacklist.bed
# (neither mate overlaps it), "orphan" has no mate, and p4 has a
# trailing supplementary record at the end of the file.

###########################################################
#  Test that a pair following a record without an adjacent
#  mate is not dropped, and that a trailing extra record
#  is not paired with a stale mate (BEDPE output)
###########################################################
echo -e "    pairtobed.t4...\c"
echo \
"chr1	1000	1050	chr1	1200	1250	p2	60	+	-
chr1	3000	3050	chr1	3200	3250	p3	60	+	-
chr1	4000	4050	chr1	4200	4250	p4	60	+	-" > exp
$BT pairtobed -abam mates.bam -b blacklist.bed -type notospan -bedpe 2> /dev/null > obs
check obs exp
rm obs exp

###########################################################
#  Same as t4, with BAM output
###########################################################
echo -e "    pairtobed.t5...\c"
echo \
"chr1	1000	1050	p2/1	60	+
chr1	1200	1250	p2/2	60	-
chr1	3000	3050	p3/1	60	+
chr1	3200	3250	p3/2	60	-
chr1	4000	4050	p4/1	60	+
chr1	4200	4250	p4/2	60	-" > exp
$BT pairtobed -abam mates.bam -b blacklist.bed -type notospan 2> /dev/null \
    | $BT bamtobed -i - > obs
check obs exp
rm obs exp

###########################################################
#  Test that records without an adjacent mate are reported
###########################################################
echo -e "    pairtobed.t6...\c"
echo \
"*****WARNING: Query orphan is marked as paired, but it's mate does not occur next to it in your BAM file.  Skipping. 
*****WARNING: Query p4 is marked as paired, but it's mate does not occur next to it in your BAM file.  Skipping. " > exp
$BT pairtobed -abam mates.bam -b blacklist.bed -type notospan -bedpe 2> obs > /dev/null
check obs exp
rm obs exp

rm mates.bam

[[ $FAILURES -eq 0 ]] || exit 1;
