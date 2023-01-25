# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'a snapshot matcher' do
  let(:metadata) { { file_path: 'spec/example_spec.rb' } }
  let(:config) { {} }

  describe '.initialize' do
    describe 'initializing the serializer' do
      context 'when a custom serializer class is configured' do
        # rubocop:disable Lint/ConstantDefinitionInBlock
        # rubocop:disable RSpec/LeakyConstantDeclaration
        class TestSerializer
          def dump(object)
            object.to_s
          end
        end
        # rubocop:enable Lint/ConstantDefinitionInBlock
        # rubocop:enable RSpec/LeakyConstantDeclaration

        context 'and the serializer class is in the local config' do
          let(:config) { { snapshot_serializer: TestSerializer } }

          before do
            allow(TestSerializer).to receive(:new)
          end

          it 'initializes the configured class' do
            build_matcher

            expect(TestSerializer).to have_received(:new)
          end
        end

        context 'and the serializer class is in the RSpec global config' do
          before do
            allow(RSpec.configuration).to(
              receive(:snapshot_serializer).and_return(TestSerializer)
            )
            allow(TestSerializer).to receive(:new)
          end

          it 'initializes the configured class' do
            build_matcher

            expect(TestSerializer).to have_received(:new)
          end
        end
      end

      context 'when a custom serializer class is not configured' do
        before do
          allow(RSpec::Snapshot::DefaultSerializer).to receive(:new)
        end

        it 'initializes the default serializer class' do
          build_matcher

          expect(RSpec::Snapshot::DefaultSerializer).to have_received(:new)
        end
      end
    end
  end

  describe '.description' do
    subject { build_matcher }

    let(:expected) { 'snapshot value' }

    before do
      subject.instance_variable_set(:@expected, expected)
    end

    it 'returns a description of the expected value' do
      expect(subject.description).to(
        eq("to match a snapshot containing: \"#{expected}\"")
      )
    end
  end

  describe '.diffable?' do
    subject { build_matcher }

    it 'returns true' do
      expect(subject.diffable?).to be(true)
    end
  end

  describe '.failure_message' do
    subject { build_matcher }

    let(:expected) { 'snapshot value' }
    let(:actual) { 'some other value' }

    before do
      subject.instance_variable_set(:@expected, expected)
      subject.instance_variable_set(:@actual, actual)
    end

    it 'returns a failure message including the actual and expected' do
      expect(subject.failure_message).to(
        eq("\nexpected: #{expected}\n     got: #{actual}\n")
      )
    end
  end

  describe '.failure_message_when_negated' do
    subject { build_matcher }

    let(:expected) { 'snapshot value' }

    before do
      subject.instance_variable_set(:@expected, expected)
      subject.instance_variable_set(:@actual, expected)
    end

    it 'returns a failure message including the actual and expected' do
      expect(subject.failure_message_when_negated).to(
        eq("\nexpected: #{expected} not to match #{expected}\n")
      )
    end
  end
end
