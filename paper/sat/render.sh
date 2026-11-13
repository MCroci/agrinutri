#!/usr/bin/env sh
# Render the SAT manuscript to DOCX (house style: Times New Roman, black headings, justified).
# Run from paper/sat/ after the analysis scripts; needs pandoc and ../softwarex/reference-swx.docx
# (made by `python ../softwarex/make_refdoc_swx.py` inside paper/softwarex/).
set -e
pandoc NFert_SAT.md -o NFert_SAT.docx --citeproc \
  --reference-doc=../softwarex/reference-swx.docx --resource-path=.
