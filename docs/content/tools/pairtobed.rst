.. _pairtobed:

###############
*pairtobed*
###############
``bedtools pairtobed`` compares each paired-end feature in a BEDPE file (or each
pair of mates in a BAM file) to the intervals in a BED/GFF/VCF file. Unlike
``bedtools intersect``, which treats every alignment independently,
``pairtobed`` considers both ends of the pair together. For example, it can
report pairs where *both* ends overlap a feature, pairs where *neither* end
does, or pairs whose entire fragment (the "outer span" from the start of the
leftmost end to the end of the rightmost end) does not overlap any feature.

.. seealso::

    :doc:`../tools/pairtopair`
    :doc:`../tools/bamtobed`
    :doc:`../tools/intersect`

================================
Usage and option summary
================================
**Usage:**
::

  bedtools pairtobed [OPTIONS] -a <BEDPE> -b <BED/GFF/VCF>

**(or)**:
::

  pairToBed [OPTIONS] -a <BEDPE> -b <BED/GFF/VCF>


===========================    =========================================================================================================================================================
Option                         Description
===========================    =========================================================================================================================================================
**-a**                         BEDPE file A. Each feature in A is compared to B in search of overlaps. Use "stdin" if passing A with a UNIX pipe.
**-abam**                      BAM file A. Each pair of mates in A is compared to B in search of overlaps. Replaces ``-a``. Output will be BAM as well (see ``-bedpe``). Use "stdin" if passing A with a UNIX pipe. **The BAM must be grouped or sorted by read name** (see below).
**-b**                         BED/GFF/VCF file B. Use "stdin" if passing B with a UNIX pipe.
**-ubam**                      Write uncompressed BAM output. The default is to write compressed BAM output.
**-bedpe**                     When using BAM input (``-abam``), write output as BEDPE. The default is to write output in BAM when using ``-abam``.
**-ed**                        Use the BAM total edit distance (NM tag) of the two mates as the BEDPE score. The default is to use the minimum of the two mapping qualities for the pair. Requires ``-abam`` and ``-bedpe``.
**-f**                         Minimum overlap required as a fraction of A. For the end-based types this is a fraction of the end being tested; for the span-based types it is a fraction of the span. Default is 1E-9 (i.e. 1bp).
**-s**                         Require same strandedness. That is, only report hits in B that overlap an end of A on the same strand. By default, overlaps are reported without respect to strand. Not applicable with the span-based types.
**-S**                         Require different strandedness. That is, only report hits in B that overlap an end of A on the opposite strand. By default, overlaps are reported without respect to strand. Not applicable with the span-based types.
**-type**                      Approach to reporting overlaps between BEDPE and BED. Default is ``either``.

                               | **either** Report overlaps if either end of A overlaps B.
                               | **neither** Report A if neither end of A overlaps B.
                               | **both** Report overlaps if both ends of A overlap B.
                               | **xor** Report overlaps if one and only one end of A overlaps B.
                               | **notboth** Report overlaps if neither end or one and only one end of A overlaps B. That is, xor + neither.
                               | **ispan** Report overlaps between [end1, start2] of A and B.
                               | **ospan** Report overlaps between [start1, end2] of A and B.
                               | **notispan** Report A if the ispan of A doesn't overlap B.
                               | **notospan** Report A if the ospan of A doesn't overlap B.
===========================    =========================================================================================================================================================


================================
Input
================================
The A input is either a BEDPE file (``-a``) or a BAM file of paired-end
alignments (``-abam``). See the BEDPE section of :doc:`../general-usage` for a
description of the BEDPE format.

When ``-abam`` is used, each pair of mates is converted to a BEDPE feature in
which each end is the aligned portion of one mate (soft clips are excluded).
The two ends are ordered so that the leftmost end is end 1. Mates are identified
by reading the BAM two records at a time and requiring that the two records
have the same read name, so **the BAM must be grouped by read name**, e.g. with
``samtools collate`` or ``samtools sort -n``. A record whose mate is not the
next record in the file is skipped with a warning.

Because mates are paired purely by adjacency, each read name should appear
exactly twice. Secondary and supplementary alignments, or a filter that removes
only one mate of a pair, will break this assumption. Filtering to primary
alignments (e.g. ``samtools view -F 0x900``) before grouping by name is
recommended.

The B input can be any BED/GFF/VCF file.


================================
Output
================================
With ``-a`` (BEDPE input) or with ``-abam`` and ``-bedpe``:

- ``either``, ``both``, ``xor``, ``notboth``, ``ispan`` and ``ospan`` report
  the A feature followed by the B feature, once for each overlapping B feature
  (so an A feature may be reported more than once).
- ``neither``, ``notispan`` and ``notospan`` report the A feature alone, once.
- For ``notboth``, an A feature where neither end overlaps B is reported alone,
  and an A feature where exactly one end overlaps B is reported with each
  overlapping B feature.

With ``-abam`` and BAM output (the default), both mates of each pair meeting the
``-type`` criterion are written once, in their original order and without
modification.

==================================================
Pairs with unmapped or inter-chromosomal ends
==================================================
For the end-based types (``either``, ``neither``, ``both``, ``xor`` and
``notboth``), an unmapped end never overlaps B. For example, with
``-type neither`` a pair with one unmapped mate is reported if the mapped mate
does not overlap B.

The span-based types (``ispan``, ``ospan``, ``notispan`` and ``notospan``) are
only defined for pairs whose two ends are on the same chromosome. Pairs with
ends on different chromosomes, and (with ``-abam``) pairs with an unmapped
mate, are never reported by ``ispan`` or ``ospan``. For ``notispan`` and
``notospan`` they are **not reported** in BEDPE output, but **are written** in BAM
output (because, by definition, they have no span that overlaps B). If you do
not want these pairs in your BAM output, remove them first, e.g. by keeping only
properly paired alignments with ``samtools view -f 2``.


================================
Default behavior
================================
By default (``-type either``), a BEDPE feature from A is reported if *either*
end overlaps a feature in B.

::

  Chromosome  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  BEDPE/BAM A         *****.................................*****

  BED File B        ^^^^^^^^

  Result              =====.................................=====


For example:

.. code-block:: bash

  $ cat A.bedpe
  chr1  100   200   chr1  5000  5100  bedpe_example1  30  +  -
  chr1  1000  1100  chr1  2000  2100  bedpe_example2  30  +  -
  chr1  100   200   chr2  300   400   bedpe_example3  30  +  -

  $ cat B.bed
  chr1  150   250   b1
  chr1  5050  5075  b2
  chr1  1500  1600  b3

  $ bedtools pairtobed -a A.bedpe -b B.bed
  chr1  100  200  chr1  5000  5100  bedpe_example1  30  +  -  chr1  150   250   b1
  chr1  100  200  chr1  5000  5100  bedpe_example1  30  +  -  chr1  5050  5075  b2
  chr1  100  200  chr2  300   400   bedpe_example3  30  +  -  chr1  150   250   b1


====================================================
``-type neither``, ``both``, ``xor`` and ``notboth``
====================================================
These types test each end of A against B separately.

**-type neither**: Report A only if *neither* end overlaps B.

::

  Chromosome  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  BEDPE/BAM A         *****.................................*****

  BED File B    ^^^^                  ^^^^^^^^                      ^^^^^^

  Result              =====.................................=====

Note that a B feature lying entirely *between* the two ends does not prevent
A from being reported. Use ``-type notospan`` to exclude such pairs.

.. code-block:: bash

  $ bedtools pairtobed -a A.bedpe -b B.bed -type neither
  chr1  1000  1100  chr1  2000  2100  bedpe_example2  30  +  -


**-type both**: Report A only if *both* ends overlap B.

.. code-block:: bash

  $ bedtools pairtobed -a A.bedpe -b B.bed -type both
  chr1  100  200  chr1  5000  5100  bedpe_example1  30  +  -  chr1  150   250   b1
  chr1  100  200  chr1  5000  5100  bedpe_example1  30  +  -  chr1  5050  5075  b2


