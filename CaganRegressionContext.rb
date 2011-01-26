
# Context to hold a current row, table, and hash of estimators
# Exists so that every invocation of the optimized function is on a particular row
class CaganRegressionContext
  def initialize(row, table, estimator_hash)
    @row = row
    @table = table
    @estimator_hash = estimator_hash
  end    
  
  # If there's no method on the context it should be in the table or in the estimators
  def method_missing(name, *args)
    sym = name.to_sym
    return @table[@row][sym] if(@table.headers.index(sym))
    return @estimator_hash[sym] if(@estimator_hash.key?sym)
    return @row if(sym == :i)
    throw Exception.new("Undefined value in context: #{sym.to_s}")
  end
  
  def[](i)
    return CaganRegressionContext.new(i, @table, @estimator_hash)
  end
end