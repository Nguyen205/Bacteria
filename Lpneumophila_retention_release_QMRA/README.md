# SYNOPSIS
QMRA raw data and code used for Clark, G.G., Coey, E.J., Loya, A.C., Nguyen, T.H. (2026) "A quantitative microbial risk assessment of activated carbon point-of-use filters and the risk Legionella pneumophila.” Water Research.


## SETUP
  Requires R 4.3 or higher (tested on 4.3.1)
  Requires packages
	'dplyr'
	'stats'
	'EnvStats'
	'truncnorm'
	'sensobol'
  Use `install.packages('')` for the packages above
  
  In the root folder, open `Leg_ret_rel_QMRA.R`
	Run Lines 1-5 to add necessary packages to library
	Run Lines 6-14 to add prepared functions to environment

## DESCRIPTION OF FILES
Leg_ret_rel_QMRA.R - Main file for running QMRA, loads libraries and functions
prepare_parcel.R - Assembles model parameters based on independent variables
orgdat.R - short function for sorting or subsetting data
bind_df.R - organizational method, binds two lists of dataframes
calc_stats.R - calculates stats (mean, median, quantile, std dev) on data
round_robin_wilk.R - performs Wilcoxon tests on data comparing each set to another
sens_an_spearman.R - performs sensitivity analysis between scenarios (separate scenarios)
mc_with_param_input.R - performs sensitivity analysis across scenarios (pooled scenarios)
crit_conc_calc.R - calculates annual risk of illness given a range of L. pneumophila concentrations


## Leg_ret_rel_QMRA.R
This is the main file for running the QMRA. It loads libraries and functions.
The "GENERATE DATA" section (Line 17) identifies the independent variables of the experimental matrix (filter age, human age, and activity), prepares data frames for fixture, daily, and annual risks of infection and illness, and then loops through the "run_mc" function to produce 10,000 iterations of risks.
The "ORGANIZE FIXTURE, DAILY, ANNUAL RISKS INF/ILL" section (Line 60) organizes the data and labels with the independent variable names
The "OUTPUT DATA" section exports the data to a subdirectory "results" within the root folder.

The "ORGANIZE MORE OUTPUT DATA" section creates separate files for results by activity or age, separated by risk type

The "CALCULATE STATISTICS" section calculates the minimum; 25th, 50th, and 75th percentiles; maximum, and standard deviation for each risk type (fixture, daily, annual infection and illness). It then, round robin style, performs Wilcoxon tests on each risk by independent variable (filter type, age, and activity)

The "SENSITIVITY ANALYSIS" section calculates Spearman rank correlation coefficients between the model parameters and the annual risk (sensitivity analysis between scenarios) and the Spearman rank correlation coefficients across model parameters and the fixture risk (sensitivity analysis across scenarios). Then Sobol indices (total and first order) are calculated for the model parameters.

The "CALCULATE CRITICAL RANGE OF L. pneumophila AND OUTPUT RISK" section generates a range of L. pneumophila concentrations and then calculates the annual risk for that range of C_0 L. pneumophila. This operation is looped through for every combination of filter type, age, and activity


## prepare_parcel.R
Takes in selected independent variables (filter age, age, activity), and prepares output list with model parameters for the given independent variables. Filter age must be written as 'none_Clwithout', 'none_Clwith', 'new_GW', 'new_PO', 'old_GW', or 'old_PO' Age must be written as 'child', 'adult', or 'elderly' Activity must be written as 'drink', 'handwash', 'dishwash', or 'shower'

## orgdat.R
Takes in parameters that you want to sort data by, outputs a list of six data frames (fixture infection risk, daily infection risk, annual infection risk, fixture illness risk, daily illness risk, and annual illness risk) for populations with the variables of interest (specific filter type, water usage activity, or age)


## bind_df.R
Takes in elements of a list and binds together into a new list


## calc_stats.R
Takes in desired risk type (fixture, daily, or annual risk of infection or illness), uploads that risk type data from results folder
Calculates quantiles, mean, std dev (function find_stats_values)
Calculates this for all columns


## round_robin_wilk.R
In round robin style, compares each dataset to another of the same risk type (input parameter) for a given target variable of interest (filter type, activity, or age)


## sens_an_spearman.R
Performs sensitivity analysis for each of the 72 scenarios separately (fixture risk).

## mc_with_param_input.R
Pools all 72 scenarios and performs sensitivity analysis across scenarios (annual risk).


## crit_conc_calc.R
From an array of possible initial L. pneumophila concentrations, calculates an example annual risk for each concentration.


## multivariate aerosol and first order decay
This is a folder containing the raw data and code for running simulations with (1) aerosol sampling utilizing a multivariate approach that preserves the covariance across aerosol sample bins or (2) fitting L. pneumophila release to a piece-wise first-order decay model.

## RUNNING
To run QMRA, run the code in `Leg_ret_rel_QMRA.R` The Monte Carlo iterations can be modified. To run just one scenario, create a variable and use `prepare_parcel.R` to assemble the relevant model input parameters. Then use `run_mc.R` to perform Monte Carlo iterations for the given model input parameters, number of days (365), and desired iterations.

To run sensitivity analysis, use `sens_an_spearman.R` for sensitivity analysis between scenarios (fixture risk) and use `mc_with_param_input.R` for sensitivity analysis across scenarios (annual risk, scenarios pooled together)

To calculate critical range of 	L. pneumophila, use `crit_conc_calc.R`


