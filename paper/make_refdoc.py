import sys
import re
import zipfile
import shutil
import tempfile
import os
from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.shared import RGBColor
from docx.oxml.ns import qn

src, dst = sys.argv[1], sys.argv[2]
doc = Document(src)
FONT = "Times New Roman"

# Theme-font attributes: when present, Word PREFERS these over an explicit
# w:ascii, so headings keep the theme font (Aptos/Arial) even after we set
# w:ascii="Times New Roman". They must be removed for the explicit font to win.
THEME_ATTRS = ('w:asciiTheme', 'w:hAnsiTheme', 'w:cstheme', 'w:eastAsiaTheme')

def force_font(rf):
    for a in ('w:ascii', 'w:hAnsi', 'w:cs', 'w:eastAsia'):
        rf.set(qn(a), FONT)
    for a in THEME_ATTRS:
        if rf.get(qn(a)) is not None:
            del rf.attrib[qn(a)]

# 1) Document defaults -> Times New Roman for every script slot
styles_el = doc.styles.element
dd = styles_el.find(qn('w:docDefaults'))
if dd is not None:
    rpd = dd.find(qn('w:rPrDefault'))
    if rpd is None:
        rpd = dd.makeelement(qn('w:rPrDefault'), {}); dd.insert(0, rpd)
    rpr = rpd.find(qn('w:rPr'))
    if rpr is None:
        rpr = rpd.makeelement(qn('w:rPr'), {}); rpd.append(rpr)
    rf = rpr.find(qn('w:rFonts'))
    if rf is None:
        rf = rpr.makeelement(qn('w:rFonts'), {}); rpr.insert(0, rf)
    force_font(rf)

BODY_JUSTIFY = {"Body Text", "First Paragraph", "Compact", "Normal"}

def is_heading(name):
    return name.startswith("Heading") or name in ("Title", "Subtitle")

for st in doc.styles:
    try:
        name = st.name
    except Exception:
        continue
    if name is None:
        continue
    # force Times New Roman on the style itself (overrides any built-in font)
    try:
        st.font.name = FONT
        rpr = st.element.get_or_add_rPr()
        rf = rpr.find(qn('w:rFonts'))
        if rf is None:
            rf = rpr.makeelement(qn('w:rFonts'), {}); rpr.insert(0, rf)
        force_font(rf)
    except Exception:
        pass
    # all headings/titles -> black
    if is_heading(name):
        try:
            st.font.color.rgb = RGBColor(0x00, 0x00, 0x00)
        except Exception:
            pass
    # body text -> justified (headings keep their own alignment)
    if name in BODY_JUSTIFY and name != "Normal":
        try:
            st.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
        except Exception:
            pass

doc.save(dst)

# Also rewrite the theme's major/minor Latin fonts to Times New Roman, so any run
# that still references a theme font (asciiTheme/minorHAnsi) resolves to TNR too.
def patch_theme(path):
    tmp_fd, tmp_path = tempfile.mkstemp(suffix=".docx"); os.close(tmp_fd)
    with zipfile.ZipFile(path, "r") as zin, \
         zipfile.ZipFile(tmp_path, "w", zipfile.ZIP_DEFLATED) as zout:
        for item in zin.infolist():
            data = zin.read(item.filename)
            if item.filename.startswith("word/theme/theme") and item.filename.endswith(".xml"):
                txt = data.decode("utf-8", "replace")
                # replace the first <a:latin typeface="..."> inside majorFont and minorFont
                def repl_first(block_tag, s):
                    return re.sub(
                        r'(<a:%s>\s*<a:latin[^>]*typeface=")[^"]*(")' % block_tag,
                        r'\g<1>%s\g<2>' % FONT, s, count=1, flags=re.S)
                txt = repl_first("majorFont", txt)
                txt = repl_first("minorFont", txt)
                data = txt.encode("utf-8")
            zout.writestr(item, data)
    shutil.move(tmp_path, path)

patch_theme(dst)
print("saved", dst)
