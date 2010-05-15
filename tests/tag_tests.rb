Shindo.tests('tags') do

  tests('negative') do
    @output = bin("#{path('negative')} -negative")
    includes('+ is tested')         { @output }
    includes('skipped (negative)')  { @output }
    returns(0)                      { $?.exitstatus }
  end

  tests('positive') do
    @output = bin("#{path('positive')} +positive")
    includes('+ is tested') { @output }
    includes('skipped')     { @output }
    returns(0)              { $?.exitstatus }
  end

end
