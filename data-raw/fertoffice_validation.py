"""Drive the Fert_Office v1.26 spreadsheet to build a validation set for NFert.

Generates random field scenarios, writes each one into the input cells of a
copy of Fert_Office_v1._26.xlsm through Excel automation (Windows + Excel
required, macros disabled), recalculates the workbook and records the balance
terms of the "Bilancio" sheet. The output CSV is the fixture used by
tests/testthat/test-fertoffice-validation.R.

Usage (from the package root):
    python data-raw/fertoffice_validation.py <Fert_Office.xlsm> <out.csv> [n] [seed]

The workbook is opened read-only from a temporary copy and never saved.
"""
import csv
import os
import random
import shutil
import sys
import tempfile

import win32com.client

# (Fert_Office "ordinato" id = NFert uptake_table$id, crop group, target
#  ID_Fa_D phase, yield range in t/ha)
CROPS = [
    (50, 2, 13, (4.0, 8.0)),     # Durum wheat (whole plant)
    (55, 2, 13, (5.0, 9.0)),     # Soft wheat FF - strong (grain)
    (69, 2, 13, (4.0, 8.0)),     # Barley (grain)
    (42, 2, 14, (2.5, 4.5)),     # Rapeseed
    (63, 2, 12, (9.0, 15.0)),    # Grain maize 500-700 (grain)
    (68, 2, 11, (45.0, 70.0)),   # Silage maize (class 700)
    (47, 2, 10, (2.5, 4.5)),     # Sunflower (achenes)
    (80, 2, 11, (3.0, 5.0)),     # Soybean (grain)
    (38, 2, 12, (50.0, 80.0)),   # Sugar beet (roots)
    (165, 4, 11, (30.0, 55.0)),  # Potato
    (171, 4, 11, (60.0, 100.0)), # Processing tomato (medium yield)
    (17, 1, 4, (25.0, 50.0)),    # Apple, full production
    (27, 1, 4, (20.0, 35.0)),    # Peach, full production
]
GROUP_OFFSET = {1: 0, 2: 33, 3: 90, 4: 120, 5: 196, 6: 219}

OUT_CELLS = {
    "fo_A": ("Bilancio", "H15"), "fo_C": ("Bilancio", "H16"),
    "fo_D": ("Bilancio", "H19"), "fo_B": ("Bilancio", "H25"),
    "fo_E": ("Bilancio", "H26"), "fo_F": ("Bilancio", "H27"),
    "fo_G": ("Bilancio", "H28"), "fo_N": ("Bilancio", "H31"),
    "fo_P_A": ("Bilancio", "I15"), "fo_P_B1": ("Bilancio", "I20"),
    "fo_P_B2": ("Bilancio", "I25"), "fo_P2O5": ("Bilancio", "I31"),
    "fo_K_A": ("Bilancio", "J15"), "fo_K_H": ("Bilancio", "J16"),
    "fo_K_F1": ("Bilancio", "J20"), "fo_K_F2": ("Bilancio", "J25"),
    "fo_K2O": ("Bilancio", "J31"),
    "fo_N_rep": ("Valori da riportare", "E7"),
    "fo_P2O5_rep": ("Valori da riportare", "F7"),
    "fo_K2O_rep": ("Valori da riportare", "G7"),
    "fo_Ca": ("Bilancio", "H17"), "fo_Cb": ("Bilancio", "H18"),
    "fo_crop": ("Coltura", "D238"), "fo_phase": ("Cicli_Fase", "F30"),
    "fo_C_tempo": ("Codici", "O2"), "fo_id_rag": ("Codici", "S2"),
    "fo_texture": ("Suolo", "B19"),
}


