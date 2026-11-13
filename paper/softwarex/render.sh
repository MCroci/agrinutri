#!/usr/bin/env sh
# Render the SoftwareX manuscript to DOCX (figures as PNG). Run from paper/softwarex/.
set -e
python make_refdoc_swx.py
sed 's/\(figures\/fig[0-9]_[a-z_]*\)\.pdf/\1.png/g' agrinutri_SoftwareX.md > _docx_src.md
pandoc _docx_src.md -o agrinutri_SoftwareX.docx --citeproc --bibliography=references.bib \
  --reference-doc=reference-swx.docx --resource-path=.
rm _docx_src.md
