# frozen_string_literal: true

require 'rubocop-ast'
require 'pry'

module AST
  class SnapshotUpserter < Parser::AST::Processor
    include RuboCop::AST::Traversal
    extend RuboCop::AST::NodePattern::Macros

    def_node_matcher :match_inline_snapshot, <<~PATTERN
      (send _ :match_inline_snapshot ...)
    PATTERN

    def initialize(rewriter, start_loc, val)
      @rewriter = rewriter
      @start_loc = start_loc
      @val = val
    end

    def on_send(node)
      match_inline_snapshot(node) do 
        next unless node.loc.expression.begin_pos == @start_loc

        @rewriter.replace(node.loc.expression, @val)
        # p node.loc
      end
    end
  end
end