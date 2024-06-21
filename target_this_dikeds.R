tar_load_globals()
tar_load_everything()

library(tidyterra)

# tt across continiet


p_tt <- ggplot() +
  geom_spatraster(data = travel_time_africa) +
  theme_minimal() +
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
  #geom_spatvector(data = africa_points_v) +
  theme_minimal() +
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
  geom_spatraster(data = tt_country) +
  geom_spatvector(
    data = africa_points_v,
    col = "hotpink"
  ) +
  theme_minimal() +
  scale_fill_viridis_c(
    option = "G",
    begin = 1,
    end = 0,
    na.value = "white"
  )

p_tt_country_pts

ggsave(
  "outputs/figures/tt_country_pts.png",
  plot = p_tt_country,
  width = 2000,
  height = 1600,
  units = "px"
)
