# frozen_string_literal: true

require 'fileutils'
require 'rspec/snapshot/default_serializer'

module RSpec
  module Snapshot
    module Matchers
      # RSpec matcher for snapshot testing
      class Matcher
        attr_reader :actual, :expected

        def initialize(metadata, config)
          @metadata = metadata
          @config = config
          @serializer = serializer_class.new
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

        private def update_snapshots?
          ENV['UPDATE_SNAPSHOTS'] # rubocop:todo Style/FetchEnvVar
        end

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
      end
    end
  end
end
