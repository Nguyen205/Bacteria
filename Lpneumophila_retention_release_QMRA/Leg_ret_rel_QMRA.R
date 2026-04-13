library(dplyr)
library(stats)
library(EnvStats)
library(truncnorm)
library(sensobol)
source('prepare_parcel.R')
source('run_mc.R')
source('orgdat.R')
source('bind_df.R')
source('calc_stats.R')
source('round_robin_wilk.R')
source('sens_an_spearman.R')
source('mc_with_param_input.R')
source('crit_conc_calc.R')


#---------------------------------GENERATE DATA---------------------------------
# Options
# filter_age: 'none_Clwithout', 'none_Clwith', 'new_GW', 'new_PO', 'old_GW', 'old_PO'
# age: child, adult, or elderly
# activity: drink, handwash, dishwash, shower 


filter_age_opt = c('none_Clwithout', 'none_Clwith', 'new_GW', 'new_PO', 'old_GW', 'old_PO')
age_opt = c('child', 'adult', 'elderly')
activity_opt = c('drink','handwash', 'dishwash', 'shower')


# Make dataframes
iterations = 1e4
fix_inf = data.frame(initial = rep(0,iterations+3)) 
dai_inf = data.frame(initial = rep(0,iterations+3))
ann_inf = data.frame(initial = rep(0,iterations+3))
fix_ill = data.frame(initial = rep(0,iterations+3))
dai_ill = data.frame(initial = rep(0,iterations+3))
ann_ill = data.frame(initial = rep(0,iterations+3))
# rep number of Monte Carlo iterations + 3 options names (filter age, human age, activity)



for(a in 1:length(filter_age_opt)){
  for(b in 1:length(age_opt)){
    for(c in 1:length(activity_opt)){
    
      # Generate the data
      f = prepare_parcel(filter_age_opt[a], age_opt[b], activity_opt[c])
      g = run_mc(f, 365, iterations)
      
      
      # Prepare data label short form
      h = strsplit(c(filter_age_opt[a], age_opt[b], 
                     activity_opt[c]), split = '')
      fi = paste(h[[1]][1], h[[1]][length(h[[1]])], sep = '')
      ag = paste(h[[2]][1], h[[2]][length(h[[2]])], sep = '')
      ac = paste(h[[3]][1], h[[3]][length(h[[3]])], sep = '')
      
      i = data.frame(x = f[[1]]) # options labels in a dataframe
      

      # ORGANIZE FIXTURE, DAILY, ANNUAL RISKS INF/ILL

      # Make fixture_risk_inf with the options and the raw numbers
      lab = paste(fi, ag, ac, 'fixture_inf', sep = '_')
      j = data.frame(x = g$fixture_inf)
      colnames(i) = lab
      colnames(j) = lab
      k = rbind(i,j)
      fix_inf = cbind(fix_inf, k)

      # Make daily_risk_inf with the options and the raw numbers
      lab = paste(fi, ag, ac, 'daily_inf', sep = '_')
      j = data.frame(x = g$daily_inf)
      colnames(i) = lab
      colnames(j) = lab
      k = rbind(i,j)
      dai_inf = cbind(dai_inf, k)

      # Make annual_risk_inf with the options and the raw numbers
      lab = paste(fi, ag, ac, 'annual_inf', sep = '_')
      j = data.frame(x = g$annual_inf)
      colnames(i) = lab
      colnames(j) = lab
      k = rbind(i,j)
      ann_inf = cbind(ann_inf, k)

      # Make fixture_risk_ill with the options and the raw numbers
      lab = paste(fi, ag, ac, 'fixture_ill', sep = '_')
      j = data.frame(x = g$fixture_ill)
      colnames(i) = lab
      colnames(j) = lab
      k = rbind(i,j)
      fix_ill = cbind(fix_ill, k)

      # Make daily_risk_inf with the options and the raw numbers
      lab = paste(fi, ag, ac, 'daily_ill', sep = '_')
      j = data.frame(x = g$daily_ill)
      colnames(i) = lab
      colnames(j) = lab
      k = rbind(i,j)
      dai_ill = cbind(dai_ill, k)

      # Make annual_risk_inf with the options and the raw numbers
      lab = paste(fi, ag, ac, 'annual_ill', sep = '_')
      j = data.frame(x = g$annual_ill)
      colnames(i) = lab
      colnames(j) = lab
      k = rbind(i,j)
      ann_ill = cbind(ann_ill, k)
     
    }
  }
}


