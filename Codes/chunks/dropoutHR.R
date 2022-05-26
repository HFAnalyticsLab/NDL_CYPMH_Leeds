# Load Cox and CRR models and display hazard ratios

crreg <- readRDS('models/crregPlusCox.RDS')

# Referral Team Type Not Stated has 0 dropouts, which causes the CI to explode
# For some reason R doesn't set its upper CI as infinity, so here change the
#   coefficient to make sure we don't get stupidly long numbers messing up our
#   table
crreg$`Cox PH`$var[18,18] <- 0

save_summary <- summary(
  crreg,
  html = TRUE, n = TRUE, ref = TRUE,
  htmlArgs = list(
    caption = 'Competing_Risk_Model',
    rgroup = c(
      'Ethnic Group', 
      'Gender', 
      'Mean IMD', 
      'CAMHS', 
      'Consultation Medium',
      'Referral Team Type',
      'Waiting Time'
    ),
    css.cell = 'white-space: nowrap; padding: 0px 5px 0px; text-overflow: ellipsis;'
  )
) %>%
  kableExtra::save_kable('dropoutHR.jpg', zoom = 1.5)