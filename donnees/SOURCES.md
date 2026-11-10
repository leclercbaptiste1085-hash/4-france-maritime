# Sources des données

- `entreprises.csv` (k€) : ABC Bourse, pages « chiffres clés » (BEN, ALCAT, EXA, GTT), copiées dans brut/abc_*.html
  et extraites par extraire_abcbourse.py.
  Fountaine Pajot : chiffre d affaires 2022-2025 = communiqué du 27/10/2025 (brut/abc_fp_ca_2025.html) ;
  autres postes = rapport de gestion au 31/08/2025 (brut/fp_rapport_gestion_2025.pdf, p. 5-6).
  Exercices décalés : Catana et Fountaine Pajot clôturent fin août (2025 = sept. 2024 - août 2025).
  Exail 2021 = Groupe Gorgé avant le rachat d'iXblue (2022) : périmètre non comparable.
- `brut/eurostat_fluvial.csv` : Eurostat iww_go_atygo, fret fluvial en millions de tonnes-km.
- `brut/eurostat_part_modale.csv` : Eurostat tran_hv_frmod, part modale du fret terrestre (%).
- `brut/eurostat_aquaculture.csv` : Eurostat fish_aq2a, production aquacole en tonnes (poids vif).
- Réseau fluvial : Cour des comptes, *L'entretien des voies navigables : l'exemple de VNF*, S2025-0001, février 2025
  (brut/cour_comptes_vnf_2025.pdf) ; état des écluses : questionnaire budgétaire de l'Assemblée nationale à VNF,
  janvier 2025 (brut/vnf_questionnaire_an_2025.pdf).
- Académie de marine, *France, ambition maritime*, 2025 (brut/academie_marine_2025.pdf) : citation d'ouverture et rang de l'espace maritime français.
