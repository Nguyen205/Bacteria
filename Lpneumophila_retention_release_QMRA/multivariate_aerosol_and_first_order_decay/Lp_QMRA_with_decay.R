library(dplyr)
library(stats)
library(EnvStats)
library(truncnorm)


#-------------------------------------RUN MONTE CARLO--------------------------
source('prep_parc_with_decay.R')
source('run_mc_with_decay.R')


# Options
# filter_age: 'none_Clwithout', 'none_Clwith', 'new_GW', 'new_PO', 'old_GW', 'old_PO'
# age: child, adult, or elderly
# activity: drink, handwash, dishwash, shower 


filter_age_opt = c('none_Clwithout', 'none_Clwith', 'new_GW', 'new_PO', 'old_GW', 'old_PO')
age_opt = c('child', 'adult', 'elderly')
activity_opt = c('drink','handwash', 'dishwash', 'shower')


# Make dataframes
iterations = 1000
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

write.table(fix_inf, file = 'results/with_decay_fixture_inf.csv', row.names = FALSE, sep = ',')
write.table(dai_inf, file = 'results/with_decay_daily_inf.csv', row.names = FALSE, sep = ',')
write.table(ann_inf, file = 'results/with_decay_annual_inf.csv', row.names = FALSE, sep = ',')
write.table(fix_ill, file = 'results/with_decay_fixture_ill.csv', row.names = FALSE, sep = ',')
write.table(dai_ill, file = 'results/with_decay_daily_ill.csv', row.names = FALSE, sep = ',')
write.table(ann_ill, file = 'results/with_decay_annual_ill.csv', row.names = FALSE, sep = ',')



#-------------------------------------ORGANIZE DATA------------------------------
# Options for orgdat function
# filter_age: 'none_Clwith', 'none_Clwithout', 'new_GW', 'new_PO', 'old_GW', 'old_PO'
# activity: drink, handwash, dishwash, shower 
# age: child, adult, or elderly
source('orgdat.R')
source('bind_df.R')


# Load data
fix_inf = read.csv('results/with_decay_fixture_inf.csv', header = TRUE)
dai_inf = read.csv('results/with_decay_daily_inf.csv', header = TRUE)
ann_inf = read.csv('results/with_decay_annual_inf.csv', header = TRUE)
fix_ill = read.csv('results/with_decay_fixture_ill.csv', header = TRUE)
dai_ill = read.csv('results/with_decay_daily_ill.csv', header = TRUE)
ann_ill = read.csv('results/with_decay_annual_ill.csv', header = TRUE)




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
    f = paste('results/with_decay', 'comp1_', activity_opt[a], '_', risk_type[r], '.csv', sep = '')
    write.table(comp1[[r]], file = f, row.names = FALSE, sep = ',')
  }
}


#-------------------------------------CALC STATS--------------------------------

source('calc_stats_with_decay.R')
source('round_robin_wilk_with_decay.R')


inf_ill_opt = c('fixture_inf', 'fixture_ill',
                'daily_inf', 'daily_ill',
                'annual_inf', 'annual_ill')
targ_var_opts = c('filt_type', 'age', 'activity')


for(i in 1:length(inf_ill_opt)){
  inf_ill_stats = calc_stats(inf_ill_opt[i])
  inf_ill_stats = inf_ill_stats[order(inf_ill_stats$activity),]
  inf_ill_stats = inf_ill_stats[order(inf_ill_stats$filt_type),]
  f = paste('results/with_decay_stats_',inf_ill_opt[i], '.csv', sep = '')
  write.table(inf_ill_stats, file = f, row.names = FALSE, sep = ',')
  
  for(j in 1:length(targ_var_opts)){
    inf_ill_wilk = round_robin_wilk(inf_ill_opt[i], targ_var_opts[j])
    f2 = paste('results/with_decay_stats_wilk_',inf_ill_opt[i], '_', 
               targ_var_opts[j], '.csv', sep = '')
    write.table(inf_ill_wilk, file = f2, row.names = FALSE, sep = ',')
  }
}



#--------------------------------SENSITIVITY ANALYSIS--------------------------
# Sensitivity between scenarios (unpooled)
source('sens_an_spearman_with_decay.R')

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
write.table(spearman_btwn, file = 'results/with_decay_spearman_btwn_fixture.csv', row.names = TRUE, sep = ',')

# Extract each variable to get distribution of how impactful each value is
C_0_cor = as.numeric(t(spearman_btwn['C_0',]))
C_AUC_cor = as.numeric(t(spearman_btwn['C_AUC',]))
B_cor = as.numeric(t(spearman_btwn['B',]))
t_cor = as.numeric(t(spearman_btwn['t',]))
tf_cor = as.numeric(t(spearman_btwn['tf',]))
CVDF_cor = as.numeric(t(spearman_btwn['CVDF',]))
k = as.numeric(t(spearman_btwn['k',]))


fivenum(C_0_cor)
fivenum(C_AUC_cor)
fivenum(B_cor)
fivenum(t_cor)
fivenum(tf_cor)
fivenum(CVDF_cor)
fivenum(k)



