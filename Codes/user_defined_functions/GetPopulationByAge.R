get_population_by_age <- function(year) {
  x <- ifelse(as.numeric(year) > 2017, 'x', '')
  
  read_excel(
    paste0('data/population', year, paste0('.xls', x)),
    sheet = paste0('Mid-', year, ' Persons'),
    skip = 4
  ) %>%
    select(
      lsoa = 1,
      lsoa_name = 2,
      `11`:`25`
    ) %>%
    distinct() %>%
    mutate(
      year = year
    )
}