#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
restore_ref_alt.py (простая версия, без классов)

Определяет, какой из двух аллелей (allele1, allele2) является референсным
(REF), а какой альтернативным (ALT), сверяясь с нуклеотидом референсного
генома в позиции варианта (pysam.FastaFile).

Вход  (TSV): #CHROM<TAB>POS<TAB>ID<TAB>allele1<TAB>allele2
Выход (TSV): #CHROM<TAB>POS<TAB>ID<TAB>REF<TAB>ALT
"""
import argparse
import os
import sys
from datetime import datetime

try:
    import pysam
except ImportError:
    print("ОШИБКА: не найдена библиотека pysam. Установите: pip3 install pysam")
    sys.exit(1)

VERSION = "1.0"
EXPECTED_HEADER = ["#CHROM", "POS", "ID", "allele1", "allele2"]
OUTPUT_HEADER = ["#CHROM", "POS", "ID", "REF", "ALT"]
NUCLEOTIDES = ["A", "C", "G", "T"]
COMPLEMENT = {"A": "T", "T": "A", "C": "G", "G": "C"}

LOG_PATH = None      
OPENED = {}          
MISSING = []         

def log(level, *parts):
    line = " ".join(str(p) for p in parts)                
    stamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")  
    text = stamp + " [" + level + "] " + line
    print(text, file=sys.stderr)                          
    if LOG_PATH:
        with open(LOG_PATH, "a", encoding="utf-8") as f:  
            f.write(text + "\n")

def parse_args():
    parser = argparse.ArgumentParser(
        prog="restore_ref_alt.py",
        description=(
            "Преобразует файл формата "
            "'#CHROM<TAB>POS<TAB>ID<TAB>allele1<TAB>allele2' в формат "
            "'#CHROM<TAB>POS<TAB>ID<TAB>REF<TAB>ALT': для каждого варианта "
            "берёт нуклеотид референсного генома (pysam.FastaFile) в позиции "
            "POS (1-based) и определяет, какой из аллелей референсный. "
            "Если ни один аллель не совпал, проверяет комплементарную цепь. "
            "Неопознанные варианты не попадают в выходной файл, а пишутся "
            "в лог."),
        epilog=(
            "Пример:\n"
            "  restore_ref_alt.py \\\n"
            "    -i FP_SNPs_10k_GB38_twoAllelsFormat.tsv \\\n"
            "    -o FP_SNPs_10k_GB38_refAlt.tsv \\\n"
            "    -r /ref/GRCh38.d1.vd1_mainChr/sepChrs/ \\\n"
            "    -l restore_ref_alt.log"),
        formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("-i", "--input", required=True,
                        help="входной TSV-файл (#CHROM POS ID allele1 allele2)")
    parser.add_argument("-o", "--output", required=True,
                        help="выходной TSV-файл (#CHROM POS ID REF ALT)")
    parser.add_argument("-r", "--ref-dir",
                        default="/ref/GRCh38.d1.vd1_mainChr/sepChrs/",
                        help="папка с файлами chrN.fa и chrN.fa.fai "
                             "(по умолчанию: %(default)s)")
    parser.add_argument("-l", "--log", default=None,
                        help="лог-файл (по умолчанию: <output>.log)")
    parser.add_argument("-v", "--version", action="version",
                        version="%(prog)s " + VERSION)
    return parser.parse_args()

def get_base(ref_dir, chrom, pos):
    if chrom in MISSING:
        return None
    if chrom not in OPENED:
        fa = os.path.join(ref_dir, chrom + ".fa")
        if not os.path.isfile(fa):
            log("WARNING", "Нет файла хромосомы:", fa,
                "- варианты с этой хромосомой не распознаются")
            MISSING.append(chrom)
            return None
        try:
            OPENED[chrom] = pysam.FastaFile(fa)
        except Exception as e:
            log("WARNING", "Не удалось открыть файл:", fa, "- причина:", e)
            MISSING.append(chrom)
            return None
        log("INFO", "Открыт файл референса:", fa)
    fasta = OPENED[chrom]
    if pos > fasta.get_reference_length(chrom):
        return None
    return fasta.fetch(chrom, pos - 1, pos).upper()

args = parse_args()
LOG_PATH = args.log if args.log else args.output + ".log"

try:
    open(LOG_PATH, "w", encoding="utf-8").close()   
except OSError as e:
    print("ОШИБКА: не удалось создать лог-файл", LOG_PATH, "-", e)
    sys.exit(1)

log("INFO", "Запуск restore_ref_alt.py версии", VERSION)
log("INFO", "Входной файл: ", args.input)
log("INFO", "Выходной файл:", args.output)
log("INFO", "Референс:     ", args.ref_dir)
log("INFO", "Лог-файл:     ", LOG_PATH)

if not os.path.isfile(args.input):
    log("ERROR", "Входной файл не найден:", args.input)
    sys.exit(1)
if os.path.getsize(args.input) == 0:
    log("ERROR", "Входной файл пустой:", args.input)
    sys.exit(1)
if not os.path.isdir(args.ref_dir):
    log("ERROR", "Папка с референсным геномом не найдена:", args.ref_dir)
    sys.exit(1)

total = 0          # корректных вариантов прочитано
n_allele1 = 0      # REF = allele1
n_allele2 = 0      # REF = allele2
n_flip1 = 0        # REF найден на обратной цепи, по allele1
n_flip2 = 0        # REF найден на обратной цепи, по allele2
n_unresolved = 0   # REF определить не удалось
n_bad = 0          # строки неверного формата

try:
    fin = open(args.input, "r", encoding="utf-8", newline=None)
except OSError as e:
    log("ERROR", "Не удалось открыть входной файл:", e)
    sys.exit(1)

try:
    fout = open(args.output, "w", encoding="utf-8", newline="\n")
except OSError as e:
    log("ERROR", "Не удалось создать выходной файл:", e)
    sys.exit(1)

header = fin.readline().rstrip("\r\n").split("\t")
if header != EXPECTED_HEADER:
    log("ERROR", "Неверный заголовок входного файла.",
        "Ожидалось:", "\\t".join(EXPECTED_HEADER),
        "Получено:", "\\t".join(header))
    sys.exit(1)
log("INFO", "Заголовок входного файла корректен")

fout.write("\t".join(OUTPUT_HEADER) + "\n")
log("INFO", "Начата обработка вариантов")


line_no = 1   
for line in fin:
    line_no += 1
    line = line.rstrip("\r\n")
    if line.strip() == "":
        continue                      

    fields = line.split("\t")

    if len(fields) != 5:
        n_bad += 1
        log("WARNING", "Строка", line_no, ": ожидалось 5 колонок, найдено",
            len(fields), "- строка пропущена")
        continue

    chrom, pos, vid, a1, a2 = fields
    a1 = a1.upper()
    a2 = a2.upper()

    if not pos.isdigit() or int(pos) < 1:
        n_bad += 1
        log("WARNING", "Строка", line_no, ": POS =", pos,
            "не положительное целое число - строка пропущена")
        continue
    if a1 not in NUCLEOTIDES or a2 not in NUCLEOTIDES:
        n_bad += 1
        log("WARNING", "Строка", line_no, ": аллели", a1, "и", a2,
            "должны быть одиночными A/C/G/T - строка пропущена")
        continue

    pos = int(pos)
    total += 1

    base = get_base(args.ref_dir, chrom, pos)

    ref_allele = None
    alt_allele = None
    reason = ""

    if base is None:
        reason = "нет такой хромосомы или позиции в референсе"
    elif base == a1:
        ref_allele, alt_allele = a1, a2
        n_allele1 += 1
    elif base == a2:
        ref_allele, alt_allele = a2, a1
        n_allele2 += 1
    elif base == COMPLEMENT[a1]:
        # аллели записаны для обратной цепи: берём комплементарные
        ref_allele, alt_allele = COMPLEMENT[a1], COMPLEMENT[a2]
        n_flip1 += 1
        log("WARNING", "Строка", line_no, ":", vid, chrom + ":" + str(pos),
            a1 + "/" + a2, "- в референсе", base,
            "- взяты комплементарные аллели: REF=" + ref_allele,
            "ALT=" + alt_allele)
    elif base == COMPLEMENT[a2]:
        ref_allele, alt_allele = COMPLEMENT[a2], COMPLEMENT[a1]
        n_flip2 += 1
        log("WARNING", "Строка", line_no, ":", vid, chrom + ":" + str(pos),
            a1 + "/" + a2, "- в референсе", base,
            "- взяты комплементарные аллели: REF=" + ref_allele,
            "ALT=" + alt_allele)
    else:
        reason = "в референсе " + base + ", ни один аллель не подходит"

    if ref_allele is None:
        n_unresolved += 1
        log("WARNING", "Строка", line_no, ":", vid, chrom + ":" + str(pos),
            a1 + "/" + a2, "- не распознан:", reason)
        continue

    fout.write("\t".join([chrom, str(pos), vid, ref_allele, alt_allele]) + "\n")

    if total % 2000 == 0:
        log("INFO", "Обработано вариантов:", total)

fin.close()
fout.close()
for fasta in OPENED.values():
    fasta.close()

log("INFO", "Обработка завершена")
log("INFO", "Всего корректных вариантов прочитано:   ", total)
log("INFO", "  REF = allele1:                         ", n_allele1)
log("INFO", "  REF = allele2:                         ", n_allele2)
log("INFO", "  REF на обратной цепи (по allele1):     ", n_flip1)
log("INFO", "  REF на обратной цепи (по allele2):     ", n_flip2)
log("INFO", "  не удалось определить REF:             ", n_unresolved)
log("INFO", "Строк с неверным форматом (пропущено):   ", n_bad)
log("INFO", "Записано в выходной файл:                ", total - n_unresolved)


if total == 0:
    log("ERROR", "Во входном файле нет ни одного корректного варианта")
    sys.exit(1)
log("INFO", "Готово")
