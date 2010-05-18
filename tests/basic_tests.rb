Shindo.tests('basics') do

  returns(false)        { false }

  raises(StandardError) { raise StandardError.new }

  test('returns true')  { true }

end
