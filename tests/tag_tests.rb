Shindo.tests('tags') do

  tests('negative') do
    before do
      @output = bin("#{path('negative')} -negative")
    end
    test('is tested')   { @output.include?('+ is tested') }
    test('is skipped')  { @output.include?('_ is skipped (negative)') }
    test('status')      { $?.exitstatus == 0 }
  end

  tests('positive') do
    before do
      @output = bin("#{path('positive')} +positive")
    end
    test('is tested')   { @output.include?('+ is tested (positive)') }
    test('is skipped')  { @output.include?('_ is skipped') }
    test('status')      { $?.exitstatus == 0 }
  end

end
