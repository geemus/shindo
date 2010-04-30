Shindo.tests('basics') do
  tests('exception') do
    @output = bin(path('exception'))
    test('output') { @output.include?('- exception') }
    test('status') { $?.exitstatus == 1 }
  end
  tests('failure') do
    @output = bin(path('failure'))
    test('output') { @output.include?('- failure') }
    test('status') { $?.exitstatus == 1 }
  end
  tests('pending') do
    @output = bin(path('pending'))
    test('output') { @output.include?('* pending') }
    test('status') { $?.exitstatus == 0 }
  end
  tests('success') do
    @output = bin(path('success'))
    test('output') { @output.include?('+ success') }
    test('status') { $?.exitstatus == 0 }
  end
end
