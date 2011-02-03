module Cagan
  # Table of rows and columns
  # Pretty simple stuff
  class Table
  
    @data = nil
    @headers = nil
    @rows = 0
    @cols = 0
  
    # Create from csv formated file 
    # or make a table with given number of rows
    #
    def initialize(file_or_rowcount)
      @headers = []
      @data = []
      @rows = 0
      @cols = 0
    
      if(file_or_rowcount.is_a? Numeric)
        rows = file_or_rowcount
        rows.times do
          @data << CaganRow.new(self, @rows, [])
          @rows = @rows + 1
        end
      else
        f = File.new(file_or_rowcount)
        f.each("\r") do |line|
          parts = line.split(",")
          if(@headers.empty?)
            @headers = parts.map{|p| p.strip.to_sym}
            @cols = parts.size
          else
            @data << CaganRow.new(self, @rows, parts.map{|p| p.strip.to_f})
            @rows = @rows + 1
          end
        end
      end
    end
  
    #generate a new column named symb based on block that is passed each row
    def gen(symb, &b)
      @data.each do|row|
        row.append(b.call(row).to_f)
      end
      @headers << symb
      @cols = @cols + 1
    end
  
    #print this puppy out
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
  
    class CaganRow
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
    
      def i
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
        return CaganRow.new(@table, di, ddata)
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
end