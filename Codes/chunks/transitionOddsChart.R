# Plot transition model odds ratios

transition_model_odds <- readRDS('output/transitionOdds.RData')

transition_model_odds %>%
  ggplot(aes(odds_ratio, variable_name)) + 
  geom_vline(
    aes(xintercept = 1),
    size = 0.5,
    linetype = 'dashed'
  ) +
  geom_errorbarh(
    aes(xmin = lcl, xmax = ucl),
    size = 1,
    height = 0
  ) + 
  geom_point(
    size = 1,
    colour = 'red'
  ) + 
  ylab('') + 
  xlab('Odds Ratio') +
  scale_x_log10(limits = c(2e-2, 5e1))