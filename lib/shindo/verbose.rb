module Shindo
  class Tests

    private

    def display_description(description)
      Thread.current[:formatador].display_line(description)
    end

    def display_error(error)
      Thread.current[:formatador].display_line("[red]#{error.message} (#{error.class})[/]")
      unless error.backtrace.empty?
        Thread.current[:formatador].indent do
          Thread.current[:formatador].display_lines(error.backtrace.map {|line| "[red]#{line}[/]"})
        end
      end
    end

    def display_failure(description)
      Thread.current[:totals][:failed] += 1
      Thread.current[:formatador].display_line("[red]- #{description}[/]")
    end

    def display_pending(description)
      Thread.current[:totals][:pending] += 1
      Thread.current[:formatador].display_line("[yellow]# #{description}[/]")
    end

    def display_success(description)
      Thread.current[:totals][:succeeded] += 1
      Thread.current[:formatador].display_line("[green]+ #{description}[/]")
    end

    def raises?(expectation, &block)
      @gestalt = Gestalt.new({'formatador' => Thread.current[:formatador]})
      [value = @gestalt.run(&block), value.is_a?(expectation)]
    end

    def returns?(expectation, &block)
      @gestalt = Gestalt.new({'formatador' => Thread.current[:formatador]})
      [value = @gestalt.run(&block), value == expectation]
    end

  end
end
