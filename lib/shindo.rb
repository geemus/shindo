require 'rubygems'
require 'annals'
require 'formatador'

module Shindo

  def self.tests(header = nil, &block)
    STDOUT.sync = true
    Shindo::Tests.new(header, &block)
  end

  class Tests

    attr_accessor :backtrace

    def initialize(header, tags = [], &block)
      @afters     = []
      @annals     = Annals.new
      @befores    = []
      @description_stack = []
      @formatador = Formatador.new
      @success    = true
      @tag_stack  = []
      Thread.current[:reload] = false;
      Thread.current[:tags] ||= []
      @if_tagged      = Thread.current[:tags].
                          select {|tag| tag.match(/^\+/)}.
                          map {|tag| tag[1..-1]}
      @unless_tagged  = Thread.current[:tags].
                          select {|tag| tag.match(/^\-/)}.
                          map {|tag| tag[1..-1]}
      @formatador.display_line('')
      tests(header, tags, &block)
      @formatador.display_line('')
      if @success
        Thread.current[:success] = true
      else
        Thread.current[:success] = false
      end
    end

    def after(&block)
      @afters[-1].push(block)
    end

    def before(&block)
      @befores[-1].push(block)
    end

    def full_description
      "#{@description_stack.compact.join(' ')}#{full_tags}"
    end

    def full_tags
      unless @tag_stack.flatten.empty?
        " [#{@tag_stack.flatten.join(', ')}]"
      end
    end

    def prompt(&block)
      @formatador.display("#{@formatador.indentation}Action? [c,i,q,r,t,#,?]? ")
      choice = STDIN.gets.strip
      @formatador.display_line("")
      case choice
      when 'c'
        return
      when 'i'
        @formatador.display_line('Starting interactive session...')
        if @irb.nil?
          require 'irb'
          ARGV.clear # Avoid passing args to IRB
          IRB.setup(nil)
          @irb = IRB::Irb.new(nil)
          IRB.conf[:MAIN_CONTEXT] = @irb.context
          IRB.conf[:PROMPT][:TREST] = {}
        end
        for key, value in IRB.conf[:PROMPT][:SIMPLE]
          IRB.conf[:PROMPT][:TREST][key] = "#{@formatador.indentation}#{value}"
        end
        @irb.context.prompt_mode = :TREST
        @irb.context.workspace = IRB::WorkSpace.new(block.binding)
        begin
          @irb.eval_input
        rescue SystemExit
        end
      when 'q'
        Thread.current[:success] = false
        Thread.exit
      when 'r'
        @formatador.display_line("Reloading...")
        Thread.current[:reload] = true
        Thread.exit
      when 't'
        @formatador.indent {
          if @annals.lines.empty?
            @formatador.display_line('no backtrace available')
          else
            index = 1
            for line in @annals.lines
              @formatador.display_line("#{' ' * (2 - index.to_s.length)}#{index}  #{line}")
              index += 1
            end
          end
        }
        @formatador.display_line('')
      when '?'
        @formatador.display_line('c - ignore this error and continue')
        @formatador.display_line('i - interactive mode')
        @formatador.display_line('q - quit Shindo')
        @formatador.display_line('r - reload and run the tests again')
        @formatador.display_line('t - display backtrace')
        @formatador.display_line('# - enter a number of a backtrace line to see its context')
        @formatador.display_line('? - display help')
      when /\d/
        index = choice.to_i - 1
        if @annals.lines[index]
          @formatador.indent do
            @formatador.display_line("#{@annals.lines[index]}: ")
            @formatador.indent do
              @formatador.display("\n")
              current_line = @annals.buffer[index]
              File.open(current_line[:file], 'r') do |file|
                data = file.readlines
                current = current_line[:line]
                min     = [0, current - (@annals.max / 2)].max
                max     = [current + (@annals.max / 2), data.length].min
                min.upto(current - 1) do |line|
                  @formatador.display_line("#{line}  #{data[line].rstrip}")
                end
                yellow_line("#{current}  #{data[current].rstrip}")
                (current + 1).upto(max - 1) do |line|
                  @formatador.display_line("#{line}  #{data[line].rstrip}")
                end
              end
              @formatador.display_line('')
            end
          end
        else
          @formatador.display_line("#{choice} is not a valid backtrace line, please try again.", :foreground_red)
        end
      else
        @formatador.display_line("#{choice} is not a valid choice, please try again.", :foreground_red)
      end
      @formatador.display_line("- #{full_description}", :foreground_red)
      prompt(&block)
    end

    def tests(description, tags = [], &block)
      @tag_stack.push([*tags])
      @befores.push([])
      @afters.push([])

      @formatador.display_line(description || 'Shindo.tests')
      if block_given?
        @formatador.indent { instance_eval(&block) }
      end

      @afters.pop
      @befores.pop
      @tag_stack.pop
    end

    def test(description, tags = [], &block)
      @description_stack.push(description)
      @tag_stack.push([*tags])

      # if the test includes tags and discludes ^tags, evaluate it
      if (@if_tagged.empty? || !(@if_tagged & @tag_stack.flatten).empty?) &&
          (@unless_tagged.empty? || (@unless_tagged & @tag_stack.flatten).empty?)
        if block_given?
          for before in @befores.flatten.compact
            before.call
          end

          @annals.start
          begin
            success = instance_eval(&block)
            @annals.stop
          rescue => error
            success = false
            file, line, method = error.backtrace.first.split(':')
            if method
              method << "in #{method[4...-1]} " # get method from "in `foo'"
            else
              method = ''
            end
            method << "! #{error.message} (#{error.class})"
            @annals.stop
            @annals.unshift(:file => file, :line => line.to_i, :method => method)
          end
          @success = @success && success
          if success
            @formatador.display_line("+ #{full_description}", :foreground_green)
          else
            @formatador.display_line("- #{full_description}", :foreground_red)
            if STDOUT.tty?
              prompt(&block)
            end
          end

          for after in @afters.flatten.compact
            after.call
          end
        else
          @formatador.display_line("* #{full_description}", :foreground_yellow)
        end
      else
        @formatador.display_line("_ #{full_description}")
      end

      @tag_stack.pop
      @description_stack.pop
    end

  end

end
