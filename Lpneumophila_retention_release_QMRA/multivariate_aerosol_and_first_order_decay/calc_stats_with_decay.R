calc_stats = function(risk_type){
  filename = paste('results/with_decay_', risk_type, '.csv', sep = '')
  df = read.csv(filename, header = TRUE)
  new_df = df[-c(4:1004),]
  nums = df[-c(1:3),]
  
  find_stats_values = function(x){
    quants = quantile(as.numeric(x))
    me = mean(as.numeric(x))
    std = sd(as.numeric(x))
    y = c(quants, me, std)
    names(y) = c(names(quants), 'mean', 'std dev')
    return(y)
  }
  
  nums_stats = lapply(nums, find_stats_values)
  
  new_row_name = c('filt_type', 'age', 'activity', names(nums_stats[[1]]))
  
  for (i in 1:length(nums_stats[[1]])){
    a1 = c()
    for (j in 1:length(nums_stats)){
      a1 = c(a1, nums_stats[[j]][i])
    }
    new_df = rbind(new_df, a1)
  }
  
  row.names(new_df) = new_row_name
  
  new_df = data.frame(t(new_df))
  
  return(new_df)
}
