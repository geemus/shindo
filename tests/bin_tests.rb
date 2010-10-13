Shindo.tests('bin') do

  tests('exception') do
    @output = bin(path('exception'))
    includes('- exception')           { @output }
    tests('$?.exitstatus').returns(1) { $?.exitstatus }
  end

  tests('failure') do
    @output = bin(path('failure'))
    includes('- failure')             { @output }
    tests('$?.exitstatus').returns(1) { $?.exitstatus }
  end

  tests('pending') do
    @output = bin(path('pending'))
    includes('# implicit pending') { @output }
    includes('# explicit pending') { @output }
    tests('$?.exitstatus').returns(0) { $?.exitstatus }
  end

  tests('success') do
    @output = bin(path('success'))
    includes('+ success')             { @output }
    tests('$?.exitstatus').returns(0) { $?.exitstatus }
  end

end