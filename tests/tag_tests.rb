Shindo.tests('tags') do

  tests('negative') do
    @output = bin("#{path('negative')} -negative")
    test('is tested')   { @output.include?('+ is tested') }
    test('is skipped')  { @output.include?('skipped (negative)') }
    test('status')      { $?.exitstatus == 0 }
  end

  tests('positive') do
    @output = bin("#{path('positive')} +positive")
    test('is tested')   { @output.include?('+ is tested') }
    test('is skipped')  { @output.include?('skipped') }
    test('status')      { $?.exitstatus == 0 }
  end

end
