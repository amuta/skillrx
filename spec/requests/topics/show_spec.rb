require "rails_helper"

describe "Topics", type: :request do
  describe "GET /topics/:id" do
    let(:user) { create(:user) }
    let(:topic) { create(:topic) }

    before { sign_in(user) }

    it "renders a successful response" do
      get topic_path(topic)

      expect(response).to be_successful
    end

    context "with a document attached" do
      before do
        topic.documents.attach(Rails.root.join("test/fixtures/images/logo_ruby_for_good.png"))
      end

      it "displays a link to the document" do
        get topic_path(topic)

        expect(response.body).to include("logo_ruby_for_good.png")
      end
    end
  end
end
