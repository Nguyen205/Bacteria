sens_an_spearman = function(parcel, iter){
  set.seed(4)
  
  # L pneumophila concentration (copies/mL, lognormal)
  # 1st element of Lp is meanlog, 2nd element is sdlog
  C_0 = rlnorm(iter, parcel[['Lp']][1], parcel[['Lp']][2])
  
  
  # L pneumophila ratios over time (unitless)
  # 1st element is min, 2nd element is max
  C_frac = list()
  for (i in 1:nrow(parcel[['Lp_ratio']])){
    C_frac[[i]] = runif(iter, min = parcel[['Lp_ratio']][i,2], 
                        max = parcel[['Lp_ratio']][i,3])
  }
  names(C_frac) = parcel[['Lp_ratio']][,1]
  # Way of combining C_frac into one variable independent of C_0
  C_rat = c()
  for(i in 1:iter){
    C_cur_frac = 0
    for(j in 1:(length(C_frac)-1)){
      C_cur_frac = C_cur_frac+
        (C_frac[[j+1]][i]+C_frac[[j]][i])*(parcel[['Lp_ratio']][j+1,1]-parcel[['Lp_ratio']][j,1])
      #(C1/C0 + C0/C0)*(t1-t0) + (C2/C0 + C1/C0)*(t2-t1) +...
    }
    C_rat = c(C_rat, C_cur_frac)
  }
  
  for (i in 1:length(C_frac)){
    for (j in 1:iter){
      C_frac[[i]][j] = C_frac[[i]][j]*C_0[j]
    }
  }
  
  
  # Breathing rate (mL/min, uniform)
  # 1st element is min, 2nd element is max
  B = runif(iter, parcel[['B']][1], parcel[['B']][2])
  
  
  # Exposure time (min/use, normal) 
  # 1st element is mean, 2nd element is sd, truncate at 0
  t = rtruncnorm(iter, a = 0, b = Inf, 
                 mean = parcel[['t']][1], sd = parcel[['t']][2])
  
  
  # Fixture frequency (uses/day, point)
  # Single element
  f = rep(parcel[['f']], iter)
  
  # Daily exposure time (t*f)
  tf = t*f
  
  
  
  # C*V*D*F for particle size 1-10 um
  # Concentration of aerosols (#/cm3, lognormal)*V aerosols (cm^3/#)
  # V diam in um
  # * Deposition efficiency (unitless, uniform) * Fraction to size i (unitless, point)
  C = list()
  for (i in 1:nrow(parcel[['Caer']])) {
    C[[i]] = rlnorm(iter, meanlog = parcel[['Caer']][i,1], 
                    sdlog = parcel[['Caer']][i,2])
  }
  V = (4/3)*pi*(parcel[['Vaer_diam']]/(2*10^4))^3
  Dep_eff = list()
  for (i in 1:nrow(parcel[['Dep_eff']])) {
    Dep_eff[[i]] = runif(iter, min = parcel[['Dep_eff']][i,2],
                         max = parcel[['Dep_eff']][i,3])
  }
  Frac_Leg = parcel[['Frac_Lp']]$fraction
  
  # sum of CVDF calculation
  CVDF = list()
  for (i in 1:length(C)) {
    CVDF[[i]] = C[[i]]*V[i,1]*Dep_eff[[i]]*Frac_Leg[i]
  }
  sum_CVDF = 0
  for(i in 1:length(CVDF)){
    sum_CVDF = sum_CVDF + CVDF[[i]]
  }
  
  
  # Calculate C*t (area under C(t) vs t curve)
  C_times_t = c()
  for (i in 1:iter){
    # Prepare C vs t data
    C_t_data = c()
    for (j in 1:length(C_frac)){
      C_t_data = c(C_t_data, C_frac[[j]][i])
    }
    
    # Append random time, t and set C(t) to be 0
    C_t_data = c(C_t_data,0)
    t_data = c(as.numeric(names(C_frac)), t[i])
    
    # Sort the dataframe
    Ct_combo_dat = data.frame(t_data, C_t_data)
    Ct_combo_dat = Ct_combo_dat[order(Ct_combo_dat$t_data),]
    row.names(Ct_combo_dat) = NULL
    
    # Determine the index of the new random time, t
    for(k in 1:nrow(Ct_combo_dat)){
      if(Ct_combo_dat[[k,1]] == t[i]){
        t_ind = k
      }
    }
    
    # Interpolate to find C(t); if t > 15, set C(t) = C(15)
    if(t_ind == nrow(Ct_combo_dat)){
      Ct_combo_dat[[nrow(Ct_combo_dat),2]] = Ct_combo_dat[[(nrow(Ct_combo_dat)-1),2]]
    } else {
      y1 = Ct_combo_dat[[t_ind-1, 2]]
      y2 = Ct_combo_dat[[t_ind+1, 2]]
      x1 = Ct_combo_dat[[t_ind-1, 1]]
      x2 = Ct_combo_dat[[t_ind+1, 1]]
      x = Ct_combo_dat[[t_ind, 1]]
      y = y1 + ((y2-y1)/(x2-x1))*(x-x1)
      Ct_combo_dat[[t_ind, 2]] = y
    }
    
    
    # Integrate from 0 to t with trapezoidal rule
    Ct_area = 0
    for(m in 2:t_ind){
      a = Ct_combo_dat[[m-1, 1]]
      b = Ct_combo_dat[[m, 1]]
      fa = Ct_combo_dat[[m-1, 2]]
      fb = Ct_combo_dat[[m, 2]]
      current_trap = (1/2)*(b-a)*(fa+fb)
      Ct_area = Ct_area + current_trap
    }
    
    C_times_t = c(C_times_t, Ct_area)
  }
  
#------------------------------------Dose---------------------------------------
  # Calculate daily dose = C_Leg*t*B*f*sum(C_aer*V_aer*Dep_eff*Frac_Leg)
  Daily_dose = C_times_t*B*f*sum_CVDF
  Fixture_dose = C_times_t*B*sum_CVDF
  
  # Dose response parameter k
  # 1st element of k is meanlog, 2nd element is sdlog
  k = rlnorm(iter, parcel[['k']][1], parcel[['k']][2])
  
#-------------------------------Risk of infection-------------------------------
  
  # Daily or fixture risk = 1 - e^(-k*Dose)
  Daily_risk_inf = 1-exp(-k*Daily_dose)
  Fixture_risk_inf = 1-exp(-k*Fixture_dose)
  
  
#---------------------------------Correlation-----------------------------------
  # Prepare independent variables in a list
  ind_var = c(list(C_0), list(C_rat), list(B), list(t), list(f), list(tf), list(C[[1]]), 
              list(C[[2]]), list(C[[3]]), list(C[[4]]), list(C[[5]]), 
              list(C[[6]]), list(C[[7]]), list(C[[8]]), list(C[[9]]), 
              list(C[[10]]), list(Dep_eff[[1]]), list(Dep_eff[[2]]), 
              list(Dep_eff[[3]]), list(Dep_eff[[4]]), list(Dep_eff[[5]]), 
              list(Dep_eff[[6]]), list(Dep_eff[[7]]), list(Dep_eff[[8]]), 
              list(Dep_eff[[9]]), list(Dep_eff[[10]]), list(sum_CVDF), list(k))
  
  labs = c('C_0', 'C_rat', 'B', 't', 'f', 'tf', 'C1', 'C2', 'C3', 'C4', 'C5', 'C6', 
           'C7', 'C8', 'C9', 'C10', 'D1', 'D2', 'D3', 'D4', 'D5', 'D6', 'D7', 
           'D8', 'D9', 'D10', 'CVDF', 'k')
  names(ind_var) = labs

  
  cor_coef = data.frame()
  for(i in 1:length(ind_var)){
    #correl = cor.test(Daily_risk_inf, ind_var[[i]], method = 'spearman')
    correl = cor.test(Fixture_risk_inf, ind_var[[i]], method = 'spearman')
    cor_coef = rbind(cor_coef, correl$estimate)
    rownames(cor_coef)[i] = labs[i]
  }
  colnames(cor_coef) = 'cor_coef'
  
  return(cor_coef)
}