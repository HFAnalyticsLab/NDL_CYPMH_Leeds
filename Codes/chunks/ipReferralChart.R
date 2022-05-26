# Plot referrals post-spell by age and date

p1 <- calls_and_spells %>%
  group_by(
    group = age,
    colour = 1
  ) %>%
  summarise(
    n_patients = n(),
    proportion = sum(referred_to_mh == 'N') / n_patients,
    lcl = proportion - 
      qnorm(1 - 0.05/2) * sqrt(proportion * (1 - proportion) / n_patients),
    ucl = proportion + 
      qnorm(1 - 0.05/2) * sqrt(proportion * (1 - proportion) / n_patients)
  ) %>% 
  ggplot(aes(x = group, y = 100 * proportion, colour = colour)) +
  geom_point() +
  geom_errorbar(
    aes(
      ymin = 100 * lcl,
      ymax = 100 * ucl
    )
  ) +
  theme(legend.position = 'none') +
  ylab('Patients Not Referred [%]') +
  xlab('Patient Age')

p2 <- calls_and_spells %>%
  ggplot(aes(crisis_date, fill = referred_to_mh), na.rm = TRUE) +
  geom_histogram(binwidth = 60) +
  theme(legend.position = 'none') +
  ylab('Patients') +
  xlab('Crisis Date') +
  ylim(0, NA)

suppressWarnings(gridExtra::grid.arrange(p1, p2, nrow = 1))