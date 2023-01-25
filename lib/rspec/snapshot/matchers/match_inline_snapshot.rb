# frozen_string_literal: true

require 'rspec/snapshot/default_serializer'
require_relative '../../../../lib/inline_snapshot_writer'

module RSpec
  module Snapshot
    module Matchers
      # RSpec matcher for inline snapshot testing
      class MatchInlineSnapshot
        attr_reader :actual, :expected

        def initialize(metadata:, expected:, call_stack:, config:)
          @metadata = metadata
          @expected = expected
          @config = config
          @call_stack = call_stack

          @serializer = serializer_class.new
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

        private def write_snapshot
          return unless should_write?

          InlineSnapshotWriter.new(test_file, matcher_line_index, @actual).write

          RSpec.configuration.reporter.message(
            "Inline Snapshot written: #{matcher_line_index + 1}"
          )
        end

        private def test_file
          @metadata[:file_path]
        end

        private def matcher_line_index
          @matcher_line_index ||= begin
            full_test_location = File.expand_path(test_file)
            # check the call stack to find the assertion line number
            location = @call_stack.find do |path|
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
