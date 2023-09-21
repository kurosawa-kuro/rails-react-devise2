# rails-react-devise2/backend/spec/requests/auth/sessions_spec.rb
require 'rails_helper'

RSpec.describe "Auth", type: :request do
  let(:user_attributes) { attributes_for(:user) }

  describe "POST /auth" do
    let(:registration_params) do
      user_attributes.merge(
        password_confirmation: user_attributes[:password],
        confirm_success_url: 'http://example.com'
      )
    end

    context "with valid parameters" do
      # Testing user creation
      it "creates a new user" do
        expect {
          post user_registration_path, params: registration_params
        }.to change(User, :count).by(1)

        expect(response).to have_http_status(200)
      end

      # Testing token generation on registration
      it "returns a new authentication token" do
        post user_registration_path, params: registration_params

        expect(response.headers['access-token']).not_to be_nil
        expect(response.headers['client']).not_to be_nil
      end
    end
  end

  describe "POST /auth/sign_in" do
    let!(:user) { create(:user) }
    let(:valid_credentials) { { email: user.email, password: user.password } }
    let(:invalid_credentials) { { email: user.email, password: 'wrong_password' } }

    context "with valid login credentials" do
      # Testing successful login
      it "signs in the user" do
        post user_session_path, params: valid_credentials
        expect(response).to have_http_status(200)
      end

      # Testing token generation on login
      it "returns authentication headers" do
        post user_session_path, params: valid_credentials

        expect(response.headers['access-token']).not_to be_nil
        expect(response.headers['client']).not_to be_nil
      end
    end

    context "with invalid login credentials" do
      # Testing failed login attempt
      it "does not sign in the user" do
        post user_session_path, params: invalid_credentials
        expect(response).to have_http_status(:unauthorized)
      end

      # Testing no token generation on failed login
      it "does not return authentication headers" do
        post user_session_path, params: invalid_credentials

        expect(response.headers['access-token']).to be_nil
        expect(response.headers['client']).to be_nil
      end
    end
  end

  describe "DELETE /auth/sign_out" do
    let!(:user) { create(:user) }

    context "with valid headers" do
      # Testing successful logout
      it "signs out the user" do
        headers = authentication_headers_for(user)

        delete destroy_user_session_path, headers: headers
        expect(response).to have_http_status(200)

        # Confirming that the old token is no longer valid
        get auth_validate_token_path, headers: headers
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with invalid headers" do
      let(:invalid_headers) { { 'uid' => 'invalid', 'client' => 'invalid', 'access-token' => 'invalid' } }

      # Testing that a user with invalid headers cannot log out
      it "does not sign out the user" do
        delete destroy_user_session_path, headers: invalid_headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
