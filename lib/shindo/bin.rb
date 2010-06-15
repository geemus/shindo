require File.join(File.dirname(__FILE__), '..', 'shindo')

@interrupt = lambda do
  formatador = Thread.current[:formatador] || Formatador
  unless Thread.main[:exit]
    formatador.display_line('Gracefully Exiting... (ctrl-c to force)')
    Thread.main[:exit] = true
  else
    formatador.display_line('Exiting...')
    Thread.exit
  end
end
Kernel.trap('INT', @interrupt)

helpers = Dir.glob(File.join(Dir.pwd, 'tests', '**', '*helper.rb')).sort_by {|helper| helper.count(File::SEPARATOR)}
tags = []
for argument in ARGV
  if argument.match(/^[\+\-]/)
    tags << argument
  else
    path = File.expand_path(argument)
    if File.directory?(path)
      tests ||= []
      tests |= Dir.glob(File.join(path, '**', '*tests.rb'))
    elsif File.exists?(path)
      tests ||= []
      tests << path
    else
      Formatador.display_line("[red][bold]#{argument}[/] [red]does not exist, please fix this path and try again.[/]")
      Kernel.exit(1)
    end
  end
end

# ARGV was empty or only contained tags
unless tests
  tests = Dir.glob(File.join('tests', '**', '*tests.rb'))
end

@started_at = Time.now
def run_in_thread(helpers, tests, thread_locals)
  shindo = Thread.new {
    for key, value in thread_locals
      Thread.current[key] = value
    end
    for file in helpers
      unless Thread.main[:exit]
        load(file)
      end
    end
    for file in tests
      unless Thread.main[:exit]
        load(file)
      end
    end
  }
  shindo.join
  if shindo[:reload]
    run_in_thread(helpers, tests, thread_locals)
  else
    @totals = shindo[:totals]
  end
end
run_in_thread(helpers, tests, @thread_locals.merge({:tags => tags}))

@totals   ||= { :failed => 0, :pending => 0, :succeeded => 0 }
@success  = @totals[:failed] == 0
lines = []
lines << "[red]#{@totals[:failed]} failed[/]," if @totals[:failed] > 0
lines << "[yellow]#{@totals[:pending]} pending[/]," if @totals[:pending] > 0
lines << "[green]#{@totals[:succeeded]} succeeded[/]"
lines = lines[0...-2].join(', ') << ' and ' << lines[-1] if lines.length > 3
lines << "in [bold]#{Time.now - @started_at}[/] seconds"
Formatador.display_line
Formatador.display_line(lines.join(' '))
Formatador.display_line

if @success
  Kernel.exit(0)
else
  Kernel.exit(1)
end
