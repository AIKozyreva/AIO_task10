Архив программы GRAF 2.4 берётся из интернета. Скачивается архив GrafPkg.tar.gz 

Распаковываем архив:
```
tar -xzf GrafPkg.tar.gz data/FP_SNPs.txt
```

Предобработка колонок: 
```
printf '#CHROM\tPOS\tID\tallele1\tallele2\n' > FP_SNPs_10k_GB38_twoAllelsFormat.tsv
tail -n +2 FP_SNPs.txt | awk -F'\t' '$2 != 23' > tmp1.tsv
awk -F'\t' 'BEGIN{OFS="\t"} {print "chr"$2, $4, "rs"$1, $5, $6}' tmp1.tsv > tmp2.tsv
sort -k1,1V -k2,2n tmp2.tsv > tmp3.tsv
cat FP_SNPs_10k_GB38_twoAllelsFormat.tsv tmp3.tsv > final.tsv
mv final.tsv FP_SNPs_10k_GB38_twoAllelsFormat.tsv
rm tmp1.tsv tmp2.tsv tmp3.tsv
```
