# ML model tuning range

model_info <- tibble(
  model = c(
    'GLM (Binomial)',
    'RF',
    'SVM (Linear)',
    'NNET (Single Layer with Weight Decay)',
    'NNET (Single Layer with Weight Decay)',
    'XGBoost (Tree)',
    'XGBoost (Tree)',
    'XGBoost (Tree)',
    'XGBoost (Tree)',
    'XGBoost (Tree)',
    'XGBoost (Tree)',
    'XGBoost (Tree)',
    'XGBoost (Tree)',
    'XGBoost (Tree)'
  ),
  parameter = c(
    '', 
    'mtry', 
    'tau', 
    'size', 
    'decay', 
    'nrounds', 
    'max_depth', 
    'eta', 
    'gamma', 
    'colsample_bytree', 
    'min_child_weight', 
    'subsample', 
    'scale_pos_weight', 
    'max_delta_step'
  ),
  description = c(
    '', 
    'Number of Randomly Selected Predictors', 
    'Regularization Parameter', 
    'Number of Hidden Units', 
    'Weight Decay', 
    'Number of Boosting Iterations', 
    'Max Tree Depth', 
    'Shrinkage', 
    'Minimum Loss Reduction', 
    'Subsample Ratio of Columns', 
    'Minimum Sum of Instance Weight', 
    'Subsample Percentage', 
    'Positive Class Weight Scale [pw = Number of Referrals / Number of Non-Referrals]', 
    'Maximum Delta Step Value'
  ),
  tuning_range = c(
    '',
    '1 - 14 [number of variables]',
    '0.03125 - 1024',
    '1 - 20',
    '0.00001 - 10',
    'Fixed at 100',
    '5, 10',
    '0.25, 0.75',
    'Fixed at 0.1',
    'Fixed at 0',
    'Fixed at 1',
    'Fixed at 0.5',
    '0, 1.527 [SQRT(pw)], 2.331 [pw]',
    'Fixed at 0'
  )
)

model_info %>% 
  select(-model) %>% 
  rename_all(~str_to_title(str_replace_all(., '_', ' '))) %>% 
  knitr::kable(
    'html', 
    booktabs = TRUE,
    escape = FALSE
  ) %>% 
  kableExtra::column_spec(2:3, border_left = TRUE) %>% 
  kableExtra::pack_rows(index = table(fct_inorder(model_info$model))) %>% 
  kableExtra::kable_styling(full_width = FALSE) %>%
  kableExtra::save_kable('hyperparameters.jpg', zoom = 1.5)