fix_inf = select(fix_inf, -'initial')
dai_inf = select(dai_inf, -'initial')
ann_inf = select(ann_inf, -'initial')
fix_ill = select(fix_ill, -'initial')
dai_ill = select(dai_ill, -'initial')
ann_ill = select(ann_ill, -'initial')


#--------------------------------OUTPUT DATA-------------------------------------
write.table(fix_inf, file = 'results/fixture_inf.csv', row.names = FALSE, sep = ',')
write.table(dai_inf, file = 'results/daily_inf.csv', row.names = FALSE, sep = ',')
write.table(ann_inf, file = 'results/annual_inf.csv', row.names = FALSE, sep = ',')
write.table(fix_ill, file = 'results/fixture_ill.csv', row.names = FALSE, sep = ',')
write.table(dai_ill, file = 'results/daily_ill.csv', row.names = FALSE, sep = ',')
write.table(ann_ill, file = 'results/annual_ill.csv', row.names = FALSE, sep = ',')



#---------------------------ORGANIZE MORE OUTPUT DATA----------------------------
# Options for orgdat function
# filter_age: 'none_Clwith', 'none_Clwithout', 'new_GW', 'new_PO', 'old_GW', 'old_PO'
# activity: drink, handwash, dishwash, shower 
# age: child, adult, or elderly
source('orgdat.R')
source('bind_df.R')


# Load data
fix_inf = read.csv('results/fixture_inf.csv', header = TRUE)
dai_inf = read.csv('results/daily_inf.csv', header = TRUE)
ann_inf = read.csv('results/annual_inf.csv', header = TRUE)
fix_ill = read.csv('results/fixture_ill.csv', header = TRUE)
dai_ill = read.csv('results/daily_ill.csv', header = TRUE)
ann_ill = read.csv('results/annual_ill.csv', header = TRUE)




# Separated by risk type and activity
risk_type = c('fix_inf', 'dai_inf', 'ann_inf', 'fix_ill', 'dai_ill', 'ann_ill')
activity_opt = c('drink','handwash', 'dishwash', 'shower')
age_opt = c('child', 'adult', 'elderly')

for(r in 1:length(risk_type)){
  for(a in 1:length(activity_opt)){
    n = 0
    for(age in 1:length(age_opt)){
      current_comp1 = orgdat(activity = activity_opt[a], age = age_opt[age], 
                         f_in = fix_inf, d_in = dai_inf, a_in = ann_inf, 
                         f_il = fix_ill, d_il = dai_ill, a_il = ann_ill)
      if(n == 0){
        comp1 = current_comp1
      } else {
        comp1 = bind_df(comp1, current_comp1)
      }
      n = n+1
    }
    f = paste('results/', 'comp1_', activity_opt[a], '_', risk_type[r], '.csv', sep = '')
    write.table(comp1[[r]], file = f, row.names = FALSE, sep = ',')
  }
}



drink_chi = orgdat(activity = 'drink', age = 'child', 
                       f_in = fix_inf, d_in = dai_inf, a_in = ann_inf, 
                       f_il = fix_ill, d_il = dai_ill, a_il = ann_ill)
drink_adu = orgdat(activity = 'drink', age = 'adult', 
                   f_in = fix_inf, d_in = dai_inf, a_in = ann_inf, 
                   f_il = fix_ill, d_il = dai_ill, a_il = ann_ill)
drink_eld = orgdat(activity = 'drink', age = 'elderly', 
                   f_in = fix_inf, d_in = dai_inf, a_in = ann_inf, 
                   f_il = fix_ill, d_il = dai_ill, a_il = ann_ill)

drink_comp = bind_df(drink_chi, bind_df(drink_adu, drink_eld))
comp_name = 'comp_drink'
for(i in 1:length(drink_comp)){
  f = paste('results/', comp_name, '_', names(drink_comp)[i], '.csv', sep = '')
  write.table(drink_comp[[i]], file = f, row.names = FALSE, sep = ',')
}


#--------------------------------CALCULATE STATISTICS----------------------------
source('calc_stats.R')
source('round_robin_wilk.R')


inf_ill_opt = c('fixture_inf', 'fixture_ill',
                'daily_inf', 'daily_ill',
                'annual_inf', 'annual_ill')
targ_var_opts = c('filt_type', 'age', 'activity')


