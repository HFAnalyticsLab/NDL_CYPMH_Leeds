# Plot proportion of population using non-IAPT mental health services
#   Split by year, deprivation, age, and sex
if (!file.exists('output/ageGenderDeprivationYearlyCharts.RData')) {
pop_2016 <- get_population('2016')
pop_2017 <- get_population('2017')
pop_2018 <- get_population('2018')
pop_2019 <- get_population('2019')
pop_2020 <- get_population('2020')

population_by_year <- bind_rows(
  pop_2016, pop_2017, pop_2018, pop_2019, pop_2020
)

referrals_by_imd_yearly <- cohort_referrals %>%
  mutate(
    year = as.character(as.numeric(
      str_sub(
        quarter(referral_date, fiscal_start = 4, with_year = TRUE), 
        1, 
        4
      )
    ) - 1
  )) %>%
  group_by(lsoa, year) %>%
  summarise(
    imd_decile = mode(imd_decile),
    n_patients = n_distinct(nhs_number),
    n_referrals = n_distinct(service_id),
    n_crisis = n_distinct(service_id[
      coalesce(str_detect(referral_team_type, 'Crisis'), FALSE)
    ])
  ) %>%
  left_join(population_by_year, by = c('lsoa', 'year')) %>%
  group_by(imd_decile, year) %>%
  summarise(
    n_patients = sum(n_patients),
    n_referrals = sum(n_referrals),
    n_crisis = sum(n_crisis),
    pop_estimate = sum(pop_estimate)
  ) %>%
  mutate(
    proportion = n_patients / pop_estimate,
    lcl = proportion - 
      qnorm(1 - 0.05/2) * sqrt(proportion * (1 - proportion) / pop_estimate),
    ucl = proportion +
      qnorm(1 - 0.05/2) * sqrt(proportion * (1 - proportion) / pop_estimate),
    imd_decile = 11 - imd_decile,
    referrals_per_patient = n_referrals / n_patients,
    rpp_lcl = referrals_per_patient - sqrt(referrals_per_patient) / n_patients,
    rpp_ucl = referrals_per_patient + sqrt(referrals_per_patient) / n_patients,
    crises_per_patient = n_crisis / n_patients,
    cpp_lcl = crises_per_patient - qnorm(1 - 0.05 / 2) * sqrt(
      crises_per_patient * (1 - crises_per_patient) / n_patients
    ),
    cpp_ucl = crises_per_patient + qnorm(1 - 0.05 / 2) * sqrt(
      crises_per_patient * (1 - crises_per_patient) / n_patients
    ),
    crises_per_referral = n_crisis / n_referrals,
    cpr_lcl = crises_per_referral - qnorm(1 - 0.05 / 2) * sqrt(
      crises_per_referral * (1 - crises_per_referral) / n_referrals
    ),
    cpr_ucl = crises_per_referral + qnorm(1 - 0.05 / 2) * sqrt(
      crises_per_referral * (1 - crises_per_referral) / n_referrals
    )
  ) %>%
  filter(!is.na(imd_decile))

leeds_population_by_year <- population_by_year %>%
  semi_join(
    lookup_lsoa_msoa %>% 
      semi_join(
        filter(lookup_msoa_lad, lad_name == 'Leeds'), 
        by = 'msoa_code'
      ),
    c('lsoa' = 'lsoa_code')
  ) %>%
  left_join(imd, by = 'lsoa') %>%
  mutate(year = as.numeric(year))

leeds_full_imd_yearly <- cohort_referrals %>%
  semi_join(
    lookup_lsoa_msoa %>%
      semi_join(filter(lookup_msoa_lad, lad_name == 'Leeds')),
    by = c('lsoa' = 'lsoa_code')
  ) %>%
  mutate(year = year(referral_date %m-% months(3))) %>%
  group_by(lsoa, year) %>%
  summarise(
    n_patients = n_distinct(nhs_number),
    n_referrals = n_distinct(service_id),
    n_crisis = n_distinct(service_id[
      coalesce(str_detect(referral_team_type, 'Crisis'), FALSE)
    ])
  ) %>%
  left_join(leeds_population_by_year, by = c('lsoa', 'year')) %>%
  group_by(imd_decile, year) %>%
  summarise(
    n_patients = sum(n_patients),
    n_referrals = sum(n_referrals),
    n_crisis = sum(n_crisis),
    pop_estimate = sum(pop_estimate)
  ) %>%
  mutate(
    proportion = n_patients / pop_estimate,
    lcl = proportion - 
      qnorm(1 - 0.05/2) * sqrt(proportion * (1 - proportion) / pop_estimate),
    ucl = proportion +
      qnorm(1 - 0.05/2) * sqrt(proportion * (1 - proportion) / pop_estimate),
    imd_decile = 11 - imd_decile
  ) %>%
  filter(!is.na(imd_decile))

lby <- leeds_full_imd_yearly %>%
  mutate(imd_quintile = ceiling(imd_decile / 2)) %>%
  group_by(year, imd_quintile) %>%
  summarise(
    n_patients = sum(n_patients),
    pop_estimate = sum(pop_estimate)
  ) %>%
  mutate(
    proportion = n_patients / pop_estimate,
    lcl = proportion - 
      qnorm(1 - 0.05/2) * sqrt(proportion * (1 - proportion) / pop_estimate),
    ucl = proportion +
      qnorm(1 - 0.05/2) * sqrt(proportion * (1 - proportion) / pop_estimate)
  ) %>%
  ungroup()

deprivation_plot <- lby %>% 
  mutate(`Deprivation Quintile` = factor(imd_quintile)) %>% 
  ggplot(aes(`Deprivation Quintile`, 100 * proportion, colour = year)) + 
    geom_point() + 
    geom_errorbar(aes(ymin = 100 * lcl, ymax = 100 * ucl)) + 
    ylim(0, NA) + 
    ylab('Proportion of Population [%]') + 
    xlab('Deprivation Quintile') +
    scale_color_gradient(low = '#d8b365', high = '#5ab4ac')

deprivation_yearly_plot <- lby %>% 
  mutate(`Deprivation Quintile` = factor(imd_quintile)) %>% 
  ggplot(aes(year, 100 * proportion, colour = `Deprivation Quintile`)) + 
    geom_point() + 
    geom_errorbar(aes(ymin = 100 * lcl, ymax = 100 * ucl)) + 
    ylim(0, NA) + 
    ylab('Proportion of Population [%]') + 
    xlab('Year') + 
    geom_smooth(aes(group = imd_quintile), method = 'lm', se = FALSE) +
    labs(colour = 'Deprivation\nQuintile')

# Gradient
population_linfit <- lby %>% 
  group_by(imd_quintile) %>% 
  do(fit = broom::tidy(lm(proportion ~ I(year - 2016), data = .))) %>% 
  unnest(fit)

population_linfit_ci <- lby %>% 
  group_by(imd_quintile) %>% 
  do(fit = broom::tidy(confint(lm(proportion ~ I(year - 2016), data = .)))) %>% 
  unnest(fit)  %>%
  mutate(
    lcl = x[,1],
    ucl = x[,2],
    term = rep(c('(Intercept)', 'I(year - 2016)'), 5)
  ) %>% 
  select(-x)

population_linfit <- population_linfit %>%
  inner_join(population_linfit_ci, by = c('imd_quintile', 'term'))

# gridExtra::grid.arrange(p1, p2, nrow = 1)

#---- Population split by sex ----
full_pop_2016 <- get_population_by_sex('2016')
full_pop_2017 <- get_population_by_sex('2017')
full_pop_2018 <- get_population_by_sex('2018')
full_pop_2019 <- get_population_by_sex('2019')
full_pop_2020 <- get_population_by_sex('2020')

population <- bind_rows(
  full_pop_2016, full_pop_2017, full_pop_2018, full_pop_2019, full_pop_2020
)

leeds_population <- population %>%
  semi_join(
    filter(lookup_lsoa_msoa, str_detect(lsoa_name, 'Leeds')), 
    by = c('lsoa' = 'lsoa_code')
  )

# age_band_pop <- leeds_population %>%
#   select(lsoa, year, child_estimate, teen_estimate, adult_estimate) %>%
#   pivot_longer(
#     cols = c(child_estimate, teen_estimate, adult_estimate),
#     names_to = 'age_band',
#     values_to = 'count'
#   ) %>%
#   mutate(
#     age_band = case_when(
#       age_band == 'child_estimate' ~ '11-16',
#       age_band == 'teen_estimate' ~ '17-19',
#       age_band == 'adult_estimate' ~ '20-25'
#     ),
#     year = as.numeric(year)
#   )
# 
# leeds_age_band <- cohort_referrals %>%
#   semi_join(
#     lookup_lsoa_msoa %>%
#       semi_join(filter(lookup_msoa_lad, lad_name == 'Leeds')),
#     by = c('lsoa' = 'lsoa_code')
#   ) %>%
#   mutate(
#     year = year(referral_date %m-% months(3)),
#     age_band = case_when(
#       age_at_referral > 19 ~ '20-25',
#       age_at_referral > 16 ~ '17-19',
#       age_at_referral > 11 ~ '11-16',
#       TRUE ~ NA_character_
#     )
#   ) %>%
#   filter(!is.na(age_band)) %>%
#   group_by(lsoa, year, age_band) %>%
#   summarise(
#     n_patients = n_distinct(nhs_number),
#     imd_decile = mode(imd_decile)
#   ) %>%
#   left_join(age_band_pop, by = c('lsoa', 'age_band', 'year')) %>%
#   group_by(imd_decile, year, age_band) %>%
#   summarise(
#     n_patients = sum(n_patients),
#     pop_estimate = sum(count)
#   ) %>%
#   mutate(
#     proportion = n_patients / pop_estimate,
#     lcl = proportion -
#       qnorm(1 - 0.05/2) * sqrt(proportion * (1 - proportion) / pop_estimate),
#     ucl = proportion +
#       qnorm(1 - 0.05/2) * sqrt(proportion * (1 - proportion) / pop_estimate),
#     imd_decile = 11 - imd_decile
#   ) %>%
#   filter(!is.na(imd_decile))
# 
# leeds_age_band %>%
#   group_by(age_band, year) %>%
#   summarise(
#     n_patients = sum(n_patients),
#     pop_estimate = sum(pop_estimate),
#     proportion = n_patients / pop_estimate,
#     lcl = proportion -
#       qnorm(1 - 0.05/2) * sqrt(proportion * (1 - proportion) / pop_estimate),
#     ucl = proportion +
#       qnorm(1 - 0.05/2) * sqrt(proportion * (1 - proportion) / pop_estimate)
#   ) %>%
#   ggplot(aes(year, 100 * proportion, colour = age_band)) +
#     geom_point() +
#     geom_errorbar(aes(ymin = 100 * lcl, ymax = 100 * ucl)) +
#     ylim(0, NA) +
#     ylab('Proportion of Population [%]') + 
#     xlab('Year')

# Population proportion by gender
gender_pop <- leeds_population %>%
  select(lsoa, year, female_pop_estimate, male_pop_estimate) %>%
  pivot_longer(
    cols = c(female_pop_estimate, male_pop_estimate),
    names_to = 'gender',
    values_to = 'count'
  ) %>%
  mutate(
    gender = case_when(
      gender == 'female_pop_estimate' ~ 'Female',
      gender == 'male_pop_estimate' ~ 'Male'
    ),
    year = as.numeric(year)
  )

leeds_gender <- cohort_referrals %>%
  semi_join(
    lookup_lsoa_msoa %>%
      semi_join(filter(lookup_msoa_lad, lad_name == 'Leeds')),
    by = c('lsoa' = 'lsoa_code')
  ) %>%
  mutate(
    year = year(referral_date %m-% months(3))
  ) %>%
  filter(!is.na(gender)) %>%
  group_by(lsoa, year, gender) %>%
  summarise(
    n_patients = n_distinct(nhs_number)
  ) %>%
  left_join(gender_pop, by = c('lsoa', 'gender', 'year')) %>%
  group_by(year, gender) %>%
  summarise(
    n_patients = sum(n_patients),
    pop_estimate = sum(count)
  ) %>%
  mutate(
    proportion = n_patients / pop_estimate,
    lcl = proportion -
      qnorm(1 - 0.05/2) * sqrt(proportion * (1 - proportion) / pop_estimate),
    ucl = proportion +
      qnorm(1 - 0.05/2) * sqrt(proportion * (1 - proportion) / pop_estimate)
  )

gender_plot <- leeds_gender %>%
  ggplot(aes(year, 100 * proportion, colour = gender, group = gender)) +
    geom_point() +
    geom_errorbar(aes(ymin = 100 * lcl, ymax = 100 * ucl)) +
    geom_smooth(method = 'lm', se = FALSE) +
    ylim(0, NA) +
    ylab('Proportion of Population [%]') + 
    xlab('Year')

#---- Population by age ----
age_pop_2016 <- get_population_by_age('2016')
age_pop_2017 <- get_population_by_age('2017')
age_pop_2018 <- get_population_by_age('2018')
age_pop_2019 <- get_population_by_age('2019')
age_pop_2020 <- get_population_by_age('2020')

age_population <- bind_rows(
  age_pop_2016, age_pop_2017, age_pop_2018, age_pop_2019, age_pop_2020
)

leeds_age_pop <- age_population %>%
  semi_join(
    filter(lookup_lsoa_msoa, str_detect(lsoa_name, 'Leeds')), 
    by = c('lsoa' = 'lsoa_code')
  )

age_pop <- leeds_age_pop %>%
  select(lsoa, year, `11` : `25`) %>%
  pivot_longer(
    cols = c(`11` : `25`),
    names_to = 'age',
    values_to = 'pop_estimate'
  ) %>%
  mutate(
    year = as.numeric(year),
    age = as.integer(age)
  )

leeds_age <- cohort_referrals %>%
  semi_join(
    lookup_lsoa_msoa %>%
      semi_join(filter(lookup_msoa_lad, lad_name == 'Leeds')),
    by = c('lsoa' = 'lsoa_code')
  ) %>%
  mutate(
    year = year(referral_date %m-% months(3))
  ) %>%
  group_by(lsoa, year, age = age_at_referral) %>%
  summarise(
    n_patients = n_distinct(nhs_number)
  ) %>%
  inner_join(age_pop, by = c('lsoa', 'age', 'year')) %>%
  group_by(year, age) %>%
  summarise(
    n_patients = sum(n_patients),
    pop_estimate = sum(pop_estimate)
  ) %>%
  mutate(
    proportion = n_patients / pop_estimate,
    lcl = proportion -
      qnorm(1 - 0.05/2) * sqrt(proportion * (1 - proportion) / pop_estimate),
    ucl = proportion +
      qnorm(1 - 0.05/2) * sqrt(proportion * (1 - proportion) / pop_estimate)
  )

leeds_age_avg <- leeds_age %>%
  group_by(age) %>%
  summarise(
    n_patients = sum(n_patients),
    pop_estimate = sum(pop_estimate)
  ) %>%
  mutate(
    proportion = n_patients / pop_estimate,
    lcl = proportion -
      qnorm(1 - 0.05/2) * sqrt(proportion * (1 - proportion) / pop_estimate),
    ucl = proportion +
      qnorm(1 - 0.05/2) * sqrt(proportion * (1 - proportion) / pop_estimate)
  ) %>%
  ungroup()

# Plots

age_plot <- leeds_age %>%
  ggplot() +
  geom_line(aes(age, 100 * proportion), colour = 'black', data = leeds_age_avg, size = 2) +
  # geom_ribbon(aes(age, 100 * proportion, ymin = 100 * lcl, ymax = 100 * ucl), data = leeds_age_avg, colour = NA, fill = 'black', alpha = 0.3) +
  geom_line(aes(age, 100 * proportion, colour = year, group = year), size = 1) +
  geom_ribbon(aes(age, 100 * proportion, ymin = 100 * lcl, ymax = 100 * ucl, fill = year, group = year), colour = NA, alpha = 0.3) +
  ylim(0, NA) +
  ylab('Proportion of Population [%]') + 
  xlab('Age At Referral') + 
  scale_color_gradient(low = '#d8b365', high = '#5ab4ac') + 
  scale_fill_gradient(low = '#d8b365', high = '#5ab4ac')

  save(
    deprivation_plot, deprivation_yearly_plot, gender_plot, age_plot, 
    file = 'output/ageGenderDeprivationYearlyCharts.RData'
  )
} else {
  load('output/ageGenderDeprivationYearlyCharts.RData')
}

gridExtra::grid.arrange(
  deprivation_plot, 
  deprivation_yearly_plot, 
  gender_plot, 
  age_plot
)
