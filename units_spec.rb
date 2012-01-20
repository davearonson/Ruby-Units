require './units'
include Units

describe 'Unit' do

  describe 'creation' do

    it 'creates base units' do
      name = 'whatever'
      u = Unit.new name
      u.name.should == name
      u.parts.should == { u => 1 }
      u.scale.should == 1.0
    end

  end

  describe 'compatibility' do
    
    it 'detects exact match' do
      u = Unit.new
      u.compatible?(u).should be_true
    end

    it 'detects base mismatch' do
      m = Unit.new 'm'
      s = Unit.new 's'
      m.compatible?(s).should be_false
    end

    it 'detects base vs complex mismatch w/ overlap' do
      m = Unit.new 'm'
      s = Unit.new 's'
      mps = (m / s)
      m.compatible?(mps).should be_false
      mps.compatible?(m).should be_false
    end

    it 'detects base vs complex mismatch w/o overlap' do
      m = Unit.new 'm'
      s = Unit.new 's'
      mps = m / s
      kg = Unit.new 'kg'
      kg.compatible?(mps).should be_false
      mps.compatible?(kg).should be_false
    end

    it 'detects complex mismatch w/ overlap' do
      m = Unit.new 'm'
      s = Unit.new 's'
      mps = m / s
      kg = Unit.new 'kg'
      n = kg * mps / s
      n.compatible?(mps).should be_false
      mps.compatible?(n).should be_false
    end

    it 'detects complex mismatch w/o overlap' do
      m = Unit.new 'm'
      s = Unit.new 's'
      mps = m / s
      kelvin = Unit.new 'kelvin'
      kg = Unit.new 'kg'
      kpk = kelvin / kg
      kpk.compatible?(mps).should be_false
      mps.compatible?(kpk).should be_false
    end

    it 'detects one scaling the other' do
      m = Unit.new 'm'
      i = m / 39.37
      i.compatible?(m).should be_true
      m.compatible?(i).should be_true
    end

  end

  describe 'ratios' do

    it 'determines proper ratio directly' do
      ft = Unit.new 'ft'
      yd = ft * 3
      inch = ft / 12

      inch.ratio(inch).should == 1
      inch.ratio(ft).should == 1.0 / 12
      inch.ratio(yd).should == 1.0 / 36
      
      ft.ratio(inch).should == 12
      ft.ratio(ft).should == 1
      ft.ratio(yd).should == 1.0 / 3
      
      yd.ratio(inch).should == 36
      yd.ratio(ft).should == 3
      yd.ratio(yd).should == 1
      
    end

    it 'determines proper ratio indirectly' do
      ft = Unit.new 'ft'
      sf = ft * ft
      yd = ft * 3
      sy = yd * yd
      inch = ft / 12
      si = inch * inch

      si.ratio(si).should == 1
      si.ratio(sf).should == 1.0 / 144
      si.ratio(sy).should == 1.0 / 1296

      sf.ratio(si).should == 144
      sf.ratio(sf).should == 1
      sf.ratio(sy).should == 1.0 / 9

      sy.ratio(si).should == 1296
      sy.ratio(sf).should == 9
      sy.ratio(sy).should == 1

    end

    it 'rejects incompatible units' do
      inch = Unit.new 'inch'
      second = Unit.new 'second'
      lambda { ignored = inch.ratio second }.should raise_error Units::UnitsError
    end

  end

  describe 'multiplication' do

    it 'works for one base twice' do
      m = Unit.new 'meter'
      (m * m).parts.should == { m => 2 }
    end

    it 'works for two bases' do
      u1 = Unit.new 'whatever'
      u2 = Unit.new 'something else'
      (u1 * u2).parts.should == { u1 => 1, u2 => 1 }
    end

    it 'works for non-bases' do
      m = Unit.new 'meter'
      s = Unit.new 'second'
      mps = m / s
      k = Unit.new 'kg'
      kmps = mps * k
      n = kmps / s
      j = n * m
      j.parts.should == { k => 1, m => 2, s => -2 }
    end

    it 'works with constants' do
      f = Unit.new 'foot'
      y = f * 3
      y.parts.should == { f => 1 }
      y.scale.should == 3
    end

    it 'works for scaled units' do
      a = Unit.new 'whatever'
      halfa = a / 2
      b = Unit.new 'something else'
      threeb = b * 3
      prod = halfa * threeb
      prod.scale.should == 1.5
      prod.parts.should == { a => 1, b => 1 }
    end

    it 'removes zeroed-out subunits' do
      mile = Unit.new 'mile'
      gallon = Unit.new 'gallon'
      mpg = mile / gallon
      mpg.parts.should == { mile => 1, gallon => -1 }
      (mpg * gallon).parts.should == { mile => 1 }
    end

  end

  describe 'division' do

    it 'works right with bases' do
      m = Unit.new 'meter'
      s = Unit.new 'second'
      (m / s ).parts.should == { m => 1, s => -1 }
    end

    it 'works right with non-bases' do
      m = Unit.new 'meter'
      s = Unit.new 'second'
      mps = m / s
      k = Unit.new 'kg'
      kmps = mps * k
      n = kmps / s
      n.parts.should == { k => 1, m => 1, s => -2 }
    end

    it 'works with constants' do
      m = Unit.new 'meter'
      i = m / 39.37
      i.parts.should == { m => 1 }
      i.scale.should == 1 / 39.37
    end

    it 'works for scaled units' do
      a = Unit.new 'whatever'
      halfa = a / 2
      b = Unit.new 'something else'
      threeb = b * 3
      quotnt = halfa / threeb
      quotnt.scale.should == 1.0 / 6
      quotnt.parts.should == { a => 1, b => -1 }
    end

    it 'works with complete cancellation' do
      a = Unit.new 'whatever'
      b = a * 5
      c = b * b / a
      d = c / c
      d.parts.should == {}
      d.scale.should == 1.0
    end

  end

  describe 'to_s' do

    it 'works for a named base' do
      name = 'whatever'
      Unit.new(name).to_s.should == "#{name}"
    end

    it 'works for an unnamed base' do
      Unit.new.to_s.should == "UNKNOWN_UNIT"
    end

    it 'works for a positive powered base' do
      name = 'whatever'
      u1 = Unit.new name
      (u1 * u1 * u1).to_s.should == "#{name} ^ 3"
    end

    it 'works for a negative powered base' do
      name = 'whatever'
      u1 = Unit.new name
      (u1 / (u1 * u1 * u1)).to_s.should == "#{name} ^ -2"
    end

    it 'works for a named scaled unit' do
      inch = Unit.new 'inch'
      foot = (inch * 12).name! 'foot'  # NOTE NAME!
      foot.to_s.should == 'foot'
    end

    it 'works for an unnamed scaled unit' do
      inch = Unit.new 'inch'
      foot = inch * 12  # NOTE NO NAME!
      foot.to_s.should == '12.0 inch'  # scale is always float
    end

    it 'works for a named complex unit' do
      kg = Unit.new 'kg'
      m = Unit.new 'm'
      s = Unit.new 's'
      n = (kg * m / (s * s)).name! 'n'
      j = (n * m).name! 'j'
      w = (j / s).name! 'w'
      # note: doesn't matter whether we name n or j
      w.to_s.should == 'w'
    end

    it 'works for an UNnamed complex unit' do
      kg = Unit.new 'kg'
      m = Unit.new 'm'
      s = Unit.new 's'
      n = (kg * m / (s * s)).name! 'n'
      j = (n * m).name! 'j'
      w = (j / s)
      # note: doesn't matter whether we name n or j
      w.to_s.should == 'kg m ^ 2 / s ^ 3'
    end

    it 'works for a named scaled complex unit' do
      kg = Unit.new 'kg'
      m = Unit.new 'm'
      s = Unit.new 's'
      n = kg * m / (s * s)
      j = n * m
      w = j / s
      kw = w * 1000
      h = s * 3600
      kwh = (kw * h).name! 'kwh'
      kwh.to_s.should == 'kwh'
    end

    it 'works for an UNnamed scaled complex unit' do
      kg = Unit.new 'kg'
      m = Unit.new 'm'
      s = Unit.new 's'
      n = kg * m / (s * s)
      j = n * m
      w = j / s
      kw = w * 1000
      h = s * 3600
      kwh = kw * h
      kwh.to_s.should == '3600000.0 kg m ^ 2 / s ^ 2'
    end

  end

