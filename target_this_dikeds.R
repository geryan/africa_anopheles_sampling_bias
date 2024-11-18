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
  width = 2000,
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
  width = 2000,
  height = 1600,
  units = "px"
)

## tt by country plus points

p_tt_country_pts <- ggplot() +
  geom_spatraster(data = sqrt(tt_country)) +
  geom_spatvector(
    data = africa_points_v,
    col = "hotpink"
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
  width = 2000,
  height = 1600,
  units = "px"
)



## with all MAP points

library("malariaAtlas")

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


apts <- africa_points_v
apts$data_type <- "Research\nfacility"

ppts <- c(
  occ_pts |>
    mutate(data_type = "Vector\noccurrence") |>
    select(data_type),
  apts
) |>
  vect()

new_mask <- tt_country
new_mask[which(!is.na(values(new_mask)))] <- 1

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


ggplot() +
  geom_spatraster(data = sqrt(tt_country)) +
  geom_spatvector(
    data = occ_pts,
    col = "yellow"
  ) +
  geom_spatvector(
    data = africa_points_v,
    col = "hotpink"
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




