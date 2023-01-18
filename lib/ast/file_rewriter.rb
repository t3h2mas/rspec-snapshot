# frozen_string_literal: true

module AST
  class FileRewriter
    def initialize(processor_klass)
      @processor_klass = processor_klass
    end

    def rewrite(file_name, start_loc, val)
      source = source_buffer(file_name)
      rewriter = Parser::Source::TreeRewriter.new(source.buffer)
      processor = @processor_klass.new(rewriter, start_loc, val)
      source.ast.each_node { |n| processor.process(n) }
      rewriter.process
      # TODO: write this to a file
    end

    private def source_buffer(file_name)
      code = File.read(file_name)
      RuboCop::AST::ProcessedSource.new(code, 2.7)
    end
  end
end
