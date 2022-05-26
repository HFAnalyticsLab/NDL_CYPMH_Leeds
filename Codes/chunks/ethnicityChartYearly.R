# Plot yearly comparison between ethnic breakdown of patients vs residents

cohort_referrals %>%
  left_join(geographr::lookup_lsoa_msoa, by = c('lsoa' = 'lsoa_code')) %>%
  mutate(
    year = as.character(as.numeric(
      str_sub(
        quarter(referral_date, fiscal_start = 4, with_year = TRUE), 
        1, 
        4
      )
    ) - 1
  )) %>%
  group_by(nhs_number, year) %>%
  summarise(
    msoa_name = first(msoa_name),
    gender = first(gender),
    n_referrals = n_distinct(service_id),
    ethnic_group = first(ethnic_group),
    n_crisis = n_distinct(service_id[
      coalesce(str_detect(referral_team_type, 'Crisis'), FALSE)
    ])
  ) %>%
  group_by(msoa_name, year) %>%
  summarise(
    n_patients = n_distinct(nhs_number),
    n_referrals = sum(n_referrals),
    n_non_white_referrals = sum(n_referrals[!ethnic_group %in% c('White', 'Unknown/Not Stated')]),
    n_non_white = sum(!ethnic_group %in% c('White', 'Unknown/Not Stated')),
    n_crisis = sum(n_crisis)
  ) %>%
  mutate(
    prop_non_white = n_non_white / n_patients,
    prop_non_white_referrals = n_non_white_referrals / n_referrals
  ) %>% 
  filter(n_patients > 25 & !is.na(msoa_name)) %>%
  left_join(ethnicity_msoa, by = 'msoa_name') %>%
  mutate(
    mh_lcl = prop_non_white - sqrt(n_non_white) / n_patients,
    mh_ucl = prop_non_white + sqrt(n_non_white) / n_patients
  ) %>%
  ggplot(aes(x = proportion, y = 100 * prop_non_white, colour = year)) +
  geom_point(alpha = 0.3) +
  geom_abline(slope = 1, intercept = 0) +
  geom_errorbarh(aes(xmin = lcl, xmax = ucl), alpha = 0.3) +
  geom_errorbar(aes(ymin = 100 * mh_lcl, ymax = 100 * mh_ucl), alpha = 0.3) +
  geom_smooth(method = 'lm', formula = y ~ 0 + x, se = FALSE, size = 1, lty = 'dashed') +
  xlim(0, 100) +
  ylim(0, 100) +
  xlab('Percentage BAME Residents (Census 2011)') +
  ylab('Percentage BAME Patients (MHSDS 2016-2021)')