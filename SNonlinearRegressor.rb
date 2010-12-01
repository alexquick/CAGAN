require "SRegressionContext.rb"
require "matrix.rb"
class SNonlinearRegressor

  def estimate (table, lhs, current_estimators, &f)
    run_error = {}
    i = 1;
    
    run_error = run(table, lhs, current_estimators, &f)
    best = {:estimators=>current_estimators.clone, :error=>run_error }
    begin
      next_estimators = next_estimate(table, lhs, current_estimators, &f)
      
      current_error = run(table, lhs, next_estimators, &f)
      
      puts "%.2f = >%.2f (%s)" % [current_error[:r_sq], run_error[:r_sq], current_estimators]
      
      diff  = false
      current_estimators.each_pair do |k, v|
        if((v-next_estimators[k]).abs > 0.00001)
          diff = true
          break
        end
      end
      
      run_error = current_error
      current_estimators = next_estimators
      
      if(best[:error].empty? or best[:error][:r_sq] > run_error[:r_sq])
        best[:estimators]=current_estimators.clone
        best[:error] = run_error
      end
      
      
      i+=1
      puts "%d)\t  b:%.2f c%.2f" % [i, best[:error][:r_sq], run_error[:r_sq]]
      
    end while diff and i < 50
    
    
    #predict
    predict = []
    table.rows.times do |row|
      context = SRegressionContext.new(row, table, best[:estimators])
      got = f.call(context);
      expected = table[row][lhs];
      residual = (expected-got)
      residual_sq = residual**2
      predict << [context.i, expected, got, residual, residual_sq]
    end
    n=table.rows
    ssTot = 0
    ssErr = 0
    y_hat = 0.0
    table.rows.times do |i|
      y_hat += predict[i][1] #expected
    end
    y_hat = y_hat/n
    table.rows.times do |i|
      ssTot += (predict[i][1] - y_hat)**2
      ssErr += predict[i][4]
    end
    
    
    
    r_sq = 1-(ssErr/ssTot)
    puts "fail: #{r_sq}" if(r_sq < 0)
    
    return {:best => best, :predict=>predict, :r_sq => r_sq, :r=>sqrt(r_sq)}
  end
  
  def run(table, lhs, estimator_hash, &f)
    error = {:r => 0, :r_sq => 0}
    table.rows.times do |row|
      context = SRegressionContext.new(row, table, estimator_hash)
      got = f.call(context)
      expected = table[row][lhs]
      error[:r] += (expected-got)
      error[:r_sq] += (expected-got)**2 
    end
    return error
  end
  
  def next_estimate(table, lhs, estimators, &f)
    j_rows = []
    residuals = []
    keys = estimators.keys
    estimators = estimators.clone
    table.rows.times do |row_i|
      row = []
      estimators.each_key do |key|
        row << naive_numerical_deriv(key, row_i, table, estimators, &f)
      end
      j_rows << row
      
      predicted = f.call(SRegressionContext.new(row_i, table, estimators))
      expected = table[row_i][lhs]
      residuals << expected - predicted
    end
    
    j = Matrix.rows(j_rows)
    #puts j
    r = Matrix.column_vector(residuals)
    #puts r
    jt = j.transpose
    
    h = ((jt * j).inverse)
    puts h
    h = h.map()do |elem| -elem end
    puts h
    g = jt * r
    deltas = h * g
    puts deltas
    
    estimators.keys.each_index do |i|
      key = estimators.keys[i]
      puts " Adjusting #{key} from #{estimators[key]} to " +(estimators[key] - 0.5 * deltas[i,0]).to_s
      estimators[key] -= 0.5 * deltas[i,0]
    end
      
    
    return estimators
  end
  
  def naive_numerical_deriv(x_var, row, table, estimators, &f)
    o = estimators[x_var];
    h = Math.sqrt(0.0000000596) * o
    t = o + h
    h = t - o
    estimators[x_var] = o + 2 * h
    f_x_a = -f.call(SRegressionContext.new(row, table, estimators))
    estimators[x_var]  = o + h
    f_x_b = 8 * f.call(SRegressionContext.new(row, table, estimators))
    estimators[x_var]  = o - h
    f_x_c = -8 * f.call(SRegressionContext.new(row, table, estimators))
    estimators[x_var] = o - 2 * h
    f_x_d = f.call(SRegressionContext.new(row, table, estimators))
    estimators[x_var] = o
    return (f_x_a + f_x_b + f_x_c + f_x_d )/(12*h)
  end
end
