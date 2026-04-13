prepare_parcel = function(filter_age, age, activity){
  
  # Fail if options aren't correct
  if(!(filter_age == 'none_Clwith' | filter_age == 'none_Clwithout' | 
       filter_age == 'new_GW' | filter_age == 'new_PO' |
       filter_age == 'old_GW' | filter_age == 'old_PO')){
    stop('invalid filter age option')
  } else if(!(age == 'child' | age == 'adult' | age == 'elderly')){
    stop('invalid age option')
  } else if(!(activity == 'drink' | activity == 'handwash' | 
              activity == 'dishwash' | activity == 'shower')){
    stop('invalid activty option')
  }
  
  # Load data
  Lp_init = read.csv('Lp_distr_data_countmL.csv', header = TRUE)
  Lp_decay = read.csv('Lpneum_decay_con.csv', header = TRUE)
  breath_rate = read.csv('breath_rate_mLmin.csv', header = TRUE)
  exposure_time = read.csv('exposure_time_min.csv', header = TRUE)
  fixture_freq = read.csv('fixture_freq_useday.csv', header = TRUE)
  CVDF_combo = read.csv('CVDF_combo_nummL.csv', header = TRUE)
  dose_response_param = read.csv('dose_response_param.csv', header = TRUE)
  morbidity_ratio = read.csv('morbidity_ratio.csv', header = TRUE)
  
  # Options dataframe
  options = data.frame(choice = c(filter_age, age, activity))
  rownames(options) = c('filter_age', 'age', 'activity')
  
  
  # L pneumophila concentrations (1st element is mean, 2nd is std dev), copies/mL
  if(filter_age == 'none_Clwith'){
    Lp = Lp_init$nofilt_withCl
  } else if (filter_age == 'none_Clwithout'){
    Lp = Lp_init$nofilt_noCl
  } else if (filter_age == 'new_GW' | filter_age == 'new_PO'){
    Lp = Lp_init$new_filter
  } else if (filter_age == 'old_GW' | filter_age == 'old_PO'){
    Lp = Lp_init$old_filter
  }
  
  # L pneumophila conc ratios over time (1st col is time, 2nd is min, 3rd is max)
  # L pneumophila decay constants (1st element is pre 5min, 2nd element is post 5min)
  if(filter_age == 'none_Clwith'){
    Lp_dec = Lp_decay$none_Clwith
  } else if (filter_age == 'none_Clwithout'){
    Lp_dec = Lp_decay$none_Clwithout
  } else if (filter_age == 'new_GW'){
    Lp_dec = Lp_decay$new_GW
  } else if (filter_age == 'new_PO'){
    Lp_dec = Lp_decay$new_PO
  } else if (filter_age == 'old_GW'){
    Lp_dec = Lp_decay$old_GW
  } else if (filter_age == 'old_PO'){
    Lp_dec = Lp_decay$old_PO
  }
  
  # Breathing rate (1st element is min, 2nd element is max), mL/min
  B = c(breath_rate$min, breath_rate$max)
  
  
  # Exposure time (1st element is mean, 2nd element is std dev), min
  if(activity == 'drink'){
    t = exposure_time$drink
  } else if (activity == 'handwash'){
    t = exposure_time$handwash
  } else if (activity == 'dishwash'){
    t = exposure_time$dishwash
  } else if (activity == 'shower'){
    t = exposure_time$shower
  }
  
  # Fixture frequency (point)
  if (activity == 'handwash'){
    f = fixture_freq$handwash
  } else if (activity == 'dishwash'){
    f = fixture_freq$dishwash
  } else if (activity == 'shower'){
    f = fixture_freq$shower
  } else if (activity == 'drink'){
    f = fixture_freq$drink
  }
  if (age == 'child'){
    f = f[1]
  } else if (age == 'adult'){
    f = f[2]
  } else if (age == 'elderly'){
    f = f[3]
  }
  
  # Aerosol concentrations (ln mean, ln sd), num/cm3
  if (activity == 'drink'){
    Caer = data.frame(CVDF_combo$Drftn_ln_mean, CVDF_combo$Drftn_ln_sd)
  } else if (activity == 'handwash' || activity == 'dishwash'){
    Caer = data.frame(CVDF_combo$Sink_ln_mean, CVDF_combo$Sink_ln_sd)
  } else if (activity == 'shower'){
    Caer = data.frame(CVDF_combo$Shower_ln_mean, CVDF_combo$Shower_ln_sd)
  }
  colnames(Caer) = c('aer_ln_mean', 'aer_ln_sd')
  
  # Volume diameter, um
  Vaer_diam = data.frame(CVDF_combo$diameter_um)
  colnames(Vaer_diam) = 'aer_diam_um'
  
  # Aerosol deposition efficiency & fractionization, unitless
  Dep = data.frame(diameter = CVDF_combo$diameter_um, min = CVDF_combo$dep_min,
                   max = CVDF_combo$dep_max)
  Frac = data.frame(diameter_um = CVDF_combo$diameter_um, 
                    fraction = CVDF_combo$fraction)
  
  # Dose-response parameter (unitless)
  k = c(dose_response_param$mean, dose_response_param$sd)
  
  # Morbidity ratio (probability of illness given infection)
  if (age == 'child'){
    MR = morbidity_ratio$children
  } else if(age == 'adult'){
    MR = morbidity_ratio$adults
  } else if (age == 'elderly'){
    MR = morbidity_ratio$elderly
  }
  
  result = list(options, Lp, Lp_dec, B, t, f, Caer, Vaer_diam, Dep, Frac, 
                k, MR)
  
  names(result) = c('options', 'Lp', 'Lp_decay', 'B', 't', 'f', 'Caer', 
                    'Vaer_diam', 'Dep_eff', 'Frac_Lp', 'k', 'MR')
  
  return(result)
}
