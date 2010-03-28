Shindo.tests('tags') do

  tests('negative') do
    before do
      @tempfile = tempfile('negative', <<-TESTS)
      Shindo.tests do
        test('is tested') { true }
        test('is skipped', 'negative') { false }
      end
      TESTS
      @output = bin("#{@tempfile.path} -negative")
    end
    test('is tested')   { @output.include?('+ is tested') }
    test('is skipped')  { @output.include?('_ is skipped (negative)') }
    test('status')      { $?.exitstatus == 0 }
  end

  tests('positive') do
    before do
      @tempfile = tempfile('positive', <<-TESTS)
      Shindo.tests do
        test('is tested', 'positive') { true }
        test('is skipped') { false }
      end
      TESTS
      @output = bin("#{@tempfile.path} +positive")
    end
    test('is tested')   { @output.include?('+ is tested (positive)') }
    test('is skipped')  { @output.include?('_ is skipped') }
    test('status')      { $?.exitstatus == 0 }
  end

end
