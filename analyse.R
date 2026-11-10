# La France et la mer : un savoir-faire réel, un espace sous-exploité
# Sources : Eurostat (fish_aq2a, iww_go_atygo, tran_hv_frmod), ABC Bourse, Fountaine Pajot, Cour des comptes
# Lancer depuis le dossier du projet : Rscript analyse.R
# (les comptes des entreprises sont extraits au préalable par donnees/extraire_abcbourse.py)

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(ggplot2); library(scales)
})

brut <- "donnees/brut/"
dir.create("sorties", showWarnings = FALSE)

# ---------------------------------------------------------------------------
# Style : fond blanc, bleu et vert, police Calibri
# ---------------------------------------------------------------------------
papier <- "white"; encre <- "#1B2A3A"; balise <- "#2E8B57"; lagon <- "#1F5A8C"; brume <- "#B8C7D6"

theme_set(theme_minimal(base_size = 12, base_family = "Calibri") +
  theme(plot.background  = element_rect(fill = papier, colour = NA),
        panel.background = element_rect(fill = papier, colour = NA),
        plot.title.position = "plot", plot.caption.position = "plot",
        plot.title    = element_text(face = "bold", colour = encre, size = 16, margin = margin(b = 4)),
        plot.subtitle = element_text(colour = "#4A5568", margin = margin(b = 12)),
        plot.caption  = element_text(colour = "#6B7280", size = 8, hjust = 0, margin = margin(t = 10)),
        axis.text     = element_text(colour = "#4A5568"),
        panel.grid.major.y = element_line(colour = "#E3E8EE"),
        panel.grid.major.x = element_blank(), panel.grid.minor = element_blank(),
        strip.text    = element_text(face = "bold", colour = encre, hjust = 0),
        legend.position = "none", plot.margin = margin(16, 20, 12, 16)))

enregistrer <- function(g, fichier, l = 8, h = 5) ggsave(file.path("sorties", fichier), g, width = l, height = h, dpi = 300)

pays_noms <- c(FR = "France", NO = "Norvège", ES = "Espagne", EL = "Grèce", IT = "Italie",
               NL = "Pays-Bas", DE = "Allemagne", BE = "Belgique")

eurostat <- function(f) read.csv(paste0(brut, f)) |>
  mutate(pays = pays_noms[geo], annee = TIME_PERIOD, v = OBS_VALUE)

# ---------------------------------------------------------------------------
# 1. La mer cultivée : production aquacole (tonnes, poids vif)
# ---------------------------------------------------------------------------
aqua <- eurostat("eurostat_aquaculture.csv") |>
  filter(geo %in% c("FR", "NO", "ES", "IT")) |>  # Grèce écartée : série incomplète (2012-2015)
  mutate(kt = v / 1000)

aqua_der <- max(aqua$annee)
ratio_no <- with(filter(aqua, annee == aqua_der), kt[geo == "NO"] / kt[geo == "FR"])

g1 <- ggplot(aqua, aes(annee, kt, group = pays)) +
  geom_area(data = filter(aqua, geo == "NO"), fill = brume, alpha = 0.35) +
  geom_line(aes(colour = geo == "FR", linewidth = geo == "FR")) +
  geom_text(data = filter(aqua, annee == aqua_der), aes(label = pays, colour = geo == "FR"),
            hjust = -0.12, family = "Calibri", size = 3.8) +
  scale_colour_manual(values = c(`TRUE` = balise, `FALSE` = lagon)) +
  scale_linewidth_manual(values = c(`TRUE` = 1.6, `FALSE` = 0.6)) +
  scale_x_continuous(expand = expansion(mult = c(0.01, 0.13))) +
  scale_y_continuous(labels = label_number(big.mark = " "), expand = expansion(mult = c(0, 0.06))) +
  labs(title = sprintf("La Norvège élève %.0f fois plus de poissons\net de coquillages que la France", ratio_no),
       subtitle = "Production aquacole, milliers de tonnes (poids vif)",
       x = NULL, y = NULL,
       caption = "Source : Eurostat, fish_aq2a (toutes espèces, tous milieux).")
enregistrer(g1, "1_aquaculture.png")

