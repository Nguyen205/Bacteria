sens_an_spearman = function(parcel, iter){
  set.seed(4)
  
  # L pneumophila concentration (copies/mL, lognormal)
  # 1st element of Lp is meanlog, 2nd element is sdlog
  C_0 = rlnorm(iter, parcel[['Lp']][1], parcel[['Lp']][2])
  
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
  
  
  # Calculate concentration of Lp released from filter over time
  # For t < 5
  # C(t) = C_0*e^k1*t
  # Area under curve (AUC) = (C0/k1)*(e^(k1t)-1)
  
  # For t > 5
  # C(t) = C(5)*e^(k2*(t-5))
  # Area under curve (AUC) = (C0/k1)*(e^(5*k1)-1)+(C5/k2)*(e^(k2(t-5))-1)
  
  k1 = parcel$Lp_decay[1]
  k2 = parcel$Lp_decay[2]
  time_integrated_C = c()
  
  for(i in (1:length(t))) {
    if(t[i] < 5){
      AUC = (C_0[i]/k1)*(exp(k1*t[i])-1)
      time_integrated_C = c(time_integrated_C, AUC)
    } else {
      C5 = C_0[i]*exp(k1*5)
      til_five = (C_0[i]/k1)*(exp(5*k1)-1) # AUC from 0 to 5
      AUC = til_five + (C5/k2)*(exp(k2*(t[i]-5))-1)
      time_integrated_C = c(time_integrated_C, AUC)
    }
    #print(time_integrated_C)
  }
  
  
  
  
  #------------------------------------Dose---------------------------------------
  # Calculate daily dose = C_Leg*t*B*f*sum(C_aer*V_aer*Dep_eff*Frac_Leg)
  Daily_dose = time_integrated_C*B*f*sum_CVDF
  Fixture_dose = time_integrated_C*B*sum_CVDF
  
  # Dose response parameter k
  # 1st element of k is meanlog, 2nd element is sdlog
  k = rlnorm(iter, parcel[['k']][1], parcel[['k']][2])
  
  #-------------------------------Risk of infection-------------------------------
  
  # Daily or fixture risk = 1 - e^(-k*Dose)
  Daily_risk_inf = 1-exp(-k*Daily_dose)
  Fixture_risk_inf = 1-exp(-k*Fixture_dose)
  
  
  #---------------------------------Correlation-----------------------------------
  # Prepare independent variables in a list
  ind_var = c(list(C_0), list(time_integrated_C), list(B), list(t), list(f), 
              list(tf), list(C[[1]]), 
              list(C[[2]]), list(C[[3]]), list(C[[4]]), list(C[[5]]), 
              list(C[[6]]), list(C[[7]]), list(C[[8]]), list(C[[9]]), 
              list(C[[10]]), list(Dep_eff[[1]]), list(Dep_eff[[2]]), 
              list(Dep_eff[[3]]), list(Dep_eff[[4]]), list(Dep_eff[[5]]), 
              list(Dep_eff[[6]]), list(Dep_eff[[7]]), list(Dep_eff[[8]]), 
              list(Dep_eff[[9]]), list(Dep_eff[[10]]), list(sum_CVDF), list(k))
  
  labs = c('C_0', 'C_AUC', 'B', 't', 'f', 'tf', 'C1', 'C2', 'C3', 'C4', 'C5', 'C6', 
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