end


describe Measure do

  describe 'creation' do

    it 'has the right unit' do
      unit = Unit.new 'blah'
      qty = 3
      m = Measure.new( qty, unit )
      m.quantity.should == qty
      m.unit.should == unit
    end

  end

  describe 'inversion' do
    it 'works' do
      m = Unit.new
      s = Unit.new
      Measure.new( 4,  m / s ).invert.should == Measure.new( 0.25, s / m )
    end
  end

  describe 'comparison' do

    it 'rejects incompatible units' do
      foot = Measure.new 12, Unit.new('inch')
      minute = Measure.new 60, Unit.new('second')
      lambda { ignored = foot == minute }.should raise_error Units::UnitsError
    end

  end

  describe 'explicit conversion' do
    it 'works' do
      f = Unit.new
      s = Unit.new
      fps = f / s
      y = f * 3
      min = s * 60
      ypm = y / min
      m = Measure.new( 10, fps ).convert( ypm )
      m.quantity.should == 200
      m.unit.should == ypm
    end
  end

  describe 'implicit conversion' do

    it 'applies * scaled units' do
      ft = Unit.new 'foot'
      yd = ft * 3
      Measure.new( 1, yd ).should == Measure.new( 3, ft )
      Measure.new( 1, ft ).should == Measure.new( 1/3.0, yd )
    end

    it 'applies / scaled units' do
      yd = Unit.new 'yard'
      ft = yd / 3
      Measure.new( 1, yd ).should == Measure.new( 3, ft )
      Measure.new( 1, ft ).should == Measure.new( 1/3.0, yd )
    end

    it 'applies indirectly scaled units' do
      ft = Unit.new 'foot'
      yd = ft * 3
      inch = ft / 12
      Measure.new( 1, yd ).should == Measure.new( 36, inch )
      Measure.new( 1, inch ).should == Measure.new( 1.0/36, yd )
    end

    it 'applies multiple scaled units' do
      yd = Unit.new 'yd'
      ft = yd / 3
      sec = Unit.new 'sec'
      min = sec * 60
      fps = ft / sec
      ypm = yd / min
      Measure.new( 10, fps ).should == Measure.new( 200, ypm )
    end

  end

  describe 'addition' do

    it 'works with matching units' do
      q1 = 3
      q2 = 5
      u = Unit.new 'whatever'
      m1 = Measure.new q1, u
      m2 = Measure.new q2, u
      (m1 + m2).should == Measure.new( q1 + q2, u )
    end

    it 'works with compatible units' do
      ratio = 12
      inch = Unit.new 'inch'
      foot = inch * 12
      sum = Measure.new( 0.5, foot ) + Measure.new( 3, inch )
      sum.should == Measure.new( 0.75, foot )
      sum.should == Measure.new( 9, inch )
    end

    it 'rejects incompatible units' do
      foot = Measure.new 12, Unit.new('inch')
      minute = Measure.new 60, Unit.new('second')
      lambda { ignored = foot + minute }.should raise_error Units::UnitsError
    end

  end

  describe 'negation' do

    it 'works' do
      q = 3
      u = Unit.new 'whatever'
      m = Measure.new q, u
      neg = -m
      neg.quantity.should == -q
      neg.unit.should == u
    end

  end

  describe 'subtraction' do

    it 'works with matching units' do
      q1 = 3
      q2 = 5
      u = Unit.new 'whatever'
      m1 = Measure.new q1, u
      m2 = Measure.new q2, u
      (m2 - m1).should == Measure.new( q2 - q1, u )
    end

    it 'works with compatible units' do
      ratio = 12
      inch = Unit.new 'inch'
      foot = inch * 12
      sum = Measure.new( 0.5, foot ) - Measure.new( 2, inch )
      sum.should == Measure.new( 1.0/3, foot )
      sum.should == Measure.new( 4, inch )
    end

    it 'rejects incompatible units' do
      foot = Measure.new 12, Unit.new('inch')
      minute = Measure.new 60, Unit.new('second')
      lambda { ignored = foot - minute }.should raise_error Units::UnitsError
    end

  end

  describe 'multiplication' do

    it 'winds up with correct answer' do
      u1 = Unit.new 'first unit'
      q1 = 3
      m1 = Measure.new q1, u1
      u2 = Unit.new 'second unit'
      q2 = 5
      m2 = Measure.new q2, u2
      prod = m1 * m2
      prod.quantity.should == q1 * q2
      prod.unit.parts.should == { u1 => 1, u2 => 1 }
    end

  end

  describe 'division' do

    it 'winds up with correct answer' do
      u1 = Unit.new 'first unit'
      q1 = 3
      m1 = Measure.new q1, u1
      u2 = Unit.new 'second unit'
      q2 = 4
      m2 = Measure.new q2, u2
      quotnt = m1 / m2
      quotnt.quantity.should == 1.0 * q1 / q2  # force to float
      quotnt.unit.parts.should == { u1 => 1, u2 => -1 }
    end

  end


  describe 'to_s' do

    # don't need to test anything more complex than this *here*;
    # it should be tested in Unit's tests
    it 'works' do
      q = 1.5
      name = 'blah'
      Measure.new( q, Unit.new(name)).to_s.should == "#{q} #{name}"
    end

  end

end