# ---------------------------------------------------------------------------
# 2. Les industriels : chiffre d'affaires et marge nette
#    Catana et Fountaine Pajot clôturent fin août : 2025 = sept. 2024 - août 2025.
#    Exail 2021 = Groupe Gorgé avant le rachat d'iXblue : exclu, périmètre non comparable.
# ---------------------------------------------------------------------------
ent <- read.csv("donnees/entreprises.csv", encoding = "UTF-8") |>
  filter(!(entreprise == "Exail Technologies" & exercice == 2021)) |>
  pivot_wider(names_from = poste, values_from = valeur_keur) |>
  rename(ca = `Chiffre d'affaires`, rn = `Résultat (part du groupe)`) |>
  mutate(ca_m = ca / 1000, marge = rn / ca,
         entreprise = factor(entreprise, levels = c("Bénéteau", "Fountaine Pajot", "Catana Group",
                                                    "Exail Technologies", "GTT")))

g2 <- ggplot(ent, aes(exercice, ca_m)) +
  geom_area(fill = lagon, alpha = 0.18) +
  geom_line(colour = lagon, linewidth = 1.1) +
  geom_point(colour = lagon, fill = papier, shape = 21, size = 2.4, stroke = 1.1) +
  geom_text(data = ent |> group_by(entreprise) |> filter(exercice == max(exercice)),
            aes(label = round(ca_m)), vjust = -1, colour = encre, family = "Calibri", size = 3.4) +
  facet_wrap(~ entreprise, scales = "free_y", nrow = 2) +
  scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.2))) +
  scale_x_continuous(breaks = c(2021, 2023, 2025)) +
  labs(title = "La plaisance reflue",
       subtitle = "Chiffre d'affaires, millions d'euros",
       x = NULL, y = NULL,
       caption = paste("Sources : ABC Bourse (comptes publiés) ; Fountaine Pajot, communiqué du 27/10/2025.",
                       "\nCatana et Fountaine Pajot clôturent fin août. Exail 2021 exclu (avant le rachat d'iXblue)."))
enregistrer(g2, "2_entreprises_ca.png", 9, 6)

marges <- ent |> filter(exercice %in% c(2024, 2025), !is.na(marge)) |>
  select(entreprise, exercice, marge) |>
  pivot_wider(names_from = exercice, values_from = marge, names_prefix = "m") |>
  mutate(entreprise = reorder(entreprise, m2025))

g3 <- ggplot(marges, aes(y = entreprise)) +
  geom_vline(xintercept = 0, colour = encre, linewidth = 0.4) +
  geom_segment(aes(x = m2024, xend = m2025, yend = entreprise), colour = brume, linewidth = 2.2) +
  geom_point(aes(x = m2024), colour = brume, size = 3.5) +
  geom_point(aes(x = m2025, colour = m2025 < 0), size = 4.2) +
  geom_text(aes(x = m2025, label = percent(m2025, accuracy = 0.1, decimal.mark = ",", suffix = " %"),
                colour = m2025 < 0),
            vjust = -1.1, family = "Calibri", size = 3.4) +
  scale_colour_manual(values = c(`TRUE` = lagon, `FALSE` = balise)) +
  scale_x_continuous(labels = label_percent(accuracy = 1, suffix = " %"), expand = expansion(mult = 0.08)) +
  labs(title = "GTT, l'économie de la connaissance",
       subtitle = "Marge nette (résultat net part du groupe / chiffre d'affaires) : 2024 en gris, 2025 en couleur",
       x = NULL, y = NULL,
       caption = "Sources : ABC Bourse ; rapport de gestion Fountaine Pajot au 31/08/2025.")
enregistrer(g3, "3_entreprises_marge.png", 8, 4.8)

# ---------------------------------------------------------------------------
# 3. Ouverture : le fleuve, un réseau qui décline
# ---------------------------------------------------------------------------
fluv <- eurostat("eurostat_fluvial.csv") |>
  filter(geo %in% c("FR", "DE", "NL", "BE")) |>
  mutate(md = v / 1000)  # milliards de t-km

fl_der <- max(fluv$annee)

# Intensité d'usage : fret rapporté à la longueur du réseau (km, Cour des comptes 2025, tableau 1)
longueur_km <- c(FR = 8500, DE = 7300, NL = 4800, BE = 1500)
intensite <- fluv |> filter(annee == fl_der) |>
  mutate(km = longueur_km[geo], mtkm_par_km = round(v / km, 1))
lib_int <- with(intensite, paste0(pays, " ", format(mtkm_par_km, decimal.mark = ","))[order(-mtkm_par_km)])

