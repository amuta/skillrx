require "rails_helper"

RSpec.describe TextGenerator::Tags do
  subject { described_class.new(language) }

  let(:language) { create(:language) }

  it "generates empty text" do
    expect(subject.perform).to be_empty
  end

  context "when tagged topics exist" do
    let!(:topic) { create(:topic, :tagged, language:) }

    it "generates text with tags for topics" do
      expect(subject.perform).to eq(topic.current_tags_for_language(language.id).map(&:name).uniq.sort.join("\n"))
    end
  end

  context "when topic exists but archived" do
    let!(:topic) { create(:topic, :tagged, :archived, language:) }

    it "generates empty text" do
      expect(subject.perform).to be_empty
    end
  end

  context "when topic does not belong to language" do
    let(:other_language) { create(:language) }
    let!(:topic) { create(:topic, :tagged, language: other_language) }

    it "generates empty text" do
      expect(subject.perform).to be_empty
    end
  end
end
