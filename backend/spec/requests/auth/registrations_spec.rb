require 'rails_helper'

RSpec.describe "Auth::Registrations", type: :request do
  describe "POST /auth" do
    let(:user_attributes) { attributes_for(:user) }
    let(:valid_params) do
      user_attributes.merge(
        password_confirmation: user_attributes[:password],
        confirm_success_url: 'http://example.com'
      )
    end

    context "with valid parameters" do
      it "creates a new user" do
        expect {
          post user_registration_path, params: valid_params
        }.to change(User, :count).by(1)

        expect(response).to have_http_status(200)
      end

      it "returns a new authentication token" do
        post user_registration_path, params: valid_params

        expect(response.headers['access-token']).not_to be_nil
        expect(response.headers['client']).not_to be_nil
      end
    end
  end
end
