"""Collect the references cited in agrinutri_SoftwareX.md from the project .bib files.

Run from paper/softwarex/:  python make_bib.py
"""
import re

# every key cited in the manuscript, except the package itself (written below)
KEYS = sorted(set(re.findall(r"(?<![\w.])@([A-Za-z0-9_]+)", open("agrinutri_SoftwareX.md", encoding="utf-8").read()))
              - {"agrinutri2026"})

EU2115 = r"""@misc{eu2021_2115,
  author = {{European Parliament and Council of the European Union}},
  title = {Regulation ({EU}) 2021/2115 establishing rules on support for strategic plans to be drawn up by Member States under the common agricultural policy ({CAP} Strategic Plans), Article 15(4)(g)},
  year = {2021},
  howpublished = {Official Journal of the European Union, L 435, 6.12.2021},
  url = {https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:32021R2115}
}"""

NFERT = r"""@misc{agrinutri2026,
  author = {Croci, Michele and Impollonia, Giorgio and Ferrarini, Andrea and Fiorini, Andrea and Ragazzi, Manuele and Franceschi, Nicolaj and Tabaglio, Vincenzo and Amaducci, Stefano},
  title = {{agrinutri}: {N}, {P} and {K} Fertilization Following {Emilia-Romagna} {DPI} 2026. {R} package version 1.0.1},
  year = {2026},
  howpublished = {\url{https://github.com/mcroci/agrinutri}},
  doi = {10.5281/zenodo.24202414}
}"""

txt = "\n".join(open(f, encoding="utf-8").read()
                for f in ("../references.bib", "../references_review.bib", "../sat/references_extra.bib"))
txt += chr(10) + EU2115
entries = re.split(r"\n(?=@)", txt)
out = []
for k in KEYS:
    hit = [e.strip() for e in entries if re.match(r"@\w+\{" + re.escape(k) + ",", e.strip())]
    if not hit:
        raise SystemExit(f"missing reference {k}")
    out.append(hit[0])
out.append(NFERT)
with open("references.bib", "w", encoding="utf-8", newline="\n") as fh:
    fh.write("\n\n".join(out) + "\n")
print(f"{len(out)} entries")
