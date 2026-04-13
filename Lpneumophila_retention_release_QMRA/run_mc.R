run_mc = function(parcel, days, iter){
  set.seed(4)
  
#------------------------------Output variable setup----------------------------
  fixture_inf = c()
  daily_inf = c()
  annual_inf = c()
  
  fixture_ill = c()
  daily_ill = c()
  annual_ill = c()
  
#-----------------------------Monte Carlo iterations----------------------------
  
  for(it in 1:iter){
    
#------------------------------Generate variables-------------------------------
    
    # L pneumophila concentration (copies/mL, lognormal)
    # 1st element of Lp is meanlog, 2nd element is sdlog
    C_0 = rlnorm(days, parcel[['Lp']][1], parcel[['Lp']][2])
    
    
    # L pneumophila ratios over time (unitless)
    # 1st element is min, 2nd element is max
    # Generate fractions at each time interval
    C_frac = list()
    for (i in 1:nrow(parcel[['Lp_ratio']])){
      C_frac[[i]] = runif(days, min = parcel[['Lp_ratio']][i,2], 
                          max = parcel[['Lp_ratio']][i,3])
    }
    names(C_frac) = parcel[['Lp_ratio']][,1]
    for (i in 1:length(C_frac)){
      for (j in 1:days){
        C_frac[[i]][j] = C_frac[[i]][j]*C_0[j]
      }
    }
    
    
    # Breathing rate (mL/min, uniform)
    # 1st element is min, 2nd element is max
    B = runif(days, parcel[['B']][1], parcel[['B']][2])
    
    
    # Exposure time (min/use, normal) 
    # 1st element is mean, 2nd element is sd, truncate at 0
    t = rtruncnorm(days, a = 0, b = Inf, 
                   mean = parcel[['t']][1], sd = parcel[['t']][2])
    
    
    # Fixture frequency (uses/day, point)
    # Single element
    f = rep(parcel[['f']], days)
    
    
    # C*V*D*F for particle size 1-10 um
    # Concentration of aerosols (#/cm3, lognormal) * Vaerosol (cm3/#)
    # * Deposition efficiency (unitless, uniform) * Fraction to size i (unitless, point)
    C = list()
    for (i in 1:nrow(parcel[['Caer']])) {
      C[[i]] = rlnorm(days, meanlog = parcel[['Caer']][i,1], 
                      sdlog = parcel[['Caer']][i,2])
    }
    
    V = (4/3)*pi*(parcel[['Vaer_diam']]/(2*10^4))^3
    
    Dep_eff = list()
    for (i in 1:nrow(parcel[['Dep_eff']])) {
      Dep_eff[[i]] = runif(days, min = parcel[['Dep_eff']][i,2], 
                           max = parcel[['Dep_eff']][i,3])
    }
    
    Frac_Leg = parcel[['Frac_Lp']]$fraction
    
    # sum of CVDF calculation
    CVDF = list()
    for (i in 1:length(C)){
      CVDF[[i]] = C[[i]]*V[i,1]*Dep_eff[[i]]*Frac_Leg[i]
    }
    
    sum_CVDF = 0
    for (i in 1:length(CVDF)){
      sum_CVDF = sum_CVDF + CVDF[[i]]
    }
    
    
    # Calculate C*t (area under C(t) vs t curve)
    C_times_t = c()
    for (i in 1:days){
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
    
    
    
#-------------------------------------Dose---------------------------------------
    
    # Calculate fixture dose = C_Leg*t*B*sum(C_aer*V_aer*Dep_eff*Frac_Leg)
    Fixture_dose = C_times_t*B*sum_CVDF
    
    # Calculate daily dose = C_Leg*t*B*f*sum(C_aer*V_aer*Dep_eff*Frac_Leg)
    Daily_dose = C_times_t*B*f*sum_CVDF
    
    # Dose response parameter k
    # 1st element of k is meanlog, 2nd element is sdlog
    k = rlnorm(days, parcel[['k']][1], parcel[['k']][2])
    
#--------------------------------Risk of infection-------------------------------
    
    # Daily or fixture risk = 1 - e^(-k*Dose)
    # Annual risk of infection = 1 - PI(1-P_inf,i) from i = 1 to n
    Fixture_risk_inf = 1-exp(-k*Fixture_dose)
    Daily_risk_inf = 1-exp(-k*Daily_dose)
    Annual_risk_inf = 1-prod(1-Daily_risk_inf)
    
    
#---------------------------------Risk of illness------------------------------  
    
    # Daily or fixture risk of illness = morbidity ratio*P(inf)
    # Morbidity ratio = Prob(illness given infection)
    # Annual risk of illness = 1 - PI(1-P_ill,i) from i = 1 to n
    MR = parcel[['MR']]
    Fixture_risk_ill = MR*Fixture_risk_inf
    Daily_risk_ill = MR*Daily_risk_inf
    Annual_risk_ill = 1-prod(1-Daily_risk_ill)
    
    
#--------------------Append risks to variable for each iteration----------------
    fixture_inf = c(fixture_inf, Fixture_risk_inf[1])
    daily_inf = c(daily_inf, Daily_risk_inf[1])
    annual_inf = c(annual_inf, Annual_risk_inf)
    
    fixture_ill = c(fixture_ill, Fixture_risk_ill[1])
    daily_ill = c(daily_ill, Daily_risk_ill[1])
    annual_ill = c(annual_ill, Annual_risk_ill)
    
  }
  
  output_df = data.frame(fixture_inf, daily_inf, annual_inf, 
                         fixture_ill, daily_ill, annual_ill)
  return(output_df)
}



