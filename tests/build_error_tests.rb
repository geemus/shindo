def given_something
  raise 'ERROR!'
end

Shindo.tests('Fog::Rackspace::LoadBalancers | load_balancer_get_stats', ['rackspace']) do
  tests('another').returns(true) do
    true
  end

  given_something do
    tests('success').returns(true) do
      true
    end
  end
end

