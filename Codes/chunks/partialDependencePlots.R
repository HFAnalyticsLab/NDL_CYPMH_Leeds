# Plot partial dependence plots
pd_plots <- readRDS('output/partialDependenceplots.RDS')

# Show top `n_plots` variable PDPs
n_plots <- 6

do.call(
  gridExtra::grid.arrange, 
  c(pd_plots[names(rev(labels)[1 : n_plots])], ncol = 2)
)