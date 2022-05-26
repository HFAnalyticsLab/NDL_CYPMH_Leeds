# Plot variable importance for ensemble model

variable_importance <- readRDS('output/variableImportance.RDS')
labels <- readRDS('output/variableLabels.RDS')

# Re-scale variables so that the overall score sums to 100
scale_var <- sum(variable_importance$overall)

variable_importance %>%
  mutate_if(is.numeric, ~ 100 * . / scale_var) %>%
  ggplot(aes(x = overall, y = reorder(variable, overall))) +
  geom_bar(stat = 'identity') +
  geom_errorbarh(aes(xmin = lcl, xmax = ucl)) +
  xlab('Importance') +
  ylab('') +
  scale_y_discrete(labels = labels)