def scenario(rng):
    crop_id, group, phase, (y0, y1) = rng.choice(CROPS)
    while True:
        sand = round(rng.uniform(5, 75), 1)
        clay = round(rng.uniform(5, 60), 1)
        if sand + clay <= 95:
            break
    ca_tot = round(rng.uniform(0, 35), 1)
    return {
        "crop_id": crop_id, "group": group, "phase": phase,
        "yield": round(rng.uniform(y0, y1), 1),
        "sand": sand, "clay": clay,
        "Ntot": round(rng.uniform(0.6, 2.5), 2),
        "SOM": round(rng.uniform(0.8, 4.0), 2),
        "pH": round(rng.uniform(5.5, 8.6), 1),
        "CaCO3_tot": ca_tot,
        "CaCO3_att": round(rng.uniform(0, min(ca_tot, 12)), 1),
        "olsen_P2O5": round(rng.uniform(5, 90), 1),
        "K2O": round(rng.uniform(40, 320), 0),
        "winter_rain": round(rng.uniform(40, 420), 0),
        "feb_rain": round(rng.uniform(0, 130), 0),
        "id_dre": rng.randint(1, 3),
        "id_pre": rng.randint(1, 21),
        "id_mo": rng.randint(1, 4),
        "id_fre": rng.randint(1, 4),
        "org_prev_N": round(rng.choice([0, 0, rng.uniform(20, 250)]), 0),
        "id_ubi": rng.randint(1, 3),
        "no_till": rng.random() < 0.2,
    }


def main():
    src, out = sys.argv[1], sys.argv[2]
    n = int(sys.argv[3]) if len(sys.argv) > 3 else 200
    seed = int(sys.argv[4]) if len(sys.argv) > 4 else 20261014
    rng = random.Random(seed)

    tmpdir = tempfile.mkdtemp(prefix="fertoffice_")
    wb_path = os.path.join(tmpdir, "fo.xlsm")
    shutil.copyfile(src, wb_path)

    xl = win32com.client.DispatchEx("Excel.Application")
    xl.Visible = False
    xl.DisplayAlerts = False
    xl.AutomationSecurity = 3  # msoAutomationSecurityForceDisable: no macros
    wb = xl.Workbooks.Open(wb_path, UpdateLinks=0, ReadOnly=True)
    sh = {name: wb.Worksheets(name) for name in
          ["Inserimento", "Codici", "Bilancio", "Coltura", "Cicli_Fase",
           "Suolo", "Valori da riportare"]}
    ins, cod = sh["Inserimento"], sh["Codici"]

    rows = []
    try:
        while len(rows) < n:
            s = scenario(rng)
            cod.Range("F2").Value = s["group"]
            cod.Range("G2").Value = s["crop_id"] - GROUP_OFFSET[s["group"]]
            xl.Calculate()
            lo = sh["Cicli_Fase"].Range("L21").Value
            hi = sh["Cicli_Fase"].Range("M21").Value
            if not (lo <= s["phase"] <= hi):
                continue
            cod.Range("H2").Value = s["phase"] - lo + 1
            for cell, key in [("T10", "yield"), ("C19", "sand"),
                              ("C21", "clay"), ("L19", "Ntot"),
                              ("L21", "SOM"), ("F23", "pH"),
                              ("G25", "CaCO3_tot"), ("G27", "CaCO3_att"),
                              ("L26", "olsen_P2O5"), ("R19", "K2O"),
                              ("B37", "winter_rain"), ("E37", "feb_rain"),
                              ("Q32", "org_prev_N")]:
                ins.Range(cell).Value = s[key]
            # N fixation "considerata" = the value Fert_Office proposes for
            # the crop (Inserimento!H15), which is NFert's default.
            ins.Range("J15").Value = ins.Range("H15").Value
            cod.Range("AZ2").Value = bool(s["no_till"])
            for cell, key in [("AM2", "id_dre"), ("AO2", "id_pre"),
                              ("AP2", "id_mo"), ("AR2", "id_fre"),
                              ("AU2", "id_ubi")]:
                cod.Range(cell).Value = s[key]
            xl.Calculate()
            s["CN"] = ins.Range("L23").Value
            s["n_fix_pct"] = ins.Range("J15").Value or 0
            for k, (shname, cell) in OUT_CELLS.items():
                s[k] = sh[shname].Range(cell).Value if shname in sh else \
                    wb.Worksheets(shname).Range(cell).Value
            if s["fo_phase"] != s["phase"]:
                continue
            rows.append(s)
    finally:
        wb.Close(SaveChanges=False)
        xl.Quit()
        shutil.rmtree(tmpdir, ignore_errors=True)

    with open(out, "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)
    print(f"wrote {len(rows)} scenarios to {out}")


if __name__ == "__main__":
    main()