g4 <-ggplot(fluv, aes(annee, md, group = pays)) +
  geom_line(aes(colour = geo == "FR", linewidth = geo == "FR")) +
  geom_text(data = filter(fluv, annee == fl_der) |>
              mutate(dy = case_when(geo %in% c("DE", "BE") ~ 1.5, geo %in% c("NL", "FR") ~ -1.5, TRUE ~ 0)),
            aes(y = md + dy, label = pays, colour = geo == "FR"),
            hjust = -0.12, family = "Calibri", size = 3.8) +
  scale_colour_manual(values = c(`TRUE` = balise, `FALSE` = lagon)) +
  scale_linewidth_manual(values = c(`TRUE` = 1.6, `FALSE` = 0.6)) +
  scale_x_continuous(expand = expansion(mult = c(0.01, 0.15))) +
  scale_y_continuous(limits = c(0, NA), expand = c(0, 0)) +
  labs(title = "Le plus long réseau navigable d'Europe mais l'un des moins utilisés",
       subtitle = paste0("Fret fluvial, milliards de tonnes-kilomètres\nPar km de voie en ", fl_der,
                         " (millions de t-km) : ", paste(lib_int, collapse = " ; ")),
       x = NULL, y = NULL,
       caption = paste("Sources : Eurostat, iww_go_atygo ; longueurs des réseaux : Cour des comptes (2025).",
                       "\nLa France compte 8 500 km de voies navigables, dont 5 600 km au gabarit Freycinet fixé en 1879."))
enregistrer(g4, "4_fluvial.png")

modes <- c(ROAD = "Route", RAIL = "Rail", IWW = "Fleuve")
modal <- eurostat("eurostat_part_modale.csv") |>
  filter(geo %in% c("FR", "DE", "BE", "NL")) |>
  filter(annee == max(annee[geo == "FR"])) |>
  mutate(mode = factor(modes[tra_mode], levels = rev(modes)),
         pays = reorder(pays, ifelse(tra_mode == "IWW", v, 0), sum))

g5 <- ggplot(modal, aes(v, pays, fill = mode)) +
  geom_col(width = 0.6) +
  geom_text(data = filter(modal, tra_mode == "IWW"), aes(x = 101, y = pays, label = paste0(format(v, decimal.mark = ","), " %")),
            hjust = 0, size = 4, colour = balise, fontface = "bold", family = "Calibri", inherit.aes = FALSE) +
  annotate("text", x = c(30, 92), y = 4.45, label = c("route", "rail"), colour = "#4A5568",
           family = "Calibri", size = 3.4) +
  annotate("text", x = 101, y = 4.45, label = "fleuve", colour = balise, hjust = 0,
           family = "Calibri", size = 3.4) +
  scale_fill_manual(values = c(Route = "#D5DDE6", Rail = lagon, Fleuve = balise)) +
  scale_x_continuous(labels = function(x) paste0(x, " %"), breaks = c(0, 50, 100),
                     limits = c(0, 112), expand = c(0, 0)) +
  coord_cartesian(clip = "off") +
  labs(title = "En France, le fleuve porte moins de 2 % des marchandises",
       subtitle = sprintf("Répartition du fret terrestre par mode, %s (%% des tonnes-km)", unique(modal$annee)),
       x = NULL, y = NULL,
       caption = "Source : Eurostat, tran_hv_frmod.")
enregistrer(g5, "5_part_modale.png", 8, 4.5)

# ---------------------------------------------------------------------------
# Résultats chiffrés
# ---------------------------------------------------------------------------
sink("sorties/resultats.txt")
cat("== Aquaculture,", aqua_der, "(milliers de tonnes) ==\n")
print(aqua |> filter(annee %in% c(min(annee), aqua_der)) |> select(pays, annee, kt) |>
        pivot_wider(names_from = annee, values_from = kt))
cat("\nNorvège / France :", round(ratio_no, 1), "\n")
cat("\n== Entreprises (M€ et marge nette en %) ==\n")
print(ent |> arrange(entreprise, exercice) |> select(entreprise, exercice, ca_m, marge) |>
        mutate(marge = round(100 * marge, 1)), n = Inf)
cat("\n== Fret fluvial (milliards de t-km) ==\n")
print(fluv |> filter(annee %in% c(2015, fl_der)) |> select(pays, annee, md) |>
        pivot_wider(names_from = annee, values_from = md))
cat("\n== Fret fluvial par km de réseau,", fl_der, "(millions de t-km par km) ==\n")
print(intensite |> select(pays, km, mtkm_par_km) |> arrange(-mtkm_par_km))
cat("\n== Part modale du fret,", unique(modal$annee), "(%) ==\n")
print(modal |> select(pays, tra_mode, v) |> pivot_wider(names_from = tra_mode, values_from = v))
sink()
cat("Graphiques et résultats écrits dans sorties/\n")
