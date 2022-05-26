# Load full model specs (ROC, AUC, PR, etc) and aggregate

pf_df <- readRDS('output/modelSpecs.RDS')
y_test <- readRDS('output/testY.RDS')

# Calculate AUCs and PR-AUCs
auc <- pf_df %>% 
  group_by(model_run) %>% 
  summarise(
    xg_auc = sum(diff(xg_spec[order(xg_spec)])*rollmean(xg_sens[order(xg_spec)], 2), na.rm = T),
    en_auc = sum(diff(en_spec[order(en_spec)])*rollmean(en_sens[order(en_spec)], 2), na.rm = T),
    xg_pr_auc = sum(diff(xg_rec[order(xg_rec)])*rollmean(xg_prec[order(xg_rec)], 2), na.rm = T),
    en_pr_auc = sum(diff(en_rec[order(en_rec)])*rollmean(en_prec[order(en_rec)], 2), na.rm = T),
    no_skill_pr_auc = mean(y_test == 'N')
  )

# Calculate 95% confidence interval on all AUCs, rounded to 2 d.p.
auc_ci <- auc %>%
  select(-model_run) %>%
  summarise_all(~ quantile(., c(0.025, 0.5, 0.975))) %>%
  mutate_all(~ format(round(., digits = 2), nsmall = 2))