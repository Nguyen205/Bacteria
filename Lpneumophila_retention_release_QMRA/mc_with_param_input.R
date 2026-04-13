mc_with_param_input = function(parcel, days, iter){
  set.seed(4)
  
#------------------------------Output variable setup----------------------------
  fixture_inf = c()
  daily_inf = c()
  annual_inf = c()
  
  fixture_ill = c()
  daily_ill = c()
  annual_ill = c()
  
  C_0_out = c()
  C_rat_out = c()
  B_out = c()
  t_out = c()
  f_out = c()
  tf_out = c()
  C1_out = c()
  C2_out = c()
  C3_out = c()
  C4_out = c()
  C5_out = c()
  C6_out = c()
  C7_out = c()
  C8_out = c()
  C9_out = c()
  C10_out = c()
  D1_out = c()
  D2_out = c()
  D3_out = c()
  D4_out = c()
  D5_out = c()
  D6_out = c()
  D7_out = c()
  D8_out = c()
  D9_out = c()
  D10_out = c()
  CVDF_out = c()
  MR_out = c()
  k_out = c()
  
  
#-----------------------------Monte Carlo iterations----------------------------
  
  for(it in 1:iter){
    
#------------------------------Generate variables-------------------------------
    
    # L pneumophila concentration (copies/mL, lognormal)
    # 1st element of Lp is meanlog, 2nd element is sdlog
    C_0 = rlnorm(days, parcel[['Lp']][1], parcel[['Lp']][2])
    
    
    # L pneumophila ratios over time (unitless)
    # 1st element is min, 2nd element is max
    C_frac = list()
    for (i in 1:nrow(parcel[['Lp_ratio']])){
      C_frac[[i]] = runif(days, min = parcel[['Lp_ratio']][i,2], 
                          max = parcel[['Lp_ratio']][i,3])
    }
    names(C_frac) = parcel[['Lp_ratio']][,1]
    # Way of combining C_frac into one variable independent of C_0
    C_rat = c()
    for(i in 1:days){
      C_cur_frac = 0
      for(j in 1:(length(C_frac)-1)){
        C_cur_frac = C_cur_frac+
          (C_frac[[j+1]][i]+C_frac[[j]][i])*(parcel[['Lp_ratio']][j+1,1]-parcel[['Lp_ratio']][j,1])
        #(C1/C0 + C0/C0)*(t1-t0) + (C2/C0 + C1/C0)*(t2-t1) +...
      }
      C_rat = c(C_rat, C_cur_frac)
    }
    
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
    
    
    # Daily exposure time (t*f)
    tf = t*f
    
    
    
    # Concentration of aerosols (#/cm3, lognormal)*V aerosols (cm^3/#)
    # V diam in um
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
    for (i in 1:length(C)) {
      CVDF[[i]] = C[[i]]*V[i,1]*Dep_eff[[i]]*Frac_Leg[i]
    }
    sum_CVDF = 0
    for(i in 1:length(CVDF)){
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
    
    # Calculate fixture dose = C_Leg*B*t*sum(C_aer*V_aer*Dep_eff*Frac_Leg)
    Fixture_dose = C_times_t*B*sum_CVDF
    
    # Calculate daily dose = C_Leg*B*t*f*sum(C_aer*V_aer*Dep_eff*Frac_Leg)
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
    
    C_0_out = c(C_0_out, mean(C_0))
    C_rat_out = c(C_rat_out, mean(C_rat))
    B_out = c(B_out, mean(B))
    t_out = c(t_out, mean(t))
    f_out = c(f_out, mean(f))
    tf_out = c(tf_out, mean(tf))
    C1_out = c(C1_out, mean(C[[1]]))
    C2_out = c(C2_out, mean(C[[2]]))
    C3_out = c(C3_out, mean(C[[3]]))
    C4_out = c(C4_out, mean(C[[4]]))
    C5_out = c(C5_out, mean(C[[5]]))
    C6_out = c(C6_out, mean(C[[6]]))
    C7_out = c(C7_out, mean(C[[7]]))
    C8_out = c(C8_out, mean(C[[8]]))
    C9_out = c(C9_out, mean(C[[9]]))
    C10_out = c(C10_out, mean(C[[10]]))
    D1_out = c(D1_out, mean(Dep_eff[[1]]))
    D2_out = c(D2_out, mean(Dep_eff[[2]]))
    D3_out = c(D3_out, mean(Dep_eff[[3]]))
    D4_out = c(D4_out, mean(Dep_eff[[4]]))
    D5_out = c(D5_out, mean(Dep_eff[[5]]))
    D6_out = c(D6_out, mean(Dep_eff[[6]]))
    D7_out = c(D7_out, mean(Dep_eff[[7]]))
    D8_out = c(D8_out, mean(Dep_eff[[8]]))
    D9_out = c(D9_out, mean(Dep_eff[[9]]))
    D10_out = c(D10_out, mean(Dep_eff[[10]]))
    CVDF_out = c(CVDF_out, mean(sum_CVDF))
    MR_out = c(MR_out, MR)
    k_out = c(k_out, mean(k))
    
  }
  
  output_df = data.frame(C0 = C_0_out, C_rat = C_rat_out, B = B_out, t = t_out, 
                         f = f_out, tf = tf_out, C1 = C1_out, C2 = C2_out, 
                         C3 = C3_out, C4 = C4_out, C5 = C5_out, C6 = C6_out, 
                         C7 = C7_out, C8 = C8_out, C9 = C9_out, C10 = C10_out, 
                         D1 = D1_out, D2 = D2_out, D3 = D3_out, D4 = D4_out, 
                         D5 = D5_out, D6 = D6_out, D7 = D7_out, D8 = D8_out,
                         D9 = D9_out, D10 = D10_out, CVDF = CVDF_out, MR = MR_out, 
                         k = k_out,
                         annual_risk = annual_ill)
  return(output_df)
}



