require "matrix.rb"
module Cagan
  # Nonlinear Regression engine using Gauss-Newton
  #
  class NonlinearRegressor
    @resolution = 4 #how many decimal places make for a floating point inequality
    @max_rounds = 100 #give up after this many iterations
    def initialize
      @resolution = 4
      @max_rounds = 100
    end
  
    # Estimate the function f
    # Table table -- table of data
    # Symbol lhs -- variable that is being estimates
    # Hash current_estimators hash of {:estimator_name =>currentvalue.00, ...}
    #
    # returns: {:best=>lowest variance 
    #           :current=>variance estimation was stopped at, 
    #           :r_sq =>coeff. of determination, 
    #           :r=>residuals
    #          }
    #
    def estimate (table, lhs, current_estimators, &f)
      run_error = {}
      i = 1;
    
      throw Exception.new("table column names and estimator names can't collide") if((table.headers & current_estimators.keys).size > 0)
    
      run_error = run(table, lhs, current_estimators, &f)
      best = {:estimators=>current_estimators.clone, :error=>run_error }
      begin
        next_estimators = next_estimate(table, lhs, current_estimators, &f)
        current_error = run(table, lhs, next_estimators, &f)
      
        diff  = false
        current_estimators.each_pair do |k, v|
          if(round(v-next_estimators[k]).abs != 0)
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
        #puts "%d)\t  b:%.2f c%.2f" % [i, best[:error][:r_sq], run_error[:r_sq]]
      
      end while diff and i < @max_rounds
    
    
      #predict
      predict = []
      table.rows.times do |row|
        context = RegressionContext.new(row, table, best[:estimators])
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
    
      return {:best => best, :predict=>predict, :r_sq => r_sq, :r=>r_sq}
    end
  
    private
    def run(table, lhs, estimator_hash, &f)
      error = {:r => 0, :r_sq => 0}
      table.rows.times do |row|
        context = RegressionContext.new(row, table, estimator_hash)
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
          deriv = naive_numerical_deriv(key, row_i, table, estimators, &f)
          row << deriv
        end
        j_rows << row
      
        predicted = f.call(RegressionContext.new(row_i, table, estimators))
        expected = table[row_i][lhs]
        residuals << expected - predicted
        #puts "#{expected} -> #{predicted} :: " +  (expected - predicted).to_s + "( @ #{estimators})"
      end
    
    
      ## Here lie matrix maths
    
      j = Matrix.rows(j_rows)
      r = Matrix.column_vector(residuals)
      jt = j.transpose
    
      ## multiply the jacobian by its transpose and invert the whole thing
      h = ((jt * j).inverse)
    
      #negate the result
      h = h.map do |elem| -elem end
      
      # multiply the jacobian transpose by the residual vector
      g = jt * r
    
      #our deltas are essentially a function of affect on final expectation and effect on final expectation
      deltas = h * g
    
      #adjust by deltas
      estimators.keys.each_index do |i|
        key = estimators.keys[i]
        estimators[key] = round(estimators[key] - 0.7 * deltas[i,0])
      end
      
    
      return estimators
    end
  
  
    #5-point stencil
    def naive_numerical_deriv(x_var, row, table, estimators, &f)
      o = estimators[x_var];
      h = Math.sqrt(0.0056)*o # a nice machine epsilon
      t = o + h
      h = t - o
    
      estimators[x_var] = o + (2.0 * h)
      f_x_a = -f.call(RegressionContext.new(row, table, estimators))
    
      estimators[x_var]  = o + h
      f_x_b = 8.0 * f.call(RegressionContext.new(row, table, estimators))
    
    
      estimators[x_var]  = o - h
      f_x_c = -8.0 * f.call(RegressionContext.new(row, table, estimators))
    
      estimators[x_var] = o - (2.0 * h)
      f_x_d = f.call(RegressionContext.new(row, table, estimators))
      estimators[x_var] = o
      dy_dx = (f_x_a + f_x_b + f_x_c + f_x_d )/(12.0*h)
      return dy_dx
    end
  
    def round(num)
      (num * 10**@resolution).round.to_f / 10**@resolution
    end
  end
end