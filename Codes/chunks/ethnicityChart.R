# Plot proportion of non-white patients vs non-while residents by LSOA or MSOA

# LSOA
p1 <- referrals_by_lsoa %>% 
  filter(n_patients > 25 & !is.na(lsoa)) %>%
  ggplot(aes(x = 100 * prop_non_white_census, y = 100 * prop_non_white)) +
  geom_point() +
  geom_abline(slope = 1, intercept = 0) +
  xlab('Percentage Non-White Residents (Census 2011)') +
  ylab('Percentage Non-White Patients (MHSDS 2016-2021)')

# MSOA
p2 <- referrals_by_msoa %>% 
  filter(n_patients > 25 & !is.na(msoa_name)) %>%
  left_join(ethnicity_msoa, by = 'msoa_name') %>%
  mutate(
    mh_lcl = prop_non_white - sqrt(n_non_white) / n_patients,
    mh_ucl = prop_non_white + sqrt(n_non_white) / n_patients
  ) %>%
  ggplot(aes(x = proportion, y = 100 * prop_non_white)) +
  geom_point() +
  geom_abline(slope = 1, intercept = 0) +
  geom_errorbarh(aes(xmin = lcl, xmax = ucl)) +
  geom_errorbar(aes(ymin = 100 * mh_lcl, ymax = 100 * mh_ucl)) +
  geom_smooth(method = 'lm', formula = y ~ 0 + x, se = FALSE, size = 1, lty = 'dashed') +
  xlim(0, 100) +
  ylim(0, 100) +
  xlab('Percentage BAME Residents (Census 2011)') +
  ylab('Percentage BAME Patients (MHSDS 2016-2021)')

# Gradient, intercept at (0,0)
linear_fit <- lm(
  prop_non_white_patients ~ proportion_residents - 1,
  data = referrals_by_msoa %>% 
    filter(n_patients > 25 & !is.na(msoa_name)) %>%
    left_join(ethnicity_msoa, by = 'msoa_name') %>%
    transmute(
      proportion_residents = proportion,
      prop_non_white_patients = 100 * prop_non_white
    )
)

p2