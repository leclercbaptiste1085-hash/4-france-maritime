# Extrait les comptes 2021-2025 des pages « chiffres clés » d'ABC Bourse (brut/abc_*.html)
# et les écrit dans entreprises.csv ; les lignes Fountaine Pajot (saisies depuis ses publications) sont conservées.
# Lancer depuis donnees/ : python extraire_abcbourse.py
import csv, html, re

PAGES = {"BENp": "Bénéteau", "ALCATp": "Catana Group", "EXAp": "Exail Technologies", "GTTp": "GTT"}
POSTES = {"Chiffre d'affaires", "Résultat opérationnel", "Résultat (part du groupe)", "Capitaux propres",
          "Trésorerie et équivalents de trésorerie", "Dettes financières (passif non courant)",
          "Dettes financières (passif courant)", "Stocks et travaux en-cours net", "Effectif moyen"}

def cellules(fichier):
    s = open(fichier, encoding="utf-8", errors="replace").read()
    s = re.sub(r"<script.*?</script>", "", s, flags=re.S)
    s = html.unescape(re.sub(r"<[^>]+>", "|", s)).replace("\xa0", "").replace(" ", "")
    return [c.strip() for c in s.split("|") if c.strip()]

lignes = []
for code, nom in PAGES.items():
    c = cellules(f"brut/abc_{code}.html")
    debut, annees, vus = c.index("Trimestriels"), None, set()
    for k in range(debut, len(c)):
        if all(re.fullmatch(r"20\d\d", x) for x in c[k:k + 5]):
            annees = [int(x) for x in c[k:k + 5]]
        if c[k] in POSTES and annees and c[k] not in vus:
            vus.add(c[k])
            for a, v in zip(annees, c[k + 1:k + 6]):
                if re.fullmatch(r"-?[\d.]+", v):
                    lignes.append([nom, a, c[k], float(v)])
    assert len(vus) >= 3, f"{nom} : tableau introuvable"

fp = [r for r in csv.reader(open("entreprises.csv", encoding="utf-8")) if r[0] == "Fountaine Pajot"]
with open("entreprises.csv", "w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["entreprise", "exercice", "poste", "valeur_keur"])
    w.writerows(lignes + fp)
print(len(lignes), "lignes ABC Bourse,", len(fp), "lignes Fountaine Pajot")
