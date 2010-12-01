class STable
  @data = nil
  @headers = nil
  @rows = 0
  @cols = 0
  def initialize(file)
    @headers = []
    @data = []
    @rows = 0
    @cols = 0
    
    if(file.is_a? Numeric)
      rows = file
      rows.times do
        @data << SRow.new(self, @rows, [])
        @rows = @rows + 1
      end
    else
      f = File.new(file)
      f.each("\r") do |line|
        parts = line.split(",")
        if(@headers.empty?)
          @headers = parts.map{|p| p.strip.to_sym}
          @cols = parts.size
        else
          @data << SRow.new(self, @rows, parts.map{|p| p.strip.to_f})
          @rows = @rows + 1
        end
      end
    end
  end
  
  def gen(symb, &b)
    @data.each do|row|
      row.append(b.call(row).to_f)
    end
    @headers << symb
    @cols = @cols + 1
  end
  
  def to_s
    s = "h)\t"
    @headers.each do |h|
      s += h.to_s + "\t"
    end
    s += "\n"
    
    @rows.times do |row|
      s += "#{row.to_s})\t"
      @cols.times do |col|
        s += '%.3f' % @data[row][col].to_s + "\t"
      end
      s += "\n"
    end
    return s
  end
  
  def cols
    return @cols
  end
  
  def rows
    return @rows
  end
  
  def headers
    return @headers
  end
  
  def [](i)
    return @data[i]
  end
  
  class SRow
    @table
    @data
    @index
    def initialize(table, i, data)
      @table = table
      @data = data
      @index = i
    end
    def index
      return @index
    end
    
    def[](i)
      if(i.class == Symbol)
        return @data[@table.headers.index(i)] if @table.headers.index(i)
        throw Exception.new("#{i.to_s} undefined in table")
      else
        return @data[i]
      end
    end
    
    def delta
      ddata = []
      di = @index
      if(@index == 0)
        ddata = Array.new(@data.length, 0.0)
      else
        before = @table[@index-1]
        ddata = Array.new(@data.length){|i| @data[i]-before[i]}
      end
      return SRow.new(@table, di, ddata)
    end
    
    def length
      return @data.length
    end
    
    def append(val)
      @data << val
    end
    
    def drop(i)
      if(i.class == Symbol)
        return @data.delete_at(@table.headers.index(i))
      else
        return @data.delete_at([i])
      end
    end
  end
end
