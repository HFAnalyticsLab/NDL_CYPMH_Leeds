# Plot gender split of patient counts & referrals by age

p1 <- cohort_referrals %>%
  distinct(nhs_number, .keep_all = TRUE) %>% 
  count(age_at_referral, gender) %>% 
  group_by(age_at_referral) %>% 
  mutate(proportion = 100 * n / sum(n)) %>% 
  filter(between(age_at_referral, 11, 25)) %>% 
  ggplot() + 
  geom_line(aes(age_at_referral, proportion, colour = gender), size = 1) + 
  ylim(0, 100) +
  xlab('Age at First Referral') +
  ylab('Proportion of\nTotal Patients [%]')

p2 <- cohort_referrals %>% 
  count(age_at_referral, gender) %>% 
  group_by(age_at_referral) %>% 
  mutate(proportion = 100 * n / sum(n)) %>% 
  filter(between(age_at_referral, 11, 25)) %>% 
  ggplot() + 
  geom_line(aes(age_at_referral, proportion, colour = gender), size = 1) + 
  ylim(0, 100) +
  xlab('Age') +
  ylab('Proportion of Total\nCare Contacts [%]')

p3 <- cohort_referrals %>%
  distinct(nhs_number, .keep_all = TRUE) %>%
  filter(between(age_at_referral, 11, 25)) %>%
  ggplot() +
  geom_bar(aes(age_at_referral, fill = gender)) +
  xlab('Age at First Referral') +
  ylab('Number of Service\nUsers Referred')

gridExtra::grid.arrange(gridExtra::grid.arrange(p1, p2, nrow = 1), p3, nrow = 2)
