# frozen_string_literal: true

require 'spec_helper'

class TestSerializer
  def self.dump(val)
    val.to_s.gsub('[', '(').gsub(']', ')')
  end
end

describe RSpec::Snapshot::Matchers::MatchInlineSnapshot do
  def build_matcher(expected_val = expected)
    described_class.new(
      metadata: metadata,
      expected: expected_val,
      config: config,
      call_stack: call_stack
    )
  end

  let(:metadata) { { file_path: 'spec/example_spec.rb' } }
  let(:config) { {} }
  let(:expected) { 'foobar' }
  let(:call_stack) { [] }

  it_behaves_like 'a snapshot matcher'

  describe '.matches?' do
    before do
      allow(RSpec::Snapshot::DefaultSerializer).to(
        receive(:new).and_return(TestSerializer)
      )

      class_spy(InlineSnapshotWriter).as_stubbed_const
      class_double(File, expand_path: '/baz/ham').as_stubbed_const
    end

    describe 'matching the value' do
      let(:expected) { 'ham and eggs' }

      it 'passes when the values match' do
        matcher = build_matcher

        expect(matcher.matches?('ham and eggs')).to be(true)
      end

      it 'passes when stripping the expected matches the actual' do
        matcher = build_matcher('ham and eggs   ')

        expect(matcher.matches?('ham and eggs')).to be(true)
      end

      it 'does not pass when the values do not match' do
        matcher = build_matcher

        expect(matcher.matches?('ham & eggs')).to be(false)
      end
    end

    describe 'writing the snapshot' do
      let(:call_stack) { ['/baz/ham:43'] }

      it 'writes the snapshot if explicitly enabled' do
        allow(ENV).to receive(:[]).with('UPDATE_SNAPSHOTS').and_return('true')
        matcher = build_matcher

        matcher.matches?([1])

        expect(InlineSnapshotWriter).to have_received(:write).with(
          metadata[:file_path], 42, '(1)'
        )
      end

      it 'writes the snapshot if the snapshot is missing' do
        matcher = build_matcher
        matcher.instance_variable_set(:@expected, nil)

        matcher.matches?([1])

        expect(InlineSnapshotWriter).to have_received(:write).with(
          metadata[:file_path], 42, '(1)'
        )
      end

      it 'does not write the snapshot if already present and not explicitly enabled' do
        expect(InlineSnapshotWriter).not_to have_received(:write)
      end
    end
  end
end
