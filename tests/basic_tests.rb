Shindo.tests('basics') do

  returns(false) { false }
  raises(StandardError) { raise StandardError.new }

  tests('exception') do
    @output = bin(path('exception'))
    includes('- exception') { @output }
    returns(1, 'status')    { $?.exitstatus }
  end

  tests('failure') do
    @output = bin(path('failure'))
    includes('- failure') { @output }
    returns(1, 'status')  { $?.exitstatus }
  end

  tests('pending') do
    @output = bin(path('pending'))
    includes('# pending') { @output }
    returns(0, 'status')  { $?.exitstatus }
  end

  tests('success') do
    @output = bin(path('success'))
    includes('+ success') { @output }
    returns(0, "status") { $?.exitstatus }
  end

end
