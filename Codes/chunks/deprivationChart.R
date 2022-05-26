# Plot breakdown of service by deprivation decile
# Percentage of patients from each deprivation decile
r1 <- referrals_by_imd %>%
  ggplot() + 
  geom_point(aes(imd_decile, 100 * proportion)) +
  geom_errorbar(aes(imd_decile, 100 * proportion, ymin = 100 * lcl, ymax = 100 * ucl)) +
  ylim(0, NA) +
  xlab('Deprivation Decile') +
  ylab('Population Percentage')

# Number of crises per patient
r2 <- referrals_by_imd %>%
  ggplot() + 
  geom_point(aes(imd_decile, crises_per_patient)) +
  geom_errorbar(aes(imd_decile, crises_per_patient, ymin = cpp_lcl, ymax = cpp_ucl)) +
  ylim(0, NA) +
  xlab('Deprivation Decile') +
  ylab('Crises per Patient')

# Number of referrals per patient
# Hacky way to get uncertainties, not too sure this is correct so look at later
r3 <- referrals_by_imd %>%
  mutate(
    rpp_lcl = referrals_per_patient - sqrt(n_referrals) / n_patients,
    rpp_ucl = referrals_per_patient + sqrt(n_referrals) / n_patients
  ) %>%
  ggplot() + 
  geom_point(aes(imd_decile, referrals_per_patient)) +
  geom_errorbar(aes(imd_decile, referrals_per_patient, ymin = rpp_lcl, ymax = rpp_ucl)) +
  ylim(0, NA) +
  xlab('Deprivation Decile') +
  ylab('Referrals per Patient')

# Number of crises per referral
r4 <- referrals_by_imd %>%
  ggplot() + 
  geom_point(aes(imd_decile, crises_per_referral)) +
  geom_errorbar(aes(imd_decile, crises_per_referral, ymin = cpr_lcl, ymax = cpr_ucl)) +
  ylim(0, NA) +
  xlab('Deprivation Decile') +
  ylab('Crises per Referral')

gridExtra::grid.arrange(r1, r2, r3, r4)