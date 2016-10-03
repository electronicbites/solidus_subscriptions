require 'rails_helper'

RSpec.describe SolidusSubscriptions::Subscription, type: :model do
  it { is_expected.to have_many :installments }
  it { is_expected.to belong_to :user }
  it { is_expected.to have_one :line_item }
  it { is_expected.to validate_presence_of :user }

  it { is_expected.to accept_nested_attributes_for :line_item }

  describe '#cancel' do
    subject { subscription.cancel }

    let(:subscription) { create :subscription, :with_line_item }

    context 'the subscription can be canceled' do
      it 'is canceled' do
        subject
        expect(subscription.canceled?).to be_truthy
      end
    end

    context 'the subscription cannot be canceled' do
      before do
        allow(subscription).to receive(:can_be_canceled?).and_return(false)
      end

      it 'is pending cancelation' do
        subject
        expect(subscription.pending_cancellation?).to be_truthy
      end
    end
  end

  describe '#deactivate' do
    subject { subscription.deactivate }

    let(:traits) { [] }
    let(:subscription) do
      create :subscription, :with_line_item, line_item_traits: traits do |s|
        s.installments = build_list(:installment, 2)
      end
    end

    context 'the subscription can be deactivated' do
      let(:traits) do
        [{ max_installments: 1 }]
      end

      it 'is inactive' do
        subject
        expect(subscription.inactive?).to be_truthy
      end
    end

    context 'the subscription cannot be deactivated' do
      it { is_expected.to be_falsy }
    end
  end

  describe '#next_actionable_date' do
    before { Timecop.freeze(Date.parse("2016-10-05")) }
    after { Timecop.return }
    subject { subscription.next_actionable_date }

    context "when the subscription is active" do
      context "when there is no other subscription" do
        let(:subscription) { create(:subscription, :with_line_item, actionable_date: Date.current) }
        let(:expected_date) { Date.current + subscription.interval }
        it { is_expected.to eq expected_date }
      end

      context "when the other subscription has different units" do
        let(:expected_date) { Date.current + subscription.interval }
        let(:other_subscription) { create(:subscription, :with_line_item, user: subscription.user) }
        it { is_expected.to eq expected_date }
      end

      context "when both subscriptions are weekly" do
        context "when the existing subscription is in the future" do
          let(:expected_date) { Date.parse("2016-10-10") }

          let(:other_line_item) { create :subscription_line_item, interval_units: "week", interval_length: 1 }
          let!(:other_subscription) do
            create(:subscription, line_item: other_line_item, user: subscription.user, actionable_date: 5.days.from_now)
          end

          let(:line_item) { create :subscription_line_item, interval_units: "week", interval_length: 1 }
          let(:subscription) { create(:subscription, line_item: line_item, actionable_date: 1.day.from_now) }

          it { is_expected.to eq expected_date }
        end

        context "when the existing subscription is in the past" do
          let(:expected_date) { Date.parse("2016-10-11") }

          let(:other_line_item) { create :subscription_line_item, interval_units: "week", interval_length: 1 }
          let!(:other_subscription) do
            create(:subscription, line_item: other_line_item, user: subscription.user, actionable_date: 1.day.ago)
          end

          let(:line_item) { create :subscription_line_item, interval_units: "week", interval_length: 1 }
          let(:subscription) { create(:subscription, line_item: line_item, actionable_date: 3.days.from_now) }

          it { is_expected.to eq expected_date }
        end
      end

      context "when both subscriptions are monthly" do
        let(:expected_date) { Date.parse("2016-10-10") }
        let(:other_subscription) do
          create(:subscription, :with_line_item, user: subscription.user, actionable_date: 1.month.ago)
        end
        it { is_expected.to eq expected_date }
      end
    end

    context "when the subscription is not active" do
      let(:subscription) { build_stubbed :subscription, :with_line_item, state: :canceled }
      it { is_expected.to be_nil }
    end
  end

  describe '#advance_actionable_date' do
    subject { subscription.advance_actionable_date }

    let(:expected_date) { Date.current + subscription.interval }
    let(:subscription) do
      build(
        :subscription,
        :with_line_item,
        actionable_date: Date.current
      )
    end

    it { is_expected.to eq expected_date }

    it 'updates the subscription with the new actionable date' do
      subject
      expect(subscription.reload).to have_attributes(
        actionable_date: expected_date
      )
    end
  end

  describe ".actionable" do
    let!(:past_subscription) { create :subscription, actionable_date: 2.days.ago }
    let!(:future_subscription) { create :subscription, actionable_date: 1.month.from_now }
    let!(:inactive_subscription) { create :subscription, state: "inactive", actionable_date: 7.days.ago }
    let!(:canceled_subscription) { create :subscription, state: "canceled", actionable_date: 4.days.ago }

    subject { described_class.actionable }

    it "returns subscriptions that have an actionable date in the past" do
      expect(subject).to include past_subscription
    end

    it "does not include future subscriptions" do
      expect(subject).to_not include future_subscription
    end

    it "does not include inactive subscriptions" do
      expect(subject).to_not include inactive_subscription
    end

    it "does not include canceled subscriptions" do
      expect(subject).to_not include canceled_subscription
    end
  end

  describe '#line_item_builder' do
    subject { subscription.line_item_builder }

    let(:subscription) { create :subscription, :with_line_item }
    let(:line_item) { subscription.line_item }

    it { is_expected.to be_a SolidusSubscriptions::LineItemBuilder }
    it { is_expected.to have_attributes(subscription_line_item: line_item) }
  end
end
