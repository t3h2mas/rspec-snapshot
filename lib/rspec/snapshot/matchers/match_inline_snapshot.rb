# frozen_string_literal: true

require 'rspec/snapshot/default_serializer'
require_relative './matcher'
require_relative '../../../../lib/inline_snapshot_writer'

class YAInlineSnapshotWriter
  def initialize(test_file, call_stack)
    @test_file = test_file
    @call_stack = call_stack
  end

  def write(snapshot, force)
    return unless should_write? || force

    InlineSnapshotWriter.write(test_file, matcher_line_index, snapshot)

    RSpec.configuration.reporter.message(
      "Inline Snapshot written: #{matcher_line_index + 1}"
    )
  end

  private def snapshot_missing?
    @expected.nil?
  end

  private def should_write?
    snapshot_missing?
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
end

class InlineSnapshotReader
  def initialize(expected)
    @expected = expected
  end

  def read
    @expected&.strip
  end
end

module RSpec
  module Snapshot
    module Matchers
      # RSpec matcher for inline snapshot testing
      class MatchInlineSnapshot < Matcher
        attr_reader :actual, :expected

        def initialize(metadata:, expected:, call_stack:, config:)
          super(metadata, config)

          @expected = expected
          @call_stack = call_stack
        end

        def matches?(actual)
          @actual = serialize(actual)

          write_snapshot

          @actual == @expected&.strip
        end

        private def write_snapshot
          return unless should_write?

          InlineSnapshotWriter.write(test_file, matcher_line_index, @actual)

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
      end
    end
  end
end
