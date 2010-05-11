Shindo.tests('basics') do

  tests('exception') do
    @output = bin(path('exception'))
    returns(true, 'output') { @output.include?('- exception') }
    returns(true, 'status') { $?.exitstatus == 1 }
  end

  tests('failure') do
    @output = bin(path('failure'))
    returns(true, 'output') { @output.include?('- failure') }
    returns(true, 'status') { $?.exitstatus == 1 }
  end

  tests('pending') do
    @output = bin(path('pending'))
    returns(true, 'output') { @output.include?('* pending') }
    returns(true, 'status') { $?.exitstatus == 0 }
  end

  tests('success') do
    @output = bin(path('success'))
    returns(true, 'output') { @output.include?('+ success') }
    returns(true, 'status') { $?.exitstatus == 0 }
  end

  tests('returns') do
    returns(false) { false }
  end

  tests('raises') do
    raises(StandardError) { raise StandardError.new }
  end

end
