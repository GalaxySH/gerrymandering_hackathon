# Gerrymandering Hackathon

## My params

1. Optimizing for 'Rep'

## Instructions

This week, we'll try our hand at gerrymandering Wisconsin House districts to demonstrate how easy it is. Your tasks will be to:

1.    Choose a party to maximize seats for (Democrats 'Dem' or Republicans 'GOP')
    Use the supplied data 
2.    Download data as a basis for this
3.    Maximize the number of districts anticipated to win for your chosen party.
4.    I'll infer which party you chose based on the results

We have constraints:

1.    Exactly 8 districts, with 8 unique labels provided by you in a column you'll add to the csv file with the column name 'district' that will tell me which county (row) is assigned to which district
2.    Each district can have no less than 10% of the state's total population in it
3.    Each district can have no more than 16% of the state's total population in it
4.    Districts do not have to be contiguous; you can group any counties into a district no matter where they are in Wisconsin (interestingly, the WI constitution does not stipulate that federal House districts need to be contiguous)

Data definitions from the file I provided:

-    County: Name of the Wisconsin county
-    Population: 2020 Census population. Used for testing the 10-16% population constraints.
-    Votes: Total votes for any presidential candidate in the 2024 election
-    Dem_votes: Total votes for Harris in 2024
-    GOP_votes: Total votes for Trump in 2024
-    Partisan_votes: Sum of the values from GOP_votes and Dem_votes columns for each county. Used for simulating votes as described below
-    p_gop: Proportion: Trump votes / (Trump votes + Harris votes). Used in simulating votes as described below
-    density: Population per square mile (used to identify rural/urban counties)

We'll be simulating 10,000 elections to see which submissions have the most House districts, on average, in our simulated elections.

There are five sets of simulations, each with 2000 simulated votes:

1.    Baseline: I'll randomly sample for each county the number of Dem vs. GOP votes by drawing a proportion of the votes for each party from a random normal distribution with its mean centered around the GOP / (GOP + Dem) votes for each county with a standard deviation of 0.05 (this was calculated from polling data in the 2024 election), and multiply this proportion by the total number of voters from the Dem_votes and GOP_votes column. Dem votes will be calculated as the total number of votes from those columns minus the GOP votes as calculated above. 
2.    GOP surge: As in baseline, but I'll add 0.03 to the GOP / (GOP + Dem) vote proportion
3.    Dem surge: As in baseline, but I'll subtract 0.03 to the GOP / (GOP + Dem) vote proportion
4.    Rural turnout: As in baseline, but I'll add 5% to the number of voters in counties with <= 100 residents per square mile
5.    Urban turnout: As in baseline, but I'll add 5% to the number of voters in counties with > 100 residents per square mile

This will be a competition, with the top 3 GOP and top 3 Dem submissions being highlighted next week. Your submission has to have the following requirements to be eligible:

1.    csv file
2.    72 rows with the names of the counties represented identically as the ones I provided in the 'County' column, and the name of this column must still be 'County'. The order of the counties does not matter for simulation purposes, so you can reorder rows if you like
3.    A column named 'district' with each row assigned to exactly one district label, and this column must have exactly eight unique values
4.    I'll pull the rest of the necessary data from the original dataset for the calculations
5.    Must be able to import into R with the read.csv() method. This should be easy as long as you don't annotate notes into the csv file that you submit.
6.    Submission name: If you want a codename for your submission, include it in the filename with two leading underscores and two trailing underscores. Example: "__theAwesomestGroupingEver__.csv". Otherwise, the name of the file doesn't matter.
