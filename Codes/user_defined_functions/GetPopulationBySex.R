get_population_by_sex <- function(year) {
  x <- ifelse(as.numeric(year) > 2017, 'x', '')
  
  # Female
  female_pop <- read_excel(
    paste0('data/population', year, paste0('.xls', x)),
    sheet = paste0('Mid-', year, ' Females'),
    skip = 4
  ) %>%
    select(
      lsoa_code = 1,
      lsoa_name = 2,
      female_population = `All Ages`,
      `0`:`90+`
    ) %>%
    distinct() %>%
    rowwise() %>%
    transmute(
      lsoa = lsoa_code,
      lsoa_name,
      female_pop_estimate = sum(
        !!!syms(as.character(11 : 25))
      ),
      female_child_estimate = sum(
        !!!syms(as.character(11 : 16))
      ),
      female_teen_estimate = sum(
        !!!syms(as.character(17 : 19))
      ),
      female_adult_estimate = sum(
        !!!syms(as.character(20 : 25))
      ),
      year = year
    )
  
  # Male
  male_pop <- read_excel(
    paste0('data/population', year, paste0('.xls', x)),
    sheet = paste0('Mid-', year, ' Males'),
    skip = 4
  ) %>%
    select(
      lsoa_code = 1,
      lsoa_name = 2,
      male_population = `All Ages`,
      `0`:`90+`
    ) %>%
    distinct() %>%
    rowwise() %>%
    transmute(
      lsoa = lsoa_code,
      lsoa_name,
      male_pop_estimate = sum(
        !!!syms(as.character(11 : 25))
      ),
      male_child_estimate = sum(
        !!!syms(as.character(11 : 16))
      ),
      male_teen_estimate = sum(
        !!!syms(as.character(17 : 19))
      ),
      male_adult_estimate = sum(
        !!!syms(as.character(20 : 25))
      ),
      year = year
    )
  
  # Total
  total_pop <- read_excel(
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
      child_estimate = sum(
        !!!syms(as.character(11 : 16))
      ),
      teen_estimate = sum(
        !!!syms(as.character(17 : 19))
      ),
      adult_estimate = sum(
        !!!syms(as.character(20 : 25))
      ),
      year = year
    )
  
  # Combined
  total_pop %>%
    left_join(female_pop, by = c('lsoa', 'lsoa_name', 'year')) %>%
    left_join(male_pop, by = c('lsoa', 'lsoa_name', 'year'))
}