**-type xor**: Report A only if *exactly one* end overlaps B.

.. code-block:: bash

  $ bedtools pairtobed -a A.bedpe -b B.bed -type xor
  chr1  100  200  chr2  300  400  bedpe_example3  30  +  -  chr1  150  250  b1


**-type notboth**: Report A if *neither* end or *exactly one* end overlaps B.

.. code-block:: bash

  $ bedtools pairtobed -a A.bedpe -b B.bed -type notboth
  chr1  1000  1100  chr1  2000  2100  bedpe_example2  30  +  -
  chr1  100   200   chr2  300   400   bedpe_example3  30  +  -  chr1  150  250  b1


==================================================
``-type ispan`` and ``-type notispan``
==================================================
The "inner span" of a BEDPE feature is the interval between the two ends, from
the end of end 1 to the start of end 2 (i.e. [end1, start2]). With ``-type
ispan``, A is reported for each B feature that overlaps its inner span. With
``-type notispan``, A is reported only if no B feature overlaps its inner span.

::

  Chromosome  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  BEDPE/BAM A         *****.................................*****

  Inner span               ---------------------------------

  BED File B                       ^^^^^^^^

  ispan Result        =====.................................=====

  notispan Result

.. code-block:: bash

  $ bedtools pairtobed -a A.bedpe -b B.bed -type ispan
  chr1  100   200   chr1  5000  5100  bedpe_example1  30  +  -  chr1  150   250   b1
  chr1  100   200   chr1  5000  5100  bedpe_example1  30  +  -  chr1  1500  1600  b3
  chr1  1000  1100  chr1  2000  2100  bedpe_example2  30  +  -  chr1  1500  1600  b3


==================================================
``-type ospan`` and ``-type notospan``
==================================================
The "outer span" of a BEDPE feature runs from the start of end 1 to the end of
end 2 (i.e. [start1, end2]). For a pair of mates, this is the DNA fragment that
the pair represents. With ``-type ospan``, A is reported for each B feature that
overlaps its outer span. With ``-type notospan``, A is reported only if no B
feature overlaps its outer span.

::

  Chromosome  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  BEDPE/BAM A         *****.................................*****

  Outer span          ---------------------------------------------

  BED File B    ^^^^^^^^           ^^^^^^^^                    ^^^^^^^^

  ospan Result        =====.................................=====

  notospan Result

.. code-block:: bash

  $ bedtools pairtobed -a A.bedpe -b B.bed -type ospan
  chr1  100   200   chr1  5000  5100  bedpe_example1  30  +  -  chr1  150   250   b1
  chr1  100   200   chr1  5000  5100  bedpe_example1  30  +  -  chr1  5050  5075  b2
  chr1  100   200   chr1  5000  5100  bedpe_example1  30  +  -  chr1  1500  1600  b3
  chr1  1000  1100  chr1  2000  2100  bedpe_example2  30  +  -  chr1  1500  1600  b3


==========================================================================
Example: removing paired-end fragments that overlap a blacklist
==========================================================================
A common task is to discard every DNA fragment (read pair) that overlaps a set
of regions, such as a blacklist. Filtering reads individually (e.g. with
``bedtools intersect -v``) is not sufficient: it can keep one mate of a pair
while discarding the other, and it keeps fragments whose reads lie on either
side of a blacklisted region. Instead, use ``-type notospan``, which keeps a
pair only if its entire fragment is free of B features:

.. code-block:: bash

  # keep primary alignments of properly paired reads, grouped by read name
  $ samtools view -b -f 2 -F 0x90C reads.bam \
      | samtools collate -O - tmp > reads.byname.bam

  # keep the pairs whose fragments do not overlap the blacklist
  $ bedtools pairtobed -abam reads.byname.bam -b blacklist.bed -type notospan \
      > reads.filtered.bam

The ``samtools view -f 2`` filter removes pairs with an unmapped mate and pairs
on different chromosomes, which ``-type notospan`` would otherwise write to the
BAM output without testing (see above).
