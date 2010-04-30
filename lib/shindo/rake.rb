module Shindo

  class Rake

    def initialize
      desc "Run shindo tests"
      task :tests do
        system 'shindo'
      end
    end

  end

end
