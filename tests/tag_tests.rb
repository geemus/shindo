Shindo.tests('tags') do

  tests('negative') do
    @output = bin("#{path('negative')} -negative")
    returns(true, 'is tested')   { @output.include?('+ is tested') }
    returns(true, 'is skipped')  { @output.include?('skipped (negative)') }
    returns(true, 'status')      { $?.exitstatus == 0 }
  end

  tests('positive') do
    @output = bin("#{path('positive')} +positive")
    returns(true, 'is tested')   { @output.include?('+ is tested') }
    returns(true, 'is skipped')  { @output.include?('skipped') }
    returns(true, 'status')      { $?.exitstatus == 0 }
  end

end
