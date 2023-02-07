# frozen_string_literal: true

require 'spec_helper'

describe RSpec::Snapshot::Matchers::MatchInlineSnapshot do
  def build_matcher
    described_class.new(
      metadata: metadata,
      expected: expected,
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
    let(:serializer) { instance_double(RSpec::Snapshot::DefaultSerializer) }

    before do
      allow(RSpec::Snapshot::DefaultSerializer).to(
        receive(:new).and_return(serializer)
      )
      allow(serializer).to receive(:dump)

      class_spy(InlineSnapshotWriter).as_stubbed_const
      class_double(File, expand_path: '/baz/ham').as_stubbed_const
    end

    describe 'matching the value' do
      it 'should pass when the values match'

      it 'should pass when stripping the expected matches the actual'

      it 'should not pass when the values do not match'
    end

    describe 'writing the snapshot' do
      let(:call_stack) { ['/baz/ham:42'] }

      it 'writes the serialized value'

      it 'writes the snapshot if explicitly enabled' do
        allow(ENV).to receive(:[]).with('UPDATE_SNAPSHOTS').and_return('true')
        matcher = build_matcher

        matcher.matches?('foo')

        expect(InlineSnapshotWriter).to have_received(:write)
      end

      it 'writes the snapshot if the snapshot is missing' do
        matcher = build_matcher
        matcher.instance_variable_set(:@expected, nil)

        matcher.matches?('foo')

        expect(InlineSnapshotWriter).to have_received(:write)
      end

      it 'does not write the snapshot if already present and not explicitly enabled' do
        expect(InlineSnapshotWriter).not_to have_received(:write)
      end
    end
  end
end
