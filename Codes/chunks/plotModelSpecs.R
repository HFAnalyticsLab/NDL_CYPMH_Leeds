# Plot model comparison (XGBoost vs Ensemble) 

# Round to `round_no` places
round_no <- 5000

pf_df %>% 
  ggplot() + 
  geom_line(
    aes(xg_rec, xg_prec, group = model_run), 
    alpha = 0.05,
    na.rm = TRUE
  ) + 
  geom_line(
    aes(en_rec, en_prec, group = model_run), 
    alpha = 0.05, 
    colour = 'red',
    na.rm = TRUE
  ) + 
  geom_line(
    aes(xg_rec, xg_prec), 
    size = 1, 
    data = pf_df %>% 
      mutate(xg_rec = round(xg_rec * round_no) / round_no) %>% 
      group_by(xg_rec) %>% 
      summarise(xg_prec = mean(xg_prec, na.rm = TRUE))
  ) + 
  geom_line(
    aes(en_rec, en_prec), 
    size = 1, 
    data = pf_df %>% 
      mutate(en_rec = round(en_rec * round_no) / round_no) %>% 
      group_by(en_rec) %>% 
      summarise(en_prec = mean(en_prec, na.rm = TRUE)), 
    colour = 'red'
  ) + 
  geom_line(
    aes(recall, precision), 
    size = 1,
    colour = 'blue',
    lty = 'dashed',
    data = data.frame(recall = c(0, 1), precision = mean(y_test == 'N'))
  ) +
  xlab('Recall') +
  ylab('Precision')
