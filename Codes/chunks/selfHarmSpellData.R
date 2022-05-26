# Get and pre-process data for inpatient spells for self-harm

if (!file.exists('output/saveCallsAndSpells.RDS')) {
  # Get IAPT referrals
  iapt_referrals <- get_query("
    WITH bridging AS (
    	SELECT Person_ID AS patient_id, PSEUDO_NHSNumber AS nhs_number FROM [Warehouse_LDM].[iapt].[Bridging]
    	UNION
    	SELECT Person_ID AS patient_id, Pseudo_NHS_Number AS nhs_number FROM [Warehouse_LDM].[iapt_v1.5].[Bridging]
    ),
    referrals AS (
    	(SELECT DISTINCT
    		COALESCE(Person_ID, LocalPatientId) AS patient_id,
    		ReferralRequestReceivedDate AS referral_date
    	FROM
    		[Warehouse_LDM].[iapt].[IDS101Referral])
    	UNION
    	(SELECT DISTINCT
    		IAPT_PERSON_ID AS patient_id,
    		REFRECDATE AS referral_date
    	FROM
    		[Warehouse_LDM].[iapt_v1.5].[Referral])
    )
    SELECT 
    	nhs_number,
    	referral_date
    FROM
    	referrals r
    LEFT JOIN bridging b ON	
    	r.patient_id = b.patient_id;
  ") %>%
    mutate(referral_date = as_date(referral_date)) %>%
    distinct()
  
  # Get GP referrals for mental health appointments
  gp_mh <- get_query("
    WITH emis_bridge AS (
    	SELECT * FROM [Warehouse_LDMPC].[dbo].[EMIS_Patients]
    ),
    tpp_bridge AS (
    	SELECT * FROM [Warehouse_LDMPC].[dbo].[TPP_Patients]
    )
    SELECT eb.Patient_Pseudonym AS nhs_number, ee.EffectiveDate AS referral_date
    FROM [Warehouse_LDMPC].[dbo].[EMIS_Event] ee
    JOIN emis_bridge eb ON ee.Leeds_CCG_Patient_ID = eb.Leeds_CCG_Patient_ID
    WHERE ReadCode LIKE 'E%'
    UNION
    SELECT tb.Patient_Pseudonym AS nhs_number, te.EventDate AS referral_date
    FROM [Warehouse_LDMPC].[dbo].[TPP_SRCodes_Extract] te
    JOIN tpp_bridge tb ON te.Leeds_CCG_Patient_ID = tb.Leeds_CCG_Patient_ID
    WHERE Version3Code LIKE 'E%';
  ") %>%
    mutate(referral_date = as_date(referral_date)) %>%
    distinct()
  
  # Combine MHSDS, IAPT, and GP referrals to get each person's referral date
  mhsds_iapt_gp <- bind_rows(
    select(referrals, nhs_number, referral_date),
    iapt_referrals,
    gp_mh
  )
  
  # Inpatient episode data for self harm
  for (fy in c('1617', '1718', '1819', '1920', '2021', '2122')) {
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
  
  referral_window <- weeks(1)
  
  # Get all spells for self harm which didn't end in patient death
  self_harm <- self_harm_spells %>%
    unite('secondary_diagnoses', starts_with('secondary'), remove = FALSE) %>%
    # filter(discharge_destination != '79') %>%
    group_by(nhs_number, spell_id) %>%
    summarise(
      nhs_number = first(nhs_number),
      age_band = first(ip_age_band),
      age = first(ip_age),
      admission_date = min(admission_date),
      discharge_date = min(discharge_date),
      los = (admission_date %--% discharge_date) / ddays(),
      lsoa = first(lsoa),
      ethnic_group = first(ethnic_group),
      sex = first(sex),
      bame = first(bame),
      self_discharge = first(discharge_method) == '2',
      spell = 1,
      possibly_unintentional = str_detect(
        paste(
          coalesce(first(secondary_1), 'Z000'),
          coalesce(first(secondary_2), 'Z000'),
          coalesce(first(secondary_3), 'Z000'),
          coalesce(first(secondary_4), 'Z000'),
          coalesce(first(secondary_5), 'Z000'),
          coalesce(first(secondary_6), 'Z000'),
          coalesce(first(secondary_7), 'Z000'),
          coalesce(first(secondary_8), 'Z000'),
          coalesce(first(secondary_9), 'Z000'),
          coalesce(first(secondary_10), 'Z000'),
          coalesce(first(secondary_11), 'Z000'),
          coalesce(first(secondary_12), 'Z000'),
          sep = ','
        ),
        'X62'
      ) | 
        str_detect(
          paste(
            coalesce(first(secondary_1), 'Z000'),
            coalesce(first(secondary_2), 'Z000'),
            coalesce(first(secondary_3), 'Z000'),
            coalesce(first(secondary_4), 'Z000'),
            coalesce(first(secondary_5), 'Z000'),
            coalesce(first(secondary_6), 'Z000'),
            coalesce(first(secondary_7), 'Z000'),
            coalesce(first(secondary_8), 'Z000'),
            coalesce(first(secondary_9), 'Z000'),
            coalesce(first(secondary_10), 'Z000'),
            coalesce(first(secondary_11), 'Z000'),
            coalesce(first(secondary_12), 'Z000'),
            sep = ','
          ),
          'X64'
        ),
      provider_id = first(provider_id),
      admission_window = admission_date + referral_window,
      self_poisoning = str_detect(secondary_diagnoses, 'X6'),
      self_harm = any(str_detect(secondary_diagnoses, c('X7', 'X8')))
    ) %>%
    ungroup()
  
  self_harm_referrals <- self_harm %>%
    left_join(mhsds_iapt_gp, by = 'nhs_number') %>%
    group_by(nhs_number, spell_id) %>%
    filter(
      between(referral_date, min(admission_date), min(admission_window))
    ) %>%
    summarise(referred_to_mh = 1) %>%
    ungroup()
  
  self_harm <- self_harm %>%
    left_join(self_harm_referrals, by = c('nhs_number', 'spell_id')) %>%
    mutate(referred_to_mh = coalesce(referred_to_mh, 0))
  
  # Just look at Leeds Teaching Hospitals
  self_harm <- self_harm %>% filter(provider_id == 'RR8')
  
  calls <- call_111 %>%
    mutate(
      age_band = case_when(
        between(age, 11, 16) ~ '11-16',
        between(age, 17, 19) ~ '17-19',
        between(age, 20, 25) ~ '20-25'
      )
    ) %>%
    # left_join(distinct(all_lsoa), by = 'nhs_number') %>%
    group_by(nhs_number, call_date) %>%
    summarise(
      nhs_number = first(nhs_number),
      age_band = first(age_band),
      age = first(age),
      # lsoa = first(lsoa),
      sex = first(sex),
      ethnic_group = first(ethnic_group_ordered),
      call = 1,
      call_window = call_date + referral_window
    ) %>%
    ungroup()
  
  #----
  
  # Combine IP and 111 data to get fuller picture of each attendance
  calls_and_spells <- self_harm %>%
    select(-admission_window) %>%
    full_join(
      calls %>%
        select(-call_window),
      by = c('nhs_number', 'admission_date' = 'call_date')
    )
  
  calls_and_spells <- calls_and_spells %>%
    transmute(
      nhs_number,
      crisis_date = admission_date,
      age = coalesce(age.x, age.y),
      age_band = coalesce(age_band.x, age_band.y),
      lsoa,
      sex = coalesce(sex.x, sex.y),
      ethnic_group = coalesce(ethnic_group.x, ethnic_group.y),
      los = pmin(coalesce(los, 0), quantile(los, 0.95, na.rm = TRUE)),
      self_discharge = coalesce(self_discharge, FALSE),
      possibly_unintentional,
      self_poisoning,
      self_harm,
      spell = coalesce(spell, 0),
      call = coalesce(call, 0),
      referred_to_mh
    ) %>%
    mutate(
      ethnic_group = case_when(
        str_detect(ethnic_group, 'Asian') ~ 'Asian or Asian British',
        str_detect(ethnic_group, 'Black') ~ 'Black or Black British',
        str_detect(ethnic_group, 'Mixed') ~ 'Mixed',
        str_detect(ethnic_group, 'Other') ~ 'Other ethnic group',
        str_detect(ethnic_group, 'White') ~ 'White',
        ethnic_group %in% c('', 'Unknown/Not Stated') | 
          is.na(ethnic_group) ~ 'Unknown/Not Stated',
        TRUE ~ ethnic_group
      ),
      sex = case_when(
        sex == '1' ~ 'M',
        sex == '2' ~ 'F',
        sex == '8' ~ 'Not Specified',
        TRUE ~ sex
      )
    )
  
  # Add deprivation data
  calls_and_spells <- calls_and_spells %>%
    left_join(select(imd, lsoa, imd_decile), by = 'lsoa') %>%
    select(-lsoa) 
  
  # Flag patients who were referred to MH services within a week
  calls_and_spells <- rownames_to_column(calls_and_spells) %>%
    mutate(
      referred_to_mh = factor(if_else(referred_to_mh == 1, 'Y', 'N'))
    ) %>%
    as.data.frame()
  
  # Flag patients already known to the MH service
  already_known <- calls_and_spells %>%
    left_join(mhsds_iapt_gp, by = 'nhs_number') %>%
    filter(referral_date < crisis_date - 1) %>%
    group_by(nhs_number, crisis_date) %>%
    summarise(known_to_mh = 1)
  
  calls_and_spells <- calls_and_spells %>%
    left_join(already_known, by = c('nhs_number', 'crisis_date')) %>%
    mutate(
      known_to_mh = coalesce(known_to_mh, 0)
    )
  
  # Flag patients who have been for at least one similar spell before
  calls_and_spells <- calls_and_spells %>%
    arrange(crisis_date) %>%
    group_by(nhs_number) %>%
    mutate(previous_crisis = row_number() > 1) %>%
    ungroup()
  
  # Filter to just IP spells (not 111 calls only), F/M patients, and patients 
  #   with NHS numbers
  calls_and_spells <- calls_and_spells %>%
    filter(spell %in% c(1), sex != '9', !is.na(nhs_number))
  
  # Calculate number of patient spells per seven days
  crises_past_week <- data.frame(
    crisis_date = as_date(min(calls_and_spells$crisis_date) : max(calls_and_spells$crisis_date)),
    n = 0
  ) %>% left_join(
    count(calls_and_spells, crisis_date),
    by = 'crisis_date'
  ) %>%
    transmute(
      crisis_date, 
      n = n.x + coalesce(n.y, 0), 
      crises_past_week = 
        coalesce(lag(n), 0) + 
        coalesce(lag(n, 2), 0) + 
        coalesce(lag(n, 3), 0) + 
        coalesce(lag(n, 4), 0) + 
        coalesce(lag(n, 5), 0) + 
        coalesce(lag(n, 6), 0) + 
        coalesce(lag(n, 7), 0)
    ) %>%
    select(-n)
  
  calls_and_spells <- calls_and_spells %>%
    left_join(crises_past_week, by = 'crisis_date')
  
  # Impute missing deprivation data (set to median value)
  calls_and_spells <- calls_and_spells %>%
    mutate(imd_decile = coalesce(imd_decile, median(imd_decile, na.rm = TRUE)))
  
  saveRDS(calls_and_spells, 'output/saveCallsAndSpells.RDS')
} else {
  calls_and_spells <- readRDS('output/saveCallsAndSpells.RDS')
}