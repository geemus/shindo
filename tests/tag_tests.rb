require File.join(File.dirname(__FILE__), 'tests_helper')

negative = Tempfile.new('negative')
negative << <<-TESTS
Shindo.tests do
  test('is tested') { true }
  test('is skipped', 'negative') { false }
end
TESTS
negative.close

positive = Tempfile.new('positive')
positive << <<-TESTS
Shindo.tests do
  test('is tested', 'positive') { true }
  test('is skipped') { false }
end
TESTS
positive.close

Shindo.tests('tags') do

  tests('negative') do
    before { @output = `#{BIN} #{negative.path} -negative` }
    test('is tested')   { @output.include?('+ is tested') }
    test('is skipped')  { @output.include?('_ is skipped (negative)') }
    test('status')      { $?.exitstatus == 0 }
  end

  tests('positive') do
    before { @output = `#{BIN} #{positive.path} +positive` }
    test('is tested')   { @output.include?('+ is tested (positive)') }
    test('is skipped')  { @output.include?('_ is skipped') }
    test('status')      { $?.exitstatus == 0 }
  end

end
