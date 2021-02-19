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
    includes('# test implicit pending') { @output }
    includes('# test explicit pending') { @output }
    includes('# tests explicit pending') { @output }
    tests('$?.exitstatus').returns(0) { $?.exitstatus }
  end

  tests('success') do
    @output = bin(path('success'))
    includes('+ success')             { @output }
    includes('inline tests')          { @output }
    includes('+ returns false')        { @output }
    tests('$?.exitstatus').returns(0) { $?.exitstatus }
  end

  tests('error') do
    @output = bin(path('error'))
    includes('ok + returns true')                   { @output }
    includes('1 errored and 1 succeeded')           { @output }

    tests('$?.exitstatus').returns(1) { $?.exitstatus }
  end

  tests('contained-error') do
    @output = bin(path('contained-error'))
    includes('ok + returns true')                   { @output }
    includes('1 failed, 1 errored and 1 succeeded') { @output }

    tests('$?.exitstatus').returns(1) { $?.exitstatus }
  end
end
