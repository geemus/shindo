module Shindo
  class Tests

    private

    def display_description_stack
      Formatador.indent do
        @description_stack.length.times do
          Formatador.display_line(@description_stack.pop)
        end
      end
    end

    def display_description(description)
      unless @described
        Thread.current[:formatador].display(@description_stack.first)
        print ' '
        @described = true
      end
    end

    def display_error(error)
      Formatador.display_lines(['', Thread.current[:file]])
      display_description_stack
      Formatador.display_line("[red]#{error.message} (#{error.class})[/]")
      unless error.backtrace.empty?
        Formatador.indent do
          Formatador.display_lines(error.backtrace.map {|line| "[red]#{line}[/]"})
        end
      end
    end

    def display_failure(description)
      Thread.current[:totals][:failed] += 1
      Formatador.display_lines(['', Thread.current[:file]])
      display_description_stack
      Formatador.display_line("[red]- #{description}[/]")
    end

    def display_pending(description)
      Thread.current[:totals][:pending] += 1
      print Formatador.parse("[yellow]#[/]")
    end

    def display_success(description)
      Thread.current[:totals][:succeeded] += 1
      print Formatador.parse("[green]+[/]")
    end

    def raises?(expectation, &block)
      value = begin
        instance_eval(&block)
      rescue => error
        error
      end
      [value, value.is_a?(expectation)]
    end

    def returns?(expectation, &block)
      [value = instance_eval(&block), value == expectation]
    end

  end
end
