# ============================================================
# Wisconsin Gerrymandering Simulation Competition
# ============================================================
# Requires:
#   - "wi_data.csv" : base data with County, Population, Dem_votes, GOP_votes, density
#   - "submission.csv" : your file with 'County' and 'district' columns
# Output:
#   - Average Dem-won districts overall and by scenario
# ============================================================

set.seed(43244)

# -----------------------------
# 1. Load and check data
# -----------------------------
base <- read.csv("gerrymandering.csv", stringsAsFactors = FALSE)
subm <- read.csv("__supergroup5__.csv", stringsAsFactors = FALSE)

# Merge to align submission with base data
dat <- merge(base, subm, by = "County")

# Basic checks
if (length(unique(dat$district)) != 8) stop("Must have exactly 8 unique districts.")
if (any(is.na(dat$district))) stop("Missing district assignments.")
if (nrow(dat) != 72) stop("Must have exactly 72 counties.")

# -----------------------------
# 2. Precompute constants
# -----------------------------
state_pop <- sum(dat$Population.x)
lower_pop <- 0.10 * state_pop
upper_pop <- 0.16 * state_pop

# Population constraint check
district_pops <- tapply(dat$Population.x, dat$district, sum)
if (any(district_pops < lower_pop) || any(district_pops > upper_pop))
  warning("Population constraints violated. Some districts out of range.")

# -----------------------------
# 3. Helper function: simulate one scenario
# -----------------------------
simulate_scenario <- function(dat, add_gop_prop = 0, turnout_adj = NULL, reps = 2000) {
  # dat: merged dataset
  # add_gop_prop: shift in GOP proportion (positive = GOP surge, negative = Dem surge)
  # turnout_adj: vector of multiplicative turnout adjustments by county (length 72)
  
  n_districts <- length(unique(dat$district))
  dem_wins <- numeric(reps)
  
  for (r in seq_len(reps)) {
    # Adjusted GOP proportion
    p_gop <- pmin(pmax(dat$p_gop.x + add_gop_prop, 0), 1)
    
    # Adjusted turnout
    turnout_mult <- if (is.null(turnout_adj)) rep(1, nrow(dat)) else turnout_adj
    total_votes <- dat$Partisan_votes.x * turnout_mult
    
    # Simulate random GOP proportion from Normal(mean=p_gop, sd=0.05)
    gop_prop <- rnorm(nrow(dat), mean = p_gop, sd = 0.05)
    gop_prop <- pmin(pmax(gop_prop, 0), 1)  # clip to [0,1]
    
    gop_votes <- total_votes * gop_prop
    dem_votes <- total_votes - gop_votes
    
    # Aggregate by district
    # district_results <- aggregate(cbind(dem_votes, gop_votes) ~ district, FUN = sum)
    district_results <- data.frame(
      district = unique(dat$district),
      dem_votes = tapply(dem_votes, dat$district, sum),
      gop_votes = tapply(gop_votes, dat$district, sum)
    )
    
    # Count Dem-won districts
    # dem_wins[r] <- sum(district_results$dem_votes > district_results$gop_votes)
    district_results$dem_won <- district_results$dem_votes > district_results$gop_votes
    dem_wins[r] <- sum(district_results$dem_won)
  }
  mean(dem_wins)
}

# -----------------------------
# 4. Scenario simulations
# -----------------------------
reps <- 2000

# Base scenario (no turnout shift)
mean_baseline <- simulate_scenario(dat, reps = reps)

# GOP surge (+0.03)
mean_gop_surge <- simulate_scenario(dat, add_gop_prop = 0.03, reps = reps)

# Dem surge (-0.03)
mean_dem_surge <- simulate_scenario(dat, add_gop_prop = -0.03, reps = reps)

# Rural turnout (+5% if density <= 100)
turnout_rural <- ifelse(dat$density <= 100, 1.05, 1)
mean_rural <- simulate_scenario(dat, turnout_adj = turnout_rural, reps = reps)

# Urban turnout (+5% if density > 100)
turnout_urban <- ifelse(dat$density > 100, 1.05, 1)
mean_urban <- simulate_scenario(dat, turnout_adj = turnout_urban, reps = reps)

# -----------------------------
# 5. Combine and report results
# -----------------------------
scenario_means <- c(
  baseline = mean_baseline,
  GOP_surge = mean_gop_surge,
  Dem_surge = mean_dem_surge,
  Rural_turnout = mean_rural,
  Urban_turnout = mean_urban
)

overall_mean <- mean(scenario_means)

cat("====================================\n")
cat("Average Dem-Won Districts (out of 8)\n")
cat("====================================\n")
print(round(scenario_means, 3))
cat("------------------------------------\n")
cat(sprintf("Overall average: %.3f\n", overall_mean))
cat("====================================\n")
