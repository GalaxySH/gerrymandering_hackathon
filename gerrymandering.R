# Gerrymandering Hackathon
# Author: Stefan Hauge

#knitr::opts_chunk$set(echo = TRUE, message=FALSE, error = TRUE)
library(tidyverse)

data_file = "gerrymandering.csv"
output_file = "submission.csv"

data <- read.csv(data_file)

solution <- data %>%
  mutate(district = NA)

pop = sum(data$Population)
pop_low = 0.10 * pop
pop_high = 0.16 * pop

low_gop_first <- data %>%
  arrange(GOP_votes)

# assign districts
for (d in 1:8) {
  district_pop = 0
  district_counties = c()
  
  # algorithm: greedy
  for (i in 1:nrow(low_gop_first)) {
    county = low_gop_first[i, ]
    # if county hasn't been assigned to district
    if (!(county$County %in% solution$County[!is.na(solution$district)])) {
      # if adding county wouldn't put it over pop_high
      if (district_pop + county$Population <= pop_high) {
        district_pop = district_pop + county$Population
        district_counties = c(district_counties, county$County)
      }
    }
    if (district_pop >= pop_low) {
      break
    }
  }
  
  solution$district[solution$County %in% district_counties] <- d
}

# if any counties unassigned, assign them to the district with the lowest population
unassigned_counties <- solution$County[is.na(solution$district)]
for (county in unassigned_counties) {
  solution$district[solution$County == county] <- which.min(
    solution %>%
      filter(!is.na(district)) %>%
      group_by(district) %>%
      summarise(total_pop = sum(Population)) %>%
      pull(total_pop) # alternative to .$total_pop
  )
}

# display district populations
district_pops <- solution %>%
  group_by(district) %>%
  summarise(total_pop = sum(Population), num_counties = n())
  
# check for duplicated or missing districts
if (length(unique(solution$district)) != 8) {
  stop("Must have exactly 8 unique districts.")
}
if (any(is.na(solution$district))) {
  stop("Missing district assignments.")
}
if (nrow(solution) != 72 || length(unique(solution$County)) != 72) {
  stop("Must have exactly 72 unique counties.")
}

# if any districts overpopulated, swap counties with underpopulated districts
for (d in 1:8) {
  district_pop = district_pops$total_pop[district_pops$district == d]
  if (district_pop > pop_high) {
    # find the first district that if swapped would bring both districts within limits
    for (d2 in 1:8) {
      if (d != d2) {
        district2_pop = district_pops$total_pop[district_pops$district == d2]
        # find a county in district d that can be swapped with a county in district d2
        counties_d = solution$County[solution$district == d]
        counties_d2 = solution$County[solution$district == d2]
        for (county_d in counties_d) {
          county_d_pop = solution$Population[solution$County == county_d]
          for (county_d2 in counties_d2) {
            county_d2_pop = solution$Population[solution$County == county_d2]
            new_d_pop = district_pop - county_d_pop + county_d2_pop
            new_d2_pop = district2_pop - county_d2_pop + county_d_pop
            if (new_d_pop <= pop_high && new_d2_pop >= pop_low) {
              # perform the swap
              solution$district[solution$County == county_d] <- d2
              solution$district[solution$County == county_d2] <- d
              # update district populations
              district_pops$total_pop[district_pops$district == d] <- new_d_pop
              district_pops$total_pop[district_pops$district == d2] <- new_d2_pop
              # print a message
              cat("Swapped", county_d, "from district", d, "with", county_d2, "from district", d2, "\n")
              break
            }
          }
          if (district_pops$total_pop[district_pops$district == d] <= pop_high) {
            break
          }
        }
      }
    }
  }
}

# output to csv
write.csv(solution, output_file, row.names = FALSE)

# will require manual review
