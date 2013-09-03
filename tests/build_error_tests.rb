def given_something
  raise 'ERROR!'
end

Shindo.tests('Shindo build errors', ['build_error']) do
  tests('another').returns(true) do
    true
  end

  given_something do
    tests('success').returns(true) do
      true
    end
  end
end

