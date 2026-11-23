"""Reference DOCX for the SoftwareX manuscript.

Starts from the house style (../reference-agrinutri.docx: Times New Roman, black
headings, justified body) and sets the code styles back to a monospaced font,
so R snippets are readable. Run from paper/softwarex/:
    python make_refdoc_swx.py
"""
from docx import Document
from docx.oxml.ns import qn
from docx.shared import Pt

doc = Document("../reference-agrinutri.docx")
for name in ("Source Code", "Verbatim Char"):
    try:
        st = doc.styles[name]
    except KeyError:
        continue
    st.font.name = "Consolas"
    st.font.size = Pt(9)
    rpr = st.element.get_or_add_rPr()
    rfonts = rpr.find(qn("w:rFonts"))
    if rfonts is None:
        rfonts = rpr.makeelement(qn("w:rFonts"), {})
        rpr.append(rfonts)
    for attr in ("w:ascii", "w:hAnsi", "w:cs", "w:eastAsia"):
        rfonts.set(qn(attr), "Consolas")
    if name == "Source Code":
        st.paragraph_format.alignment = 0  # left, not justified
# explicit A4 page with 2.5 cm margins: pandoc reads the text width (16 cm) from here to size figures
from docx.shared import Cm
for sec in doc.sections:
    sec.page_width, sec.page_height = Cm(21.0), Cm(29.7)
    sec.left_margin = sec.right_margin = sec.top_margin = sec.bottom_margin = Cm(2.5)
doc.save("reference-swx.docx")
print("reference-swx.docx written")
