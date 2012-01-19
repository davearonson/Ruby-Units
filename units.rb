module Units

  class Unit

    attr_reader :name, :parts, :scale

    # for making base units; others are made w/ * or /.
    def initialize _name
      @name = _name
      @parts = { self => 1 }
      @scale = 1.0
    end

    def compatible? other
      return true if other.equal? self              # same *object*
      return true if other.parts == self.parts
      return true if other.parts == { self  => 1 }  # one is a scaling of the other
      return true if self .parts == { other => 1 }
      false
    end

    # size ratio of self to other -- how many of them are in one of me
    def ratio other
      raise UnitsError.new "Ratio error: unit mismatch" if ! self.compatible? other
      1.0 * self.scale / other.scale  # need 1.0 in case both are integer
    end

    def * other
      tmp = self.clone
      tmp.name = ''
      tmp.parts = self.parts.clone
      if Unit === other
        other.parts.each do |unit,power|
          tmp.parts[unit] ||= 0
          tmp.parts[unit] += power
          tmp.parts.delete unit if tmp.parts[unit] == 0
        end
        tmp.scale *= other.scale
      elsif Numeric === other
        tmp.scale *= other
      else
        raise UnitsError.new "Unit multiplication error: second operand must be a Unit or number, got #{other.inspect}!"
      end
      base = tmp.boildown
      base ? base : tmp
    end

    def / other
      if Unit === other
        self * other.invert
      elsif Numeric === other
        self * (1.0 / other)
      else
        raise UnitsError.new "Unit divison error: second operand must be a Unit or number, got #{other.inspect}!"
      end
    end

    def == other
      self.parts == other.parts && ( self.scale - other.scale ).abs <= Float::EPSILON
    end

  protected

    def boildown
      return nil if @parts.length != 1
      return nil if @scale != 1
      base = parts.keys.first 
      return base if parts[base] == 1
      nil
    end

    def invert
      tmp = self.clone
      tmp.name = ''
      tmp.parts = self.parts.clone
      tmp.parts.keys.each { |base| tmp.parts[base] *= -1 }
      tmp.scale = 1.0 / tmp.scale
      tmp
    end

    def name= n
      @name = n
    end

    def parts= p
      @parts = p
    end

    def scale= s
      @scale = s
    end

  end


  class UnitsError < Exception
  end


  class Measure

    attr_accessor :quantity, :unit

    def initialize quantity, unit
      @quantity = quantity
      @unit = unit
    end

    def + other
      raise UnitsError.new "Measurement addition error: unit mismatch" if ! self.compatible? other
      Measure.new( self.quantity + other.quantity / self.unit.ratio(other.unit),
                   self.unit )
    end

    def - other
      raise UnitsError.new "Measurement subtraction error: unit mismatch" if ! self.compatible? other
      self + (-other)  # a bit slower, but robust in case we redefine +
    end

    def * other
      Measure.new( self.quantity * other.quantity, self.unit * other.unit )
    end

    def / other
      Measure.new( 1.0 * self.quantity / other.quantity, self.unit / other.unit )
    end

    def -@
      Measure.new -@quantity, @unit
    end

    def == other
      raise UnitsError.new "Measurement comparison error: unit mismatch" if ! self.compatible? other
      ( self.quantity - (other.quantity / self.unit.ratio(other.unit) )).abs <=  2 * Float::EPSILON
    end

    def compatible? other
      self.unit.compatible? other.unit
    end

  end

end
