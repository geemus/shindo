Shindo.tests('basics') do
  tests('exception') do
    before do
      @output = bin(path('exception'))
    end
    test('output') { @output.include?('- exception') }
    test('status') { $?.exitstatus == 1 }
  end
  tests('failure') do
    before do
      @output = bin(path('failure'))
    end
    test('output') { @output.include?('- failure') }
    test('status') { $?.exitstatus == 1 }
  end
  tests('pending') do
    before do
      @output = bin(path('pending'))
    end
    test('output') { @output.include?('* pending') }
    test('status') { $?.exitstatus == 0 }
  end
  tests('success') do
    before do
      @output = bin(path('success'))
    end
    test('output') { @output.include?('+ success') }
    test('status') { $?.exitstatus == 0 }
  end
end
