module Shindo
  class Tests

    private

    def display_description(description)
      Formatador.display_line(description)
    end

    def display_error(error)
      Formatador.display_line("[red]#{error.message} (#{error.class})[/]")
      unless error.backtrace.empty?
        Formatador.indent do
          Formatador.display_lines(error.backtrace.map {|line| "[red]#{line}[/]"})
        end
      end
    end

    def display_failure(description)
      Thread.current[:totals][:failed] += 1
      Formatador.display_line("[red]- #{description}[/]")
    end

    def display_pending(description)
      Thread.current[:totals][:pending] += 1
      Formatador.display_line("[yellow]# #{description}[/]")
    end

    def display_success(description)
      Thread.current[:totals][:succeeded] += 1
      Formatador.display_line("[green]+ #{description}[/]")
    end

  end
end