for(i in 1:length(inf_ill_opt)){
  inf_ill_stats = calc_stats(inf_ill_opt[i])
  inf_ill_stats = inf_ill_stats[order(inf_ill_stats$activity),]
  inf_ill_stats = inf_ill_stats[order(inf_ill_stats$filt_type),]
  f = paste('results/stats_',inf_ill_opt[i], '.csv', sep = '')
  write.table(inf_ill_stats, file = f, row.names = FALSE, sep = ',')
  
  for(j in 1:length(targ_var_opts)){
    inf_ill_wilk = round_robin_wilk(inf_ill_opt[i], targ_var_opts[j])
    f2 = paste('results/stats_wilk_',inf_ill_opt[i], '_', 
               targ_var_opts[j], '.csv', sep = '')
    write.table(inf_ill_wilk, file = f2, row.names = FALSE, sep = ',')
  }
}



# ---------------------------SENSITIVITY ANALYSIS-------------------------------
# Sensitivity between scenarios
source('sens_an_spearman.R')
filter_age_opt = c('none_Clwithout', 'none_Clwith', 'new_GW', 'new_PO', 'old_GW', 'old_PO')
age_opt = c('child', 'adult', 'elderly')
activity_opt = c('drink','handwash', 'dishwash', 'shower')


spearman_btwn = data.frame(initial = rep(0,31)) # Going to have problems with cbind because the data won't have the same column length


for(a in 1:length(filter_age_opt)){
  for(b in 1:length(age_opt)){
    for(c in 1:length(activity_opt)){
      
      # Generate the data
      m = prepare_parcel(filter_age_opt[a], age_opt[b], activity_opt[c])
      n = sens_an_spearman(m, 1000)
      
      
      # Prepare data label short form
      o = strsplit(c(filter_age_opt[a], age_opt[b], 
                     activity_opt[c]), split = '')
      fi = paste(o[[1]][1], o[[1]][length(o[[1]])], sep = '')
      ag = paste(o[[2]][1], o[[2]][length(o[[2]])], sep = '')
      ac = paste(o[[3]][1], o[[3]][length(o[[3]])], sep = '')
      
      p = data.frame(x = m[[1]]) # options labels in a dataframe

      
      
      # Make Spearman correlation with the options and the raw numbers
      lab = paste(fi, ag, ac, 'Spearman', sep = '_')
      q = data.frame(x = n)
      colnames(p) = lab
      colnames(q) = lab
      r = rbind(p,q)
      spearman_btwn = cbind(spearman_btwn, r)
      
      
    }
  }
}



spearman_btwn = select(spearman_btwn, -'initial')
write.table(spearman_btwn, file = 'results/spearman_btwn_fixture.csv', row.names = TRUE, sep = ',')




# Organize data by specific spearman results
specific_spearman_compiled = data.frame(initial = rep(0,31))
for(i in 1:length(filter_age_opt)){
  which_cols = spearman_btwn[1,] == filter_age_opt[i]
  specific_spearman = as.data.frame(spearman_btwn[,which_cols])
  specific_spearman_compiled = cbind(specific_spearman_compiled, specific_spearman)
}
specific_spearman_compiled = select(specific_spearman_compiled, -'initial')
write.table(specific_spearman_compiled, file = 'results/specific_spearman_filt_type.csv', row.names = TRUE, sep = ',')


# Extract each variable to get distribution of how impactful each value is
C_0_cor = as.numeric(t(spearman_btwn['C_0',]))
C_rat_cor = as.numeric(t(spearman_btwn['C_rat',]))
B_cor = as.numeric(t(spearman_btwn['B',]))
t_cor = as.numeric(t(spearman_btwn['t',]))
tf_cor = as.numeric(t(spearman_btwn['tf',]))
CVDF_cor = as.numeric(t(spearman_btwn['CVDF',]))
k = as.numeric(t(spearman_btwn['k',]))


fivenum(C_0_cor)
fivenum(C_rat_cor)
fivenum(B_cor)
fivenum(t_cor)
fivenum(tf_cor)
fivenum(CVDF_cor)
fivenum(k)





# Sensitivity across scenarios (pooled)
source('mc_with_param_input.R')
filter_age_opt = c('none_Clwithout', 'none_Clwith', 'new_GW', 'new_PO', 'old_GW', 'old_PO')
age_opt = c('child', 'adult', 'elderly')
activity_opt = c('drink','handwash', 'dishwash', 'shower')
pooled_spearman_raw_dat = data.frame()


for(a in 1:length(filter_age_opt)){
  for(b in 1:length(age_opt)){
    for(c in 1:length(activity_opt)){
      
      # Generate the data
      s = prepare_parcel(filter_age_opt[a], age_opt[b], activity_opt[c])
      t = mc_with_param_input(s, 365, 1000)
      pooled_spearman_raw_dat = rbind(pooled_spearman_raw_dat, t)
      
    }
  }
}

