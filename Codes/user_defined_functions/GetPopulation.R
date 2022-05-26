get_population <- function(year) {
  if (year == '2019') {
    return(
      population_lsoa %>%
        rowwise() %>%
        transmute(
          lsoa = lsoa_code,
          lsoa_name,
          pop_estimate = sum(
            !!!syms(as.character(11 : 25))
          ),
          year = year
        )
    )
  }
  x <- ''
  if (as.numeric(year) > 2017) x <- 'x'
  
  read_excel(
    paste0('data/population', year, paste0('.xls', x)),
    sheet = paste0('Mid-', year, ' Persons'),
    skip = 4
  ) %>%
    select(
      lsoa_code = 1,
      lsoa_name = 2,
      total_population = `All Ages`,
      `0`:`90+`
    ) %>%
    distinct() %>%
    rowwise() %>%
    transmute(
      lsoa = lsoa_code,
      lsoa_name,
      pop_estimate = sum(
        !!!syms(as.character(11 : 25))
      ),
      year = year
    )
}