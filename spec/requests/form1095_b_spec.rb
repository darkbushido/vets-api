require 'rails_helper'

RSpec.describe Form1095B, type: :request do
  subject { create :form1095_b }
  let(:user) { build(:user, :loa3, icn: subject.veteran_icn) }
  let(:invalid_user) { build(:user, :loa1, icn: subject.veteran_icn) }
  let(:user_without_form) { build(:user, :loa3, icn: "7832473474389") }
  let(:past_form) {create(:form1095_b, tax_year: 2010)}

  describe "GET /download for valid user" do
    before do
      sign_in_as(user)
    end

    it "returns http success" do
      get "/v0/form1095_bs/download/2021"
      expect(response).to have_http_status(:success)
    end

    it "returns a PDF form" do
      get "/v0/form1095_bs/download/2021"
      expect(response.content_type).to eq('application/pdf')
    end

    it "throws 404 when form not found" do
      get "/v0/form1095_bs/download/2018"
      expect(response.status).to eq(404)
    end

    # it "throws 500 error if template form for year doesn't exist" do
    #   get "/v0/form1095_bs/download/2010"
    #   puts 'response.status, should be 500'
    #   puts response.status
    #   puts past_form.to_json
    #   # past_form.get_pdf
    #   expect(response.status).to eq(500)
    # end
  end

  describe "GET /download for invalid user" do
    before do
      sign_in_as(invalid_user)
    end

    it "returns http 403" do
      get "/v0/form1095_bs/download/2021"
      puts 'response.status'
      puts response.status
      expect(response.status).to eq(403)
    end
  end

  describe "GET /last_updated" do
    before do
      sign_in_as(user)
    end

    it "returns http success" do
      get "/v0/form1095_bs/last_updated/2021"
      expect(response).to have_http_status(:success)
    end

    it "returns last updated object" do
      get "/v0/form1095_bs/last_updated/2021"
      expect(response.body).to eq({ last_updated: subject.updated_at }.to_json)
    end
  end

  describe "GET /last_updated for invalid user" do
    before do
      sign_in_as(invalid_user)
    end

    it "returns http 403" do
      get "/v0/form1095_bs/last_updated/2021"
      puts 'response.status'
      puts response.status
      expect(response.status).to eq(403)
    end
  end

  describe "GET /last_updated when not logged in" do
    it "returns http 401" do
      get "/v0/form1095_bs/last_updated/2021"
      puts 'response.status'
      puts response.status
      expect(response.status).to eq(401)
    end
  end
end
