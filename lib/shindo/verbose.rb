module Shindo
  class Tests

    private

    def display_description(description)
      unless @inline
        Formatador.display_line(description)
      else
        Formatador.display(description)
        print ' '
      end
    end

    def display_error(error)
      Thread.current[:totals][:errored] += 1
      Formatador.display_line("[red]#{error.message} (#{error.class})[/]")
      unless error.backtrace.empty?
        Formatador.indent do
          Formatador.display_lines(error.backtrace.map {|line| "[red]#{line}[/]"})
        end
      end
    end

    def display_failure(description)
      Thread.current[:totals][:failed] += 1
      unless @inline
        Formatador.display_line("[red]- #{description}[/]")
      else
        print Formatador.parse("[red]- #{description}[/]\n")
      end
    end

    def display_pending(description)
      Thread.current[:totals][:pending] += 1
      unless @inline
        Formatador.display_line("[yellow]# #{description}[/]")
      else
        print Formatador.parse("[yellow]# #{description}[/]\n")
      end
    end

    def display_success(description)
      Thread.current[:totals][:succeeded] += 1
      unless @inline
        Formatador.display_line("[green]+ #{description}[/]")
      else
        print Formatador.parse("[green]+ #{description}[/]\n")
      end
    end

  end
end
