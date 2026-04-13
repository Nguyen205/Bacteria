prepare_parcel = function(filter_age, age, activity){
  
  # Fail if options aren't correct
  if(!(filter_age == 'none_Clwith' | filter_age == 'none_Clwithout' | 
       filter_age == 'new_GW' | filter_age == 'new_PO' |
       filter_age == 'old_GW' | filter_age == 'old_PO')){
    stop('invalid filter age option')
  } else if(!(age == 'child' | age == 'adult' | age == 'elderly')){
    stop('invalid age option')
  } else if(!(activity == 'drink' | activity == 'handwash' | 
              activity == 'dishwash')){
    stop('invalid activty option')
  }
  
  # Load data
  Lp_init = read.csv('Lp_distr_data_countmL.csv', header = TRUE)
  Lp_ratio = read.csv('Lpneum_ratios_time.csv', header = TRUE)
  breath_rate = read.csv('breath_rate_mLmin.csv', header = TRUE)
  exposure_time = read.csv('exposure_time_min.csv', header = TRUE)
  fixture_freq = read.csv('fixture_freq_useday.csv', header = TRUE)
  CVDF_combo = read.csv('CVDF_combo_nummL_for_multivar.csv', header = TRUE)
  aer_multivar = read.csv('multivar_correlation.csv', header = FALSE)
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
  if(filter_age == 'none_Clwith'){
    Lp_rat = Lp_ratio[ , c(1, 2, 3)]
  } else if (filter_age == 'none_Clwithout'){
    Lp_rat = Lp_ratio[ , c(4, 5, 6)]
  } else if (filter_age == 'new_GW'){
    Lp_rat = Lp_ratio[ , c(7, 8, 9)]
  } else if (filter_age == 'new_PO'){
    Lp_rat = Lp_ratio[ , c(10, 11, 12)]
  } else if (filter_age == 'old_GW'){
    Lp_rat = Lp_ratio[ , c(13, 14, 15)]
  } else if (filter_age == 'old_PO'){
    Lp_rat = Lp_ratio[ , c(16, 17, 18)]
  }
  Lp_rat = na.omit(Lp_rat)
  
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
    Caer = data.frame(CVDF_combo$Drftn_mean, CVDF_combo$Drftn_sd)
  } else if (activity == 'handwash' || activity == 'dishwash'){
    Caer = data.frame(CVDF_combo$Sink_mean, CVDF_combo$Sink_sd)
  }
  colnames(Caer) = c('aer_mean', 'aer_sd')
  
  
  # Aerosol multivariate correlation
  if (activity == 'drink'){
    aer_corr = unname(data.matrix(aer_multivar[1:10], rownames.force = FALSE))
  } else if (activity == 'handwash' || activity == 'dishwash'){
    aer_corr = unname(data.matrix(aer_multivar[11:20], rownames.force = FALSE))
  }
  
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
  
  result = list(options, Lp, Lp_rat, B, t, f, Caer, aer_corr, Vaer_diam, Dep, Frac, 
                k, MR)
  
  names(result) = c('options', 'Lp', 'Lp_ratio', 'B', 't', 'f', 'Caer', 'aer_corr',
                    'Vaer_diam', 'Dep_eff', 'Frac_Lp', 'k', 'MR')
  
  return(result)
}
