# Plot mental health service retention by age

grouped_referrals <- cohort_referrals %>%
  rename(provider_name = provider_name.x) %>%
  group_by(nhs_number, age_at_referral) %>%
  summarise(
    estimated_current_age = floor(
      max(age_at_referral) + (max(care_contact_date) %--% today()) / dyears()
    ),
    n_contacts = n(),
    contact_duration = sum(contact_duration, na.rm = TRUE),
    gender = first(gender),
    n_referrals = n_distinct(service_id),
    n_service_teams = n_distinct(paste(service_id, referral_team_id, sep = '-')),
    ethnic_group = first(ethnic_group),
    imd_decile = mean(imd_decile, na.rm = TRUE),
    dna = sum(dna_flag),
    dna_prop = dna / n_contacts,
    primary_referral_reason = coalesce(mode(referral_reason), 'Unknown'),
    primary_referral_source = coalesce(mode(referral_source), 'Unknown'),
    waiting_time = mean((referral_date %--% min(care_contact_date)) / ddays(), na.rm = TRUE),
    referral_team_type = mode(referral_team_type),
    referral_date = mean(referral_date)
  )

grouped_referrals <- grouped_referrals %>% 
  group_by(nhs_number) %>%
  mutate(
    contact_next_year = sum(
      lead(n_contacts)[lead(age_at_referral) == (age_at_referral + 1)],
      na.rm = TRUE
    ) > 0
  ) %>%
  ungroup()

multi_year_referrals <- cohort_referrals %>%
  rename(provider_name = provider_name.x) %>%
  group_by(nhs_number, age_at_referral) %>%
  summarise(
    contact_next_year = sum(
      n()[age_at_contact == (age_at_referral + 1)],
      na.rm = TRUE
    ) > 0
  ) %>%
  ungroup()

grouped_referrals <- grouped_referrals %>%
  left_join(multi_year_referrals, by = c('nhs_number', 'age_at_referral')) %>%
  mutate(
    contact_next_year = contact_next_year.x | contact_next_year.y
  ) %>%
  select(-contact_next_year.x, -contact_next_year.y)

gender <- grouped_referrals %>%
  filter(between(age_at_referral, 11, 25)) %>%
  group_by(age_at_referral, gender) %>% 
  summarise(
    n_patients = n(),
    proportion = sum(contact_next_year) / n_patients,
    lcl = proportion - 
      qnorm(1 - 0.05/2) * sqrt(proportion * (1 - proportion) / n_patients),
    ucl = proportion + 
      qnorm(1 - 0.05/2) * sqrt(proportion * (1 - proportion) / n_patients)
  ) %>% 
  ggplot(aes(x = age_at_referral, y = 100 * proportion, fill = gender)) + 
  geom_ribbon(aes(ymin = 100 * lcl, ymax = 100 * ucl), alpha = 0.4) +
  ylab('Patients Remining\nThe Following Year [%]') +
  xlab('Patient Age At Referral') +
  ylim(0, NA) +
  labs(fill = 'Gender')

deprivation <- grouped_referrals %>%
  filter(between(age_at_referral, 11, 25)) %>%
  group_by(age_at_referral, imd_quintile = ceiling(imd_decile / 2)) %>% 
  summarise(
    n_patients = n(),
    proportion = sum(contact_next_year) / n_patients,
    lcl = proportion - 
      qnorm(1 - 0.05/2) * sqrt(proportion * (1 - proportion) / n_patients),
    ucl = proportion + 
      qnorm(1 - 0.05/2) * sqrt(proportion * (1 - proportion) / n_patients)
  ) %>% 
  filter(imd_quintile %in% c(1, 5)) %>%
  mutate(imd_quintile = factor(imd_quintile)) %>%
  ggplot(
    aes(
      x = age_at_referral, 
      y = 100 * proportion, 
      fill = imd_quintile, 
      group = imd_quintile
    )
  ) + 
  geom_ribbon(aes(ymin = 100 * lcl, ymax = 100 * ucl), alpha = 0.4) +
  ylab('Patients Remining\nThe Following Year [%]') +
  xlab('Patient Age At Referral') +
  ylim(0, NA) +
  labs(fill = 'IMD Quintile')

ethnic_group <- grouped_referrals %>%
  filter(between(age_at_referral, 11, 25)) %>%
  group_by(age_at_referral, ethnic_group) %>% 
  summarise(
    n_patients = n(),
    proportion = sum(contact_next_year) / n_patients,
    lcl = proportion - 
      qnorm(1 - 0.05/2) * sqrt(proportion * (1 - proportion) / n_patients),
    ucl = proportion + 
      qnorm(1 - 0.05/2) * sqrt(proportion * (1 - proportion) / n_patients)
  ) %>% 
  filter(!ethnic_group %in% c('Unknown/Not Stated')) %>%
  mutate(ethnic_group = str_wrap(ethnic_group, 10)) %>%
  ggplot(
    aes(
      x = age_at_referral, 
      y = 100 * proportion, 
      fill = ethnic_group, 
      group = ethnic_group
    )
  ) + 
  geom_ribbon(aes(ymin = 100 * lcl, ymax = 100 * ucl), alpha = 0.4) +
  ylab('Patients Remining\nThe Following Year [%]') +
  xlab('Patient Age At Referral') +
  ylim(0, NA) +
  labs(fill = 'Ethnic Group')

gridExtra::grid.arrange(
  gender, deprivation, ethnic_group,
  nrow = 3
)
