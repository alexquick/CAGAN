include Math
require "../Table.rb"
require "../RegressionContext.rb"
require "../NonlinearRegressor.rb"

# Some code exercising the NLR.
# Polynomials work fine.
# Mess around with the cagan stuff to test it out for real
# because those functions are not analytic
# (you might get a singular matrix)

def sum(from, to, &b)
  accumulator = 0.0
  Range.new(from, to).each do |i|
    accumulator += b.call(i)
  end
  return accumulator
end

def dump(res)
  puts "\n\n"
  res[:predict].each do |item|
    puts "%d) expected: %.2f \t got: %.2f \t residual: %.2f \t residual_sq: %.2f" % item
  end
  puts "\n\n"
  puts res[:best]

  puts "r-square: #{res[:r_sq]}"
end

def cagan(table)
  nl = NonlinearRegressor.new
  res = nl.estimate(table, :real_bal,  {:alpha=>3.63, :beta=>0.15, :lambda=>-5.4}) do |c|
    if(c.beta < 0.0001)
      est_T = table.rows
    else
      i = 0.00005/(1-exp(-c.beta))
      i = 0 if i < 0
      est_T = -(log(i)/c.beta)+0
      est_T = est_T.round
    end
    est_T = c.i-1 if c.i != 0
    lbound = 0
    lbound = c.i - est_T if(c.i > est_T)
    c.alpha * -1 * ((1-exp(c.beta))/(exp(c.beta * c.i))) * sum(lbound,c.i){|x| c[x].c * exp(c.beta * x)} - c.lambda
  end
  return res
end

def modified_cagan(table)
  nl = NonlinearRegressor.new
  res = nl.estimate(table, :real_bal, {:alpha=>3.63, :beta=>0.15, :lambda=>-5.4}) do |c|
    c.alpha * c.c + c.beta * log(c.c) + c.lambda
  end
  return res
end

def england
  m = Table.new("hengland.csv")
  m.gen(:ln_p) {|r| log10(r[:p])}
  m.gen(:ln_m) {|r| log10(r[:m])}
  m.gen(:real_bal){|r| log10(r[:m]/r[:p])}
  res = cagan(m)
end

def hungary
  m = Table.new("hungary2.csv")
  m.gen(:real_bal) do |row|
    log(1/(10**row[:log_p_m]))
  end
  res = cagan(m)
end

def poly
  m = Table.new(200)
  x = -100
  m.gen(:x){|r|x+=1; x;}
  m.gen(:y){|r|5*r[:x] - (4*r[:x]**2) + 56.5}
  puts m
  nl = NonlinearRegressor.new
  res = nl.estimate(m, :y, {:a=>-5.0, :b=>4.00, :c=>-10, :d=>3}) do |c|
    (c.a * c.x) + (c.b * (c.x**2)) + (c.c * (c.x**3)) + c.d
  end
  dump res
end

poly

