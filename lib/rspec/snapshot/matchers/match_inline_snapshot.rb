# frozen_string_literal: true

require 'rspec/snapshot/default_serializer'
require_relative '../../../../lib/ast/file_rewriter'
require_relative '../../../../lib/ast/snapshot_upserter'

module RSpec
  module Snapshot
    module Matchers
      # RSpec matcher for inline snapshot testing
      class MatchInlineSnapshot
        attr_reader :actual, :expected

        def initialize(metadata, expected, config)
          @metadata = metadata
          @expected = expected
          @config = config

          @serializer = serializer_class.new
          @rewriter = AST::FileRewriter.new(AST::SnapshotUpserter)#.rewrite(file_name, 18527, 'tickles') 
        end

        def matches?(actual)
          @actual = serialize(actual)

          write_snapshot

          # @actual == @expected
          @actual == @expected&.strip
        end

        # do we need this?
        # === is the method called when matching an argument
        alias === matches?
        alias match matches?

        def description
          "to match a snapshot containing: \"#{@expected}\""
        end

        def diffable?
          true
        end

        def failure_message
          "\nexpected: #{@expected}\n     got: #{@actual}\n"
        end

        def failure_message_when_negated
          "\nexpected: #{@expected} not to match #{@actual}\n"
        end

        private def serializer_class
          if @config[:snapshot_serializer]
            @config[:snapshot_serializer]
          elsif RSpec.configuration.snapshot_serializer
            RSpec.configuration.snapshot_serializer
          else
            DefaultSerializer
          end
        end

        private def serialize(value)
          return value if value.is_a?(String)

          @serializer.dump(value)
        end

        private def indent(text, level)
          text.rjust(level + text.length, ' ')
        end

        private def write_snapshot
          return unless should_write?

          lines = File.read(test_file).split("\n")
          example_line = lines[example_location]

          maybe_loc = lines[...example_location].sum { |l| l.length + 1 } + lines[example_location].index('match_inline_snapshot')

          indentation_spaces = example_line.length - example_line.lstrip.length


          # require 'pry'; binding.pry

          new_lines = [
            'match_inline_snapshot(',
            indent('<<~SNAPSHOT', indentation_spaces + 2),
              @actual.split("\n").map { |l| indent(l, indentation_spaces + 4) }.join("\n"),
              indent('SNAPSHOT', indentation_spaces + 2),
              indent(')', indentation_spaces)
          ]

          File.write(test_file, @rewriter.rewrite(test_file, maybe_loc, new_lines.join("\n")))

          RSpec.configuration.reporter.message(
            "Inline Snapshot written: #{example_location}"
          )
        end

        private def test_file
          @metadata[:file_path]
        end

        private def example_location
          @metadata[:location].gsub("#{test_file}:", '').to_i
        end

        private def snapshot_missing?
          @expected.nil?
        end

        private def should_write?
          update_snapshots? || snapshot_missing?
        end

        private def update_snapshots?
          ENV.fetch('UPDATE_SNAPSHOTS', false)
        end
      end
    end
  end
end
