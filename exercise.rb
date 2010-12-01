include Math
require "STable.rb"
require "SNonlinearRegressor.rb"


def sum(from, to, &b)
  accumulator = 0.0
  Range.new(from, to).each do |i|
    accumulator += b.call(i)
  end
  return accumulator
end

m = STable.new("hengland.csv")
m.gen(:ln_p) {|r| log10(r[:p])}
m.gen(:ln_m) {|r| log10(r[:m])}
m.gen(:real_bal){|r| log10(r[:m]/r[:p])}

x = -1;
m.gen(:x){|r| x=x+1;x}
m.gen(:y){|r| 5*r[:x]+1}

neg_T = 24
nl = SNonlinearRegressor.new
res = nl.estimate(m, :real_bal, {:alpha=>-4.0, :beta=>0.5, :lambda=>-3.0}) do |c|
  lbound = 0
  lbound = c.i - neg_T if(c.i > neg_T)
  c.alpha * -1 * ((1-exp(c.beta))/(exp(c.beta * c.i))) * sum(lbound,c.i){|x| c[x].c * exp(c.beta * x)} - c.lambda
end


# res = nl.estimate(m, :real_bal, {:alpha=>4.0, :beta=>1.0}) do |c|
#   c.alpha * c.real_bal + c.beta - 5
# end
# res = nl.estimate(m, :y, {:alpha=>10.0, :k=>3.0}) do |c|
#   c.alpha * c.x + c.k
# end
puts "\n\n"
res[:predict].each do |item|
  puts "%d) expected: %.2f \t got: %.2f \t residual: %.2f \t residual_sq: %.2f" % item
end
puts "\n\n"
puts res[:best]

puts "r-square: #{res[:r_sq]}"
