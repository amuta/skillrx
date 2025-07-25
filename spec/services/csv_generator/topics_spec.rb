require "rails_helper"

RSpec.describe CsvGenerator::Topics do
  subject { described_class.new(language) }

  let(:language) { create(:language) }
  let(:header) { "TopicID,TopicName,TopicVolume,TopicIssue,TopicYear,TopicMonth,ContentProvider\n" }

  it "generates empty csv" do
    expect(subject.perform).to eq(header)
  end

  context "when topics exist" do
    let!(:topic) { create(:topic, language:) }
    let(:data) do
      header.tap do |csv|
        csv << "#{topic.id},#{topic.title},#{topic.published_at.year},#{topic.published_at.month},#{topic.published_at.year},#{topic.published_at.month},#{topic.provider.name}\n"
      end
    end

    it "generates csv with topics info" do
      expect(subject.perform).to eq(data)
    end
  end

  context "when topic exists but archived" do
    let!(:topic) { create(:topic, :archived, language:) }

    it "generates empty csv" do
      expect(subject.perform).to eq(header)
    end
  end

  context "when topic does not belong to language" do
    let(:other_language) { create(:language) }
    let!(:topic) { create(:topic, language: other_language) }

    it "generates empty csv" do
      expect(subject.perform).to eq(header)
    end
  end
end
