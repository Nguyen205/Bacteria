orgdat = function(filter_age = NaN, activity = NaN, age = NaN, 
                  f_in, d_in, a_in, f_il, d_il, a_il){
  
  labels = fix_inf[c(1:3),]
  if(is.na(age) & is.na(activity)){
    chosen_col = which((labels[1,] == filter_age))
  } else if(is.na(filter_age) & is.na(activity)){
    chosen_col = which((labels[2,] == age))
  } else if(is.na(filter_age) & is.na(age)){
    chosen_col = which((labels[3,] == activity))
  } else if(is.na(filter_age)){
    chosen_col = which((labels[2,] == age & labels[3,] == activity))
  } else if (is.na(activity)){
    chosen_col = which((labels[1,] == filter_age & labels[2,] == age))
  } else if (is.na(age)){
    chosen_col = which((labels[1,] == filter_age & labels[3,] == activity))
  } else {
    chosen_col = which((labels[1,] == filter_age & 
                          labels[2,] == age & 
                          labels[3,] == activity))
  }
  
  
  
  fix_inf_df = f_in[,chosen_col]
  dai_inf_df = d_in[,chosen_col]
  ann_inf_df = a_in[,chosen_col]
  fix_ill_df = f_il[,chosen_col]
  dai_ill_df = d_il[,chosen_col]
  ann_ill_df = a_il[,chosen_col]
  
  x = list(fix_inf_df, dai_inf_df, ann_inf_df, fix_ill_df, dai_ill_df, ann_ill_df)
  names(x) = c('fix_inf', 'dai_inf', 'ann_inf', 'fix_ill', 'dai_ill', 'ann_ill')
  
  return(x)
  
}
