tar_load_globals()
tar_load_everything()

library(tidyterra)

# tt across continiet


p_tt <- ggplot() +
  geom_spatraster(data = travel_time_africa) +
  theme_void() +
  theme(legend.position = "none") +
  scale_fill_viridis_c(
    option = "G",
    begin = 1,
    end = 0,
    na.value = "white"
  )

p_tt

ggsave(
  "outputs/figures/tt.png",
  plot = p_tt,
  width = 1600,
  height = 1600,
  units = "px"
)


## tt by country
p_tt_country <- ggplot() +
  geom_spatraster(data = tt_country) +
  theme_void() +
  theme(legend.position = "none") +
  scale_fill_viridis_c(
    option = "G",
    begin = 1,
    end = 0,
    na.value = "white"
  )

p_tt_country

ggsave(
  "outputs/figures/tt_country.png",
  plot = p_tt_country,
  width = 1600,
  height = 1600,
  units = "px"
)


p_tt_country_sqrt <- ggplot() +
  geom_spatraster(data = tt_country^(1/2)) +
  theme_void() +
  theme(legend.position = "none") +
  scale_fill_viridis_c(
    option = "G",
    begin = 1,
    end = 0,
    na.value = "white"
  )

p_tt_country_sqrt

ggsave(
  "outputs/figures/tt_country_sqrt.png",
  plot = p_tt_country_sqrt,
  width = 1600,
  height = 1600,
  units = "px"
)

## tt by country plus points

p_tt_country_pts <- ggplot() +
  geom_spatraster(data = sqrt(tt_country)) +
  geom_spatvector(
    data = africa_points_v,
    col = "deeppink"
  ) +
  theme_void() +
  theme(legend.position = "none") +
  scale_fill_viridis_c(
    option = "G",
    begin = 1,
    end = 0,
    na.value = "white"
  )

p_tt_country_pts

ggsave(
  "outputs/figures/tt_country_pts.png",
  plot = p_tt_country_pts,
  width = 1600,
  height = 1600,
  units = "px"
)



## with all MAP points

library("malariaAtlas")

# get occurrence points
occurrences <- getVecOcc(continent = "Africa")

occ_pts <- bind_cols(
  occurrences |>
    as.data.frame(),
  occurrences |>
    st_coordinates()
) |>
  as_tibble() |>
  select(-geometry) |>
  vect(
    geom = c("X", "Y"),
    crs = crs(africa_points_v)
  )

# join occurrence and research location points
# add data type col to research location points
apts <- africa_points_v
apts$data_type <- "Research\nfacility"

# join them
ppts <- c(
  occ_pts |>
    mutate(data_type = "Vector\noccurrence") |>
    select(data_type),
  apts
) |>
  vect()

# get flat raster mask for Africa
new_mask <- tt_country
new_mask[which(!is.na(values(new_mask)))] <- 1


# plot of vector occurrence locations
p_vec_occ <- ggplot() +
  geom_spatraster(
    data = new_mask
  ) +
  geom_spatvector(
    data = ppts |>
      filter(data_type == "Vector\noccurrence"),
    aes(
      col = data_type
    )
  ) +
  scale_fill_viridis_c(
    option = "G",
    begin = 1,
    end = 0.7,
    na.value = "white",
    guide = "none"
  ) +
  scale_colour_manual(
    values = "gold",
    guide = guide_legend(title = "Data type")
  ) +
  theme_void() +
  theme(
    legend.position = "inside",
    legend.position.inside = c(0.25, 0.4)
  )

p_vec_occ

ggsave(
  "outputs/figures/vec_occ.png",
  plot = p_vec_occ,
  width = 1600,
  height = 1600,
  units = "px",
  bg = "white"
)


# vector occurrence with research locations
p_vec_occ_res_loc <- ggplot() +
  geom_spatraster(
    data = new_mask
  ) +
  geom_spatvector(
    data = ppts,
    aes(
      col = data_type
    )
  ) +
  scale_fill_viridis_c(
    option = "G",
    begin = 1,
    end = 0.7,
    na.value = "white",
    guide = "none"
  ) +
  scale_colour_manual(
    values = c("deeppink", "gold"),
    guide = guide_legend(title = "Data type")
  ) +
  theme_void() +
  theme(
    legend.position = "inside",
    legend.position.inside = c(0.25, 0.4)
  )

p_vec_occ_res_loc

ggsave(
  "outputs/figures/vec_occ_res.png",
  plot = p_vec_occ_res_loc,
  width = 1600,
  height = 1600,
  units = "px",
  bg = "white"
)


# vector occurrene plus research locations on travel time
p_vec_occ_res_loc_tt <- ggplot() +
  geom_spatraster(
    data = sqrt(tt_country)
  ) +
  geom_spatvector(
    data = ppts,
    aes(
      col = data_type
    )
  ) +
  scale_fill_viridis_c(
    option = "G",
    begin = 1,
    end = 0,
    na.value = "white",
    guide = "none"
  ) +
  scale_colour_manual(
    values = c("deeppink", "gold"),
    guide = guide_legend(title = "Data type")
  ) +
  theme_void() +
  theme(
    legend.position = "inside",
    legend.position.inside = c(0.25, 0.4)
  )

p_vec_occ_res_loc_tt

ggsave(
  "outputs/figures/vec_occ_res_tt.png",
  plot = p_vec_occ_res_loc_tt,
  width = 1600,
  height = 1600,
  units = "px",
  bg = "white"
)



## Epi plots for comparison

# mask for kenya tanzania and uganda
kut <- make_africa_mask(
  type = "vector",
  countries = c("KEN", "UGA", "TZA")
)

# get sp version for getRaster
library(raster)
kutsp <- as(kut, "Spatial")




pfpc <- getRaster("Malaria__202406_Global_Pf_Incidence_Count")


pfpc_kut <- pfpc |>
  crop(kut) |>
  mask(kut)

plot(pfpc_kut |> sqrt())

pfir <- getRaster("Malaria__202406_Global_Pf_Incidence_Rate")

pfir_kut <- pfir |>
  crop(kut) |>
  mask(kut)
plot(pfir_kut)


pfmc <- getRaster(
  "Malaria__202406_Global_Pf_Mortality_Count",
  shp = kutsp
)

pfmc[is.na(values(pfmc))] <- 0
pfmc <- mask(pfmc, kut)
plot(pfmc^(1/3))

ggplot() +
  geom_spatraster(
    data = pfmc^(1/3)
  ) +
  theme_void() +
  theme(legend.position = "none") +
  scale_fill_viridis_c(
    option = "G",
    begin = 1,
    end = 0,
    na.value = "white"
  )
ggsave(
  filename = "outputs/figures/pf_mortality_count_scaled.png",
  width = 1600,
  height = 1600,
  units = "px",
  bg = "white"
)
