round_robin_wilk = function(risk_type, target_var){
  filename = paste('results/', risk_type, '.csv', sep = '')
  df = read.csv(filename, header = TRUE)
  labels = df[-c(4:10004),]
  numbers = df[-c(1:3),]
  
  if(target_var == 'filt_type'){
    target_row = 1
    alt1_row = 2
    alt2_row = 3
  } else if(target_var == 'age'){
    target_row = 2
    alt1_row = 1
    alt2_row = 3
  } else if(target_var == 'activity'){
    target_row = 3
    alt1_row = 1
    alt2_row = 2
  } else{
    stop('Error: invalid target variable')
  }
  
    
  output_df = data.frame('filt_type1' = NA, 'age1' = NA,
                         'activity1' = NA, 'data1_med' = NA,
                         'filt_type2' = NA, 'age2' = NA, 
                         'activity2' = NA, 'data2_med' = NA, 
                         'stat_alt' = NA, 'pval' = NA, 'significance' = NA)
  
  comparisons = 1:(ncol(df))
  for (i in 1:(length(comparisons)-1)){
    for (j in ((i+1):length(comparisons))){
      if(labels[target_row, i] != labels[target_row, j] &
         labels[alt1_row, i] == labels[alt1_row, j] &
         labels[alt2_row, i] == labels[alt2_row, j]){
        
        data1 = as.numeric(numbers[[i]])
        data2 = as.numeric(numbers[[j]])
        
        t1 = wilcox.test(data1, data2, alternative = 'two.sided', paired = FALSE)
        tpval = t1$p.value
        if (tpval < 0.1) {
          if (median(data1) > median(data2)) {
            t1 = wilcox.test(data1, data2, alternative = 'greater', paired = FALSE)
          } else {
            t1 = wilcox.test(data1, data2, alternative = 'less', paired = FALSE)
          }
        }
        talt = t1$alternative
        tpval = t1$p.value
        
        
        if (tpval < 0.05) {
          t_sig = 'significant'
        } else {
          t_sig = 'not significant'
        }
        
        
        current_df = data.frame('filt_type1' = labels[1,i], 
                                'age1' = labels[2,i],
                                'activity1' = labels[3,i], 
                                'data1_med' = median(data1),
                                'filt_type2' = labels[1,j], 
                                'age2' = labels[2,j],
                                'activity2' = labels[3,j], 
                                'data2_med' = median(data2), 
                                'stat_alt' = talt, 
                                'pval' = tpval, 
                                'significance' = t_sig)
        
        output_df = rbind(output_df, current_df)
        
      }
      
      
    }
  }
  
  output_df = na.omit(output_df)
  
  return(output_df)
}
