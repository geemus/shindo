Shindo.tests('bin') do

  tests("negative -negative") do
    @output = bin("#{path('negative')} -negative")
    includes('+ is tested')           { @output }
    includes('skipped (negative)')    { @output }
    tests('$?.exitstatus').returns(0) { $?.exitstatus }
  end

  tests("positive +positive") do
    @output = bin("#{path('positive')} +positive")
    includes('+ is tested')           { @output }
    includes('skipped')               { @output }
    tests('$?.exitstatus').returns(0) { $?.exitstatus }
  end

end
