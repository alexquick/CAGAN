require "STable.rb"
class SRegressionContext
  def initialize(row, table, estimator_hash)
    @row = row
    @table = table
    @estimator_hash = estimator_hash
  end    
  
  def method_missing(name, *args)
    sym = name.to_sym
    return @table[@row][sym] if(@table.headers.index(sym))
    return @estimator_hash[sym] if(@estimator_hash.key?sym)
    return @row if(sym == :i)
    throw Exception.new("Undefined value in context: #{sym.to_s}")
  end
  
  def[](i)
    return SRegressionContext.new(i, @table, @estimator_hash)
  end
end