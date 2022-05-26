# Set up Rmd data

knitr::opts_chunk$set(message = FALSE, warning = FALSE, echo = FALSE)
need_packages <- c(
  'config',
  'MASS',
  'zoo',
  'readxl',
  'tidyverse',
  'lubridate',
  'odbc',
  'survival',
  'survminer',
  'cmprsk2',
  'tictoc',
  'htmlTable',
  'fingertipsR',
  'geographr',
  'PHEindicatormethods',
  'hms'
)

lapply(need_packages, library, character.only = TRUE)

options(stringsAsFactors = FALSE)
options(dplyr.summarise.inform = FALSE)

config <- get()

# Load custom functions
invisible(
  lapply(
    Sys.glob('user_defined_functions/*.R'),
    function(x) source(x)
  )
)

appendix <- FALSE

if (file.exists('output/reportData.RData')) {
  load('output/reportData.RData')
} else {
  referrals <- get_query(read_file('sql/GetReferrals.sql')) %>%
    mutate(
      referral_date = ymd(referral_date),
      discharge_date = ymd(discharge_date),
      referral_closed_date = ymd(referral_closed_date)
    )
  
  contacts <- get_query(read_file('sql/GetCareContacts.sql')) %>%
    mutate(
      dna_flag = if_else(
        attendance_type %in% c(
          'Did not attend - no advance warning given',
          'Patient arrived late and could not be seen'
        ),
        TRUE,
        FALSE
      ),
      care_contact_date = ymd(care_contact_date)
    )
  
  patients <- get_query(read_file('sql/GetPatients.sql'))
  
  activity <- get_query(read_file('sql/GetCareActivity.sql')) %>%
    mutate(
      report_date = ymd(report_date)
    )
  
  call_111 <- get_query(read_file('sql/Get111Calls2.sql')) %>%
    mutate(
      call_datetime = call_date,
      call_date = as_date(call_date),
      ethnic_group = case_when(
        ethnicity == 'Asian Background' ~ 'Asian or Asian British',
        ethnicity == 'Black Background' ~ 'Black or Black British',
        ethnicity == 'Chinese & Other Background' ~ 'Asian or Asian British',
        ethnicity == 'Ethnicity Not Known/Not Recorded' ~ 'Unknown/Not Stated',
        ethnicity == 'Mixed Background' ~ 'Mixed',
        ethnicity == 'White Background' ~ 'White',
        ethnicity == '' ~ 'Unknown/Not Stated',
        is.na(ethnicity) ~ 'Unknown/Not Stated',
        ethnicity == '' ~ 'Unknown/Not Stated',
        TRUE ~ ethnicity
      ),
      ethnic_group_census = case_when(
        ethnic_group == 'Mixed' ~ 'Mixed/multiple ethnic groups',
        ethnic_group == 'White' ~ 'White',
        ethnic_group == 'Asian or Asian British' ~ 'Asian/Asian British',
        ethnic_group == 'Black or Black British' ~ 'Black/African/Caribbean/Black British',
        ethnic_group == 'Other ethnic groups' ~ 'Other ethnic group',
        TRUE ~ 'Unknown/Not Stated'
      )
    )
  
  # Sometimes patients are recorded with multiple ethnicities, here we select one
  #   ethnicity per patient
  call_111 <- call_111 %>% 
    mutate(
      ethnicity_order = case_when(
        ethnic_group_census == 'Unknown/Not Stated' ~ 1,
        ethnic_group_census == 'White' ~ 2,
        TRUE ~ 3
      )
    ) %>%
    arrange(-ethnicity_order) %>%
    group_by(nhs_number) %>%
    mutate(ethnic_group_ordered = first(ethnic_group_census)) %>%
    ungroup()
  
  # Filter to date range and remove duplicates
  call_111 <- call_111 %>%
    filter(between(call_date, ymd('2016-04-01'), ymd('2021-03-31'))) %>%
    distinct(nhs_number, call_datetime, symptom_1, .keep_all = TRUE)
  
  call_111 <- call_111 %>%
    mutate(
      call_time = as_hms(call_datetime),
      bame = !ethnic_group_ordered %in% c('White', 'Unknown/Not Stated'),
      age_band = case_when(
        between(age, 11, 16) ~ '11-16',
        between(age, 17, 19) ~ '17-19',
        between(age, 20, 25) ~ '20-25'
      )
    )
  
  # Load in deaths data
  deaths <- get_query(read_file('sql/GetDeaths.sql')) %>% 
    arrange(
      -case_when(
        coalesce(ethnic_group, '') %in% c('Unknown/Not Stated', '') ~ 1,
        ethnic_group == 'White' ~ 2,
        TRUE ~ 3
      )
    ) %>%
    group_by(nhs_number) %>%
    mutate(ethnic_group = first(ethnic_group)) %>%
    ungroup() %>%
    distinct() %>%
    mutate(
      date_of_death = ymd(date_of_death),
      bame = !coalesce(ethnic_group, '') %in% c('White', '')
    )
  
  # Load indices of deprivation and remove health component to calculate imd
  iod <- read_excel('data/IoD2019.xlsx') %>%
    select(
      lsoa = 1,
      income_score = 5,
      employment_score = 6,
      education_score = 7,
      health_score = 8,
      crime_score = 9,
      barriers_score = 10,
      living_environment_score = 11
    )
  
  imd <- iod %>% 
    transmute(
      lsoa,
      imd_score = (0.225 * income_score +
                     0.225 * employment_score +
                     0.135 * education_score +
                     #			0.135 * health_score +
                     0.093 * crime_score +
                     0.093 * barriers_score + 
                     0.093 * living_environment_score) / 0.864,
      imd_score_unscaled = 0.225 * income_score +
        0.225 * employment_score +
        0.135 * education_score +
        0.135 * health_score +
        0.093 * crime_score +
        0.093 * barriers_score + 
        0.093 * living_environment_score,
      imd_decile = ntile(imd_score, 10),
      imd_decile_unscaled = ntile(imd_score_unscaled, 10),
      imd_quartile = ntile(imd_score, 4),
      imd_quartile_unscaled = ntile(imd_score_unscaled, 4)
    )
  
  #----
  # Filtering to only those aged 11 - 25 at some point within the last few years
  
  cohort_id <- referrals %>%
    filter(
      between(age_at_referral, 11, 25)
    ) %>%
    distinct(patient_id)
  
  cohort_patients <- patients %>%
    semi_join(cohort_id, by = 'patient_id')
  
  # Get activities
  cohort_activities <- activity %>%
    group_by(care_contact_id) %>%
    summarise(most_common_procedure = mode(term)) %>%
    ungroup()
  
  # Look at referrals and join on care-contacts
  cohort_referrals <- cohort_patients %>% 
    left_join(referrals, by = 'patient_id') %>%
    left_join(contacts, by = c('patient_id', 'service_id')) %>%
    left_join(cohort_activities, by = c('care_contact_id')) %>%
    left_join(imd, by = 'lsoa')
  
  # Filter to just referrals for LYPFT and LCH within date range
  cohort_referrals <- cohort_referrals %>%
    filter(
      provider_name.x %in% c(
        'LEEDS AND YORK PARTNERSHIP NHS FOUNDATION TRUST',
        'LEEDS COMMUNITY HEALTHCARE NHS TRUST'
      ),
      !is.na(patient_id),
      gender != 'Home leave',
      between(referral_date, ymd('2016-04-01'), ymd('2021-03-31'))
    )
  
  cohort_referrals <- cohort_referrals %>%
    mutate(
      ethnic_group = case_when(
        ethnicity == 'White and Black Caribbean' ~ 'Mixed/multiple ethnic groups',
        ethnicity == 'White and Black African' ~ 'Mixed/multiple ethnic groups',
        ethnicity == 'White and Asian' ~ 'Mixed/multiple ethnic groups',
        ethnicity == 'Any other mixed background' ~ 'Mixed/multiple ethnic groups',
        ethnicity == 'British' ~ 'White',
        ethnicity == 'Irish' ~ 'White',
        ethnicity == 'Any other white background' ~ 'White',
        ethnicity == 'Indian' ~ 'Asian/Asian British',
        ethnicity == 'Pakistani' ~ 'Asian/Asian British',
        ethnicity == 'Bangladeshi' ~ 'Asian/Asian British',
        ethnicity == 'Chinese' ~ 'Asian/Asian British',
        ethnicity == 'Any other Asian background' ~ 'Asian/Asian British',
        ethnicity == 'African' ~ 'Black/African/Caribbean/Black British',
        ethnicity == 'Carribbean' ~ 'Black/African/Caribbean/Black British',
        ethnicity == 'Any other black background' ~ 'Black/African/Caribbean/Black British',
        ethnicity == 'Any other ethnic group' ~ 'Other ethnic group',
        TRUE ~ 'Unknown/Not Stated'
      ),
      bame = !ethnic_group %in% c('White', 'Unknown/Not Stated')
    )
  
  #----
  # Ethnicity rates compared to PHE ethnic proportions
  
  ethnicity_msoa <- fingertips_data(93087, AreaTypeID = 3) %>%
    select(
      msoa_name = AreaName,
      proportion = Value,
      lcl = `LowerCI95.0limit`,
      ucl = `UpperCI95.0limit`
    )
  
  referrals_by_msoa <- cohort_referrals %>%
    left_join(geographr::lookup_lsoa_msoa, by = c('lsoa' = 'lsoa_code')) %>%
    group_by(nhs_number) %>%
    summarise(
      msoa_name = first(msoa_name),
      gender = first(gender),
      n_referrals = n_distinct(service_id),
      ethnic_group = first(ethnic_group),
      n_crisis = n_distinct(service_id[
        coalesce(str_detect(referral_team_type, 'Crisis'), FALSE)
      ])
    ) %>%
    group_by(msoa_name) %>%
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
    )
  
  referrals_by_lsoa <- cohort_referrals %>%
    group_by(nhs_number) %>%
    summarise(
      lsoa = first(lsoa),
      gender = first(gender),
      n_referrals = n_distinct(service_id),
      ethnic_group = first(ethnic_group),
      bame = first(bame),
      n_crisis = n_distinct(service_id[
        coalesce(str_detect(referral_team_type, 'Crisis'), FALSE)
      ])
    ) %>%
    group_by(lsoa) %>%
    summarise(
      n_patients = n_distinct(nhs_number),
      n_non_white_referrals = sum(n_referrals[bame]),
      n_referrals = sum(n_referrals),
      n_non_white = sum(bame),
      n_crisis = sum(n_crisis)
    ) %>%
    mutate(
      prop_non_white = n_non_white / n_patients,
      prop_non_white_referrals = n_non_white_referrals / n_referrals
    ) %>%
    left_join(
      population_lsoa_ethnicity_census %>%
        group_by(lsoa_code) %>%
        summarise(
          pop_census = sum(n_people),
          pop_non_white_census = sum(n_people[ethnicity != 'White'])
        ) %>%
        mutate(
          prop_non_white_census = pop_non_white_census / pop_census
        ),
      by = c('lsoa' = 'lsoa_code')
    )
  
  #----
  # Referrals by IMD (SII/RII)
  referrals_lsoas <- cohort_referrals %>%
    count(lsoa) %>%
    filter(n > 25)
  
  referrals_by_imd <- cohort_referrals %>%
    semi_join(referrals_lsoas, by = 'lsoa') %>%
    group_by(lsoa) %>%
    summarise(
      imd_decile = mode(imd_decile),
      n_patients = n_distinct(nhs_number),
      n_referrals = n_distinct(service_id),
      n_crisis = n_distinct(service_id[
        coalesce(str_detect(referral_team_type, 'Crisis'), FALSE)
      ])
    ) %>%
    left_join(
      population_lsoa %>%
        rowwise() %>%
        transmute(
          lsoa = lsoa_code,
          lsoa_name,
          pop_estimate = sum(
            !!!syms(as.character(11 : 25))
          ),
        ),
      by = 'lsoa'
    ) %>%
    group_by(imd_decile) %>%
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
      rpp_lcl = referrals_per_patient - qnorm(1 - 0.05 / 2) * sqrt(
        referrals_per_patient * (1 - referrals_per_patient) / n_patients
      ),
      rpp_ucl = referrals_per_patient + qnorm(1 - 0.05 / 2) * sqrt(
        referrals_per_patient * (1 - referrals_per_patient) / n_patients
      ),
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
  
  patient_sii <- phe_sii(
    referrals_by_imd,
    imd_decile,
    pop_estimate,
    value = proportion,
    lower_cl = lcl,
    upper_cl = ucl,
    value_type = 2,
    multiplier = 100,
    rii = TRUE
  )
  
  crisis_sii <- phe_sii(
    referrals_by_imd,
    imd_decile,
    n_patients,
    value = crises_per_patient,
    lower_cl = cpp_lcl,
    upper_cl = cpp_ucl,
    value_type = 1,
    multiplier = 100,
    rii = TRUE
  )
  
  crisis_per_referral_sii <- phe_sii(
    referrals_by_imd,
    imd_decile,
    n_referrals,
    value = crises_per_referral,
    lower_cl = cpr_lcl,
    upper_cl = cpr_ucl,
    value_type = 2,
    multiplier = 100,
    rii = TRUE
  )
  
  #----
  # Inpatient episode data for self harm
  
  for (fy in c('1617', '1718', '1819', '1920', '2021')) {
    if (fy == '1617') self_harm_spells <- tibble()
    
    self_harm_spells <- get_query(
      str_replace_all(
        read_file("sql/GetSelfHarmSpells.sql"),
        c(
          "<XYXY>" = fy
        )
      )
    ) %>%
      mutate(
        admission_date = ymd(admission_date),
        discharge_date = ymd(discharge_date),
        episode_start_date = ymd(episode_start_date),
        episode_end_date = ymd(episode_end_date),
        bame = !coalesce(ethnic_group, '') %in% c('White', ''),
        ip_age_band = case_when(
          ip_age < 17 ~ '11-16',
          ip_age < 20 ~ '17-19',
          TRUE ~ '20-25'
        )
      ) %>%
      bind_rows(self_harm_spells)
  }
  
  save.image('output/reportData.RData')
}