write.table(pooled_spearman_raw_dat, file = 'results/spearman_across_annual_raw_dat.csv', row.names = TRUE, sep = ',')



# Calculate correlation
pooled_spearman_raw_dat = read.csv('results/spearman_across_annual_raw_dat.csv')
cor_coef = data.frame()
cor_coef_names = c()
for (i in 1:(ncol(pooled_spearman_raw_dat)-1)){
  correl = cor.test(pooled_spearman_raw_dat[[i]], 
                    pooled_spearman_raw_dat[[ncol(pooled_spearman_raw_dat)]],
                    method = 'spearman')
  cor_coef = rbind(cor_coef, correl$estimate)
  cor_coef_names = c(cor_coef_names, colnames(pooled_spearman_raw_dat)[i])
}
row.names(cor_coef) = cor_coef_names
colnames(cor_coef) = 'spearman_cor_coef'

write.table(cor_coef, file = 'results/spearman_across_annual_cor_coef.csv', row.names = TRUE, sep = ',')


# Combining exposure time and exposure frequency to analyze correlation coefficient
x = select(pooled_spearman_raw_dat, c('t', 'f', 'annual_risk'))
x$tot_exp = x$t*x$f
cor.test(x$tot_exp,x$annual_risk, method = 'spearman')


#---------------------- Sobol indices - variance based sensitivity analysis------
# Options
# filter_age: 'none_Clwithout', 'none_Clwith', 'new_GW', 'new_PO', 'old_GW', 'old_PO'
# age: child, adult, or elderly
# activity: drink, handwash, dishwash, shower 

filter_age_opt = c('none_Clwithout', 'none_Clwith', 'new_GW', 'new_PO', 'old_GW', 'old_PO')
age_opt = c('child', 'adult', 'elderly')
activity_opt = c('drink','handwash', 'dishwash', 'shower')

factors = c('C_0', 'B', 't', 'C1', 'C2', 'C3', 'C4', 'C5', 'C6', 'C7', 
            'C8', 'C9', 'C10', 'D1', 'D2', 'D3', 'D4', 'D5', 'D6', 'D7', 'D8', 
            'D9', 'D10', 'k')

options = data.frame(parameter = c('filter_age', 'age', 'activity'))
sobol_results_first = data.frame(parameter = factors)
sobol_results_first = rbind(options, sobol_results_first)
sobol_results_total = data.frame(parameter = factors)
sobol_results_total = rbind(options, sobol_results_total)


# Sample size for matrix and bootstrap replicas
N = 10000 # sample size of base sample matrix
# R = 20 # number of bootstrap replicas

set.seed(4)

for(a in 1:length(filter_age_opt)){
  for(b in 1:length(age_opt)){
    for(c in 1:length(activity_opt)){
      
      # Generate Sobol matrices
      parcel = prepare_parcel(filter_age_opt[a], age_opt[b], activity_opt[c])
      g = sobol_matrices(N=N, params = factors, order = 'first')
      
      # Use distributions of each QMRA model parameter and Sobol matrix
      # to acquire sample set of values of for each model parameter
      
      # Initial L. pneumophila concentration, C_0
      g[,'C_0'] = qlnorm(g[,'C_0'], parcel[['Lp']][1], parcel[['Lp']][2])
      
      # Breathing rate, B
      g[,'B'] = qunif(g[,'B'], parcel[['B']][1], parcel[['B']][2])
      
      
      # Exposure time, t
      g[,'t'] = qtruncnorm(g[,'t'], a = 0, b = Inf, 
                           mean = parcel[['t']][1], sd = parcel[['t']][2])
      
      # Aerosol concentration size 1-10 um, C1-C10
      for (i in 1:nrow(parcel[['Caer']])) {
        cur_aer_C = paste('C',rownames(parcel[['Caer']])[i], sep = '')
        g[,cur_aer_C] = qlnorm(g[,cur_aer_C], meanlog = parcel[['Caer']][i,1], 
                               sdlog = parcel[['Caer']][i,2])
      }
      
      # Deposition efficiency size 1-10 um, D1-D10
      for (i in 1:nrow(parcel[['Dep_eff']])) {
        cur_aer_D = paste('D',rownames(parcel[['Caer']])[i], sep = '')
        g[,cur_aer_D] = qunif(g[,cur_aer_D],min = parcel[['Dep_eff']][i,2], 
                              max = parcel[['Dep_eff']][i,3])
      }
      
      # Dose-response parameter, k
      g[,'k'] = qlnorm(g[,'k'], parcel[['k']][1], parcel[['k']][2])
      
      
      # Implement the Sobol' G function
      h = sobol_Fun(g)
      
      
      # Calculate the Sobol indices
      # Sobol indices stored in results:
      # 1st order estimate and total order estimate
      #m = sobol_indices(Y = h, N = N, params = factors, boot = TRUE, R = R,
      #type = 'norm', conf = 0.95)
      m = sobol_indices(Y = h, N = N, params = factors, boot = FALSE)
      
      
      # Prepare data label short form
      n = strsplit(c(filter_age_opt[a], age_opt[b], 
                     activity_opt[c]), split = '')
      fi = paste(n[[1]][1], n[[1]][length(n[[1]])], sep = '')
      ag = paste(n[[2]][1], n[[2]][length(n[[2]])], sep = '')
      ac = paste(n[[3]][1], n[[3]][length(n[[3]])], sep = '')
      
      lab = paste(fi, ag, ac, sep = '_')
      o = data.frame(original = c(filter_age_opt[a], age_opt[b], 
                                  activity_opt[c])) # options labels in a dataframe
      
      sobol_results_first[lab] = rbind(o, data.frame(m[['results']][1:24,1]))
      
      sobol_results_total[lab] = rbind(o, data.frame(m[['results']][25:48,1]))
      
    }
  }
}

