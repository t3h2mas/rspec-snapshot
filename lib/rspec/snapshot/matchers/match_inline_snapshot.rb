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
          @rewriter = AST::FileRewriter.new(AST::SnapshotUpserter)
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

          start_index = matcher_start_index(lines)

          indentation_level = indentation_spaces(example_line(lines))

          updated_source = update_matcher_source(indentation_level)

          File.write(test_file,
                     @rewriter.rewrite(test_file, start_index, updated_source))

          RSpec.configuration.reporter.message(
            "Inline Snapshot written: #{example_line_index + 1}"
          )
        end

        private def example_line(lines)
          lines[example_location]
        end

        private def matcher_start_index(lines)
          previous_lines = lines[..example_location - 1]
          matcher_line_start = previous_lines.sum { |l| l.length + 1 }
          matcher_start = lines[example_location].index('match_inline_snapshot')

          matcher_line_start + matcher_start
        end

        private def update_matcher_source(indentation_level)
          [
            'match_inline_snapshot(',
            indent('<<~SNAPSHOT', indentation_level + 2),
            actual_with_indent(indentation_level + 4),
            indent('SNAPSHOT', indentation_level + 2),
            indent(')', indentation_level)
          ].join("\n")
        end

        private def actual_with_indent(indentation_level)
          @actual.split("\n").map do |line|
            indent(line, indentation_level)
          end.join("\n")
        end

        private def indentation_spaces(line)
          line.length - line.lstrip.length
        end

        private def test_file
          @metadata[:file_path]
        end

        private def example_line_index
          @example_line_index ||= begin
            full_test_location = File.expand_path(test_file)
            # check the call stack to find the assertion line number
            location = caller.find do |path|
              path.split(':').first == full_test_location
            end

            line_no = location.split(':')[1].to_i

            line_no - 1
          end
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
