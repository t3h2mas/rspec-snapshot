# frozen_string_literal: true

require 'rspec/snapshot/matchers/match_snapshot'
require 'rspec/snapshot/matchers/match_inline_snapshot'

module RSpec
  module Snapshot
    # rubocop:disable Style/Documentation
    module Matchers
      def match_snapshot(snapshot_name, config = {})
        MatchSnapshot.new(RSpec.current_example.metadata,
                          snapshot_name,
                          config)
      end

      alias snapshot match_snapshot

      def match_inline_snapshot(expected = nil, config = {})
        MatchInlineSnapshot.new(meta_data: RSpec.current_example.metadata,
                                expected: expected,
                                config: config,
                                call_stack: caller)
      end
    end
    # rubocop:enable Style/Documentation
  end
end

RSpec.configure do |config|
  config.include RSpec::Snapshot::Matchers
end
