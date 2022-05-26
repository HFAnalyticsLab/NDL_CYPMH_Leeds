# Plot mental health service retention by age

grouped_referrals <- cohort_referrals %>%
  rename(provider_name = provider_name.x) %>%
  # filter(
  #   provider_name %in% c(
  #     # 'LEEDS AND YORK PARTNERSHIP NHS FOUNDATION TRUST',
  #     # 'LEEDS COMMUNITY HEALTHCARE NHS TRUST',
  #     'COMMUNITY LINKS (NORTHERN) LTD',
  #     'NORTHPOINT WELLBEING LTD HQ',
  #     'THE MARKET PLACE (LEEDS)'
  #   )
  # ) %>%
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
  # filter(
  #   provider_name %in% c(
  #     # 'LEEDS AND YORK PARTNERSHIP NHS FOUNDATION TRUST',
  #     # 'LEEDS COMMUNITY HEALTHCARE NHS TRUST',
  #     'COMMUNITY LINKS (NORTHERN) LTD',
  #     'NORTHPOINT WELLBEING LTD HQ',
  #     'THE MARKET PLACE (LEEDS)'
  #   )
  # ) %>%
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

if (!appendix) {
  appendix <- TRUE
  # plot_transition <- grouped_referrals %>%
  #   filter(between(age_at_referral, 11, 25)) %>%
  #   group_by(age_at_referral) %>% 
  #   summarise(
  #     n_patients = n(),
  #     proportion = sum(contact_next_year) / n_patients,
  #     lcl = proportion - 
  #       qnorm(1 - 0.05/2) * sqrt(proportion * (1 - proportion) / n_patients),
  #     ucl = proportion + 
  #       qnorm(1 - 0.05/2) * sqrt(proportion * (1 - proportion) / n_patients)
  #   ) %>% 
  #   ggplot(aes(x = age_at_referral, y = 100 * proportion)) + 
  #   geom_point() +
  #   geom_errorbar(aes(ymin = 100 * lcl, ymax = 100 * ucl)) +
  #   ylab('Patients Remining The Following Year [%]') +
  #   xlab('Patient Age At Referral') +
  #   ylim(0, NA)
  
  if (file.exists('output/seenNextYear.RDS')) {
    seen_next_year <- readRDS('output/seenNextYear.RDS')
  } else {
    seen_next_year <- cohort_referrals %>% 
      filter(!is.na(nhs_number), !is.na(care_contact_date)) %>%
      mutate(mhsds_date = coalesce(care_contact_date, referral_date)) %>%
      distinct(nhs_number, mhsds_date, .keep_all = TRUE) %>%
      group_by(nhs_number) %>%
      mutate(
        contact_next_year = map_int(
          mhsds_date, 
          ~ sum(between(mhsds_date, .x %m+% years(1), .x %m+% years(2)))
        )
      ) %>%
      ungroup()
    
    saveRDS(seen_next_year, 'output/seenNextYear.RDS')
  }
  
  # Compare this proportion to the old figure
  plot_transition <- seen_next_year %>% 
    filter(
      year(mhsds_date %m-% months(3)) < 2020,
      between(age_at_contact, 11, 25)
    ) %>% 
    group_by(service_id, age = age_at_contact) %>% 
    summarise(
      n_patients = n_distinct(nhs_number),
      contact_next_year = sum(contact_next_year) > 0
    ) %>% 
    group_by(age) %>% 
    summarise(
      n_patients = sum(n_patients),
      proportion = sum(contact_next_year) / n_patients,
      lcl = proportion - 
        qnorm(1 - 0.05/2) * sqrt(proportion * (1 - proportion) / n_patients),
      ucl = proportion + 
        qnorm(1 - 0.05/2) * sqrt(proportion * (1 - proportion) / n_patients)
    ) %>% 
    ggplot() + 
    geom_point(aes(age, 100 * proportion)) +
    geom_errorbar(aes(age, ymin = 100 * lcl, ymax = 100 * ucl)) +
    ylim(0, NA) +
    ylab('Patients Still In contact The Following Year [%]') +
    xlab('Patient Age At Contact')
} else {
  # Show how many people had a care-contact one year after every care contact
  if (file.exists('output/seenNextYear.RDS')) {
    seen_next_year <- readRDS('output/seenNextYear.RDS')
  } else {
    seen_next_year <- cohort_referrals %>% 
      filter(!is.na(nhs_number)) %>%
      mutate(mhsds_date = coalesce(care_contact_date, referral_date)) %>%
      distinct(nhs_number, mhsds_date, .keep_all = TRUE) %>%
      group_by(nhs_number) %>%
      mutate(
        contact_next_year = map_int(
          mhsds_date, 
          ~ sum(between(mhsds_date, .x %m+% years(1), .x %m+% years(2)))
        )
      ) %>%
      ungroup()
    
    saveRDS(seen_next_year, 'output/seenNextYear.RDS')
  }
  
  # Compare this proportion to the old figure
  plot_transition <- seen_next_year %>% 
    filter(
      year(mhsds_date %m-% months(3)) < 2020, 
      between(age_at_referral, 11, 25)
    ) %>% 
    group_by(service_id, age = age_at_referral) %>% 
    summarise(
      n_patients = n_distinct(nhs_number),
      contact_next_year = sum(contact_next_year) > 0
    ) %>% 
    group_by(age) %>% 
    summarise(
      n_patients = sum(n_patients),
      proportion = sum(contact_next_year) / n_patients,
      lcl = proportion - 
        qnorm(1 - 0.05/2) * sqrt(proportion * (1 - proportion) / n_patients),
      ucl = proportion + 
        qnorm(1 - 0.05/2) * sqrt(proportion * (1 - proportion) / n_patients)
    ) %>% 
    ggplot() + 
    geom_ribbon(
      aes(age, ymin = 100 * lcl, ymax = 100 * ucl), 
      alpha = 0.4, 
      fill = 'red'
    ) +
    geom_ribbon(
      aes(age_at_referral, ymin = 100 * lcl, ymax = 100 * ucl), 
      fill = 'blue', 
      data = grouped_referrals %>%
        filter(
          between(age_at_referral, 11, 25), 
          year(referral_date %m-% months(3)) < 2020
        ) %>%
        group_by(age_at_referral) %>% 
        summarise(
          n_patients = n(),
          proportion = sum(contact_next_year) / n_patients,
          lcl = proportion - 
            qnorm(1 - 0.05/2) * sqrt(proportion * (1 - proportion) / n_patients),
          ucl = proportion + 
            qnorm(1 - 0.05/2) * sqrt(proportion * (1 - proportion) / n_patients)
        ),
      alpha = 0.4
    ) + 
    ylim(0, NA) +
    ylab('Patients Remining The Following Year [%]') +
    xlab('Patient Age At Referral')
}

plot_transition