write.table(sobol_results_first, file = 'results/sobol_results_first.csv', row.names = FALSE, sep = ',')
write.table(sobol_results_total, file = 'results/sobol_results_total.csv', row.names = FALSE, sep = ',')         



#------------CALCULATE CRITICAL RANGE OF L pneumophila AND OUTPUT RISK----------
source('crit_conc_calc.R')
filter_age_opt = c('none_Clwithout', 'none_Clwith', 'new_GW', 'new_PO', 'old_GW', 'old_PO')
age_opt = c('child', 'adult', 'elderly')
activity_opt = c('drink','handwash', 'dishwash', 'shower')

# Generate L. pneumophila range
Lp_range = c(1e-14, 1e-13, 1e-12, 1e-11, 1e-10, 1e-9, 1e-8, 1e-7, 1e-6, 1e-5, 1e-4, 1e-3, 1e-2, 1e-1, 1e0, 1e1, 1e2, 1e3, 1e4, 1e5, 1e6, 1e7, 1e8, 1e9, 1e10, 1e11, 1e12, 1e13, 1e14, 1e15, 1e16, 1e17, 1e18, 1e19, 1e20) # Lp range in #/mL


# Generate finer L. pneumophila range to determine 10^-4 risk
Lp_fine = c(1e-4, 2e-4, 3e-4, 4e-4, 5e-4, 6e-4, 7e-4, 8e-4, 9e-4)
next_ten = Lp_fine
for(i in 1:12){
  next_ten = next_ten*10
  Lp_fine = c(Lp_fine, next_ten)
}
Lp_range = Lp_fine


crit_conc = data.frame(Lp_conc_num_per_mL = c(rep(NA,3), Lp_range))
set.seed(4)
for(a in 1:length(filter_age_opt)){
  for(b in 1:length(age_opt)){
    for(c in 1:length(activity_opt)){
      
      u = prepare_parcel(filter_age_opt[a], age_opt[b], activity_opt[c])
      v = crit_conc_calc(u, Lp_range, 'annual')
      
      
      # Prepare data label short form
      w = strsplit(c(filter_age_opt[a], age_opt[b], 
                     activity_opt[c]), split = '')
      fi = paste(w[[1]][1], w[[1]][length(w[[1]])], sep = '')
      ag = paste(w[[2]][1], w[[2]][length(w[[2]])], sep = '')
      ac = paste(w[[3]][1], w[[3]][length(w[[3]])], sep = '')
      
      x = data.frame(x = u[[1]]) # options labels in a dataframe
      
      
      # Calc crit conc with the options and the raw numbers
      lab = paste(fi, ag, ac, 'crit_conc', sep = '_')
      y = data.frame(x = v)
      colnames(x) = lab
      colnames(y) = lab
      z = rbind(x,y)
      crit_conc = cbind(crit_conc, z)
      
      
    }
  }
}

#write.table(crit_conc, file = 'results/crit_risk_annual.csv', row.names = TRUE, sep = ',')

write.table(crit_conc, file = 'results/crit_risk_annual_fine.csv', row.names = TRUE, sep = ',')



