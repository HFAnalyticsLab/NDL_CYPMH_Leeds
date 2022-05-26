
referral_hist <- read_excel("output/figure_outputs/Output_4-2ts_Tables_Leeds1.xlsx") %>% 
  mutate(
    ts_ym = lubridate::ym(ts_ym),
    type = case_when(
      type == 'servdisch' ~ 'Discharge',
      type == 'servreqs' ~ 'Referral'
    ),
    segment = case_when(
      ts_ym >= ymd('2020-09-01') ~ 'S3',
      ts_ym >= ymd('2020-03-01') ~ 'S2',
      TRUE ~ 'S1'
    )
  )

referral_hist %>%
  ggplot() +
  geom_ribbon(
    aes(ts_ym, ymin = minv, ymax = value, fill = segment), 
    alpha = 0.2, 
    data = mutate(
      distinct(referral_hist, ts_ym, segment), 
      value = max(referral_hist$number.std), 
      minv = 1
    )
  ) +
  geom_line(aes(ts_ym, number.std, colour = type), size = 1) +
  geom_smooth(
    aes(ts_ym, number.std, colour = type, group = paste(segment, type)),
    method = 'lm',
    se = FALSE, 
    size = 1,
    lty = 'twodash',
    data = referral_hist %>% filter(segment != 'S2')
  ) +
  xlab('') +
  ylab('Referrals/Discharges per Person') +
  ylim(1, max(referral_hist$number.std))
