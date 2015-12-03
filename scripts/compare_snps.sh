#!/bin/bash

if [ "$#" -ne 4 ]; then
	 echo "Syntax $0 <graphs_dir> <alignments_dir> <calls_dir> <out_dir>"
	 exit 1
fi

GRAPHS=$1
ALIGNMENTS=$2
VARIANTS=$3
OUT_DIR=$4
TOIL_DIR=cps_toil_dir
TOIL_OPTS="--maxCores 48 --vg_cores 8"
INDEX_OPTS="--kmer 27 --edge_max 3"
TAG_OPTS="--orig_tag ${GRAPHS}"
#OPTS="--dir_tag --only_summary"
OPTS="--dir_tag"

# output for clusteGraphs.py that we rename
CP_FILES=( "heatmap_kmer.pdf" "heatmap_log_kmer.pdf" "heatmap_vm1_kmer.pdf" "heatmap_log_vm1_kmer.pdf" "tree_kmer.dot" "tree_kmer.newick"  "tree_kmer.png" "heatmap_corg.pdf" "heatmap_log_corg.pdf" "heatmap_vm1_corg.pdf" "heatmap_log_vm1_corg.pdf" "tree_corg.dot" "tree_corg.newick"  "tree_corg.png" )

# These are the g1kvcf samples that don't exist.  right now heatmaps are just computed without
# them.  so squares compareing g1kvcf samples will be average of 5 datapoints whereas all
# other squares will ne average of 9 datapoints.  We can ensure only 5 datapoints ever used
# by uncommenting this, but it seems a bit drastic
#GLOBIGNORE="*HG00512*:*HG00514*:*HG00733*:*NA19240*"

mkdir $OUT_DIR

#for i in brca1 brca2 sma lrc_kr mhc cenx
for i in brca1 brca2 sma lrc_kir mhc
#for i in brca1
do
	 #heatmap of original
	 rm -rf ${TOIL_DIR} ; scripts/clusterGraphs.py ./${TOIL_DIR} ${GRAPHS}/*${i}*.vg ${OUT_DIR}/${i} ${TAG_OPTS} ${TOIL_OPTS} ${INDEX_OPTS} ${OPTS}

	 for j in "${CP_FILES[@]}"
	 do
		  mv ${OUT_DIR}/${i}/${j} ${OUT_DIR}/${i}/original_${i}_${j}
	 done

	 # heatmap of categories
	 #for k in sample augmented
	 for k in sample
	 do
		  # just the category
		  rm -rf ${TOIL_DIR} ; scripts/clusterGraphs.py ./${TOIL_DIR} ${VARIANTS}/${i}/*/*${k}*.vg ${OUT_DIR}/${i} ${TAG_OPTS} ${TOIL_OPTS} ${INDEX_OPTS} ${OPTS} --avg_sample --no_corg

		  for j in "${CP_FILES[@]}"
		  do
				mv ${OUT_DIR}/${i}/${j} ${OUT_DIR}/${i}/${k}_${i}_avg_${j}
		  done

		  # category and original together
		  rm -rf ${TOIL_DIR} ; scripts/clusterGraphs.py ./${TOIL_DIR} ${GRAPHS}/*${i}*.vg ${VARIANTS}/${i}/*/*${k}*.vg ${OUT_DIR}/${i} ${TAG_OPTS} ${TOIL_OPTS} ${INDEX_OPTS} ${OPTS} --avg_sample --no_corg

		  for j in "${CP_FILES[@]}"
		  do
				mv ${OUT_DIR}/${i}/${j} ${OUT_DIR}/${i}/${k}_and_original_${i}_avg_${j}
		  done
	 done

	 # tables
	 mkdir ${OUT_DIR}/${i}
	 scripts/callStats.py ${ALIGNMENTS}/${i}/*/*.gam --out_dir ${VARIANTS}  --out_sub $i  --graph_dir ${GRAPHS}
	 rm -rf ${TOIL_DIR} ; scripts/trioStats.py ./${TOIL_DIR} ${ALIGNMENTS}/${i}/*/*.gam --out_dir ${VARIANTS} --out_sub $i ${TOIL_OPTS}
	 cp ${VARIANTS}/${i}/*.tsv ${VARIANTS}/${i}/*.pdf ${OUT_DIR}/${i}
	 	 
done
