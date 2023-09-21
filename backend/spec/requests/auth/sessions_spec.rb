# sessions_spec.rb

require 'rails_helper'

RSpec.describe "Auth", type: :request do
  let(:user_attributes) { attributes_for(:user) }

  describe "POST /auth" do
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

  describe "POST /auth/sign_in" do
    let!(:user) { create(:user) }
    let(:valid_login_params) { { email: user.email, password: user.password } }

    context "with valid login parameters" do
      it "signs in the user" do
        post user_session_path, params: valid_login_params
        expect(response).to have_http_status(200)
      end

      it "returns authentication headers" do
        post user_session_path, params: valid_login_params

        expect(response.headers['access-token']).not_to be_nil
        expect(response.headers['client']).not_to be_nil
      end
    end

    context "with invalid login parameters" do
      let(:invalid_login_params) { { email: user.email, password: 'wrong_password' } }

      it "does not sign in the user" do
        post user_session_path, params: invalid_login_params
        expect(response).to have_http_status(:unauthorized)
      end

      it "does not return authentication headers" do
        post user_session_path, params: invalid_login_params

        expect(response.headers['access-token']).to be_nil
        expect(response.headers['client']).to be_nil
      end
    end
  end

  describe "DELETE /auth/sign_out" do
    let!(:user) { create(:user) }
    let(:headers) do
      post user_session_path, params: { email: user.email, password: user.password }
      {
        'uid' => response.headers['uid'],
        'client' => response.headers['client'],
        'access-token' => response.headers['access-token']
      }
    end

    context "with valid headers" do
      it "signs out the user" do
        delete destroy_user_session_path, headers: headers
        expect(response).to have_http_status(200)

        # Devise Token Authの場合、一度サインアウトすると、以前の認証ヘッダーは無効になります
        # したがって、以下のリクエストは失敗するはずです。
        # ここでは仮に`auth_validate_token`を叩くこととしますが、テスト対象のAPIに合わせて適切なエンドポイントを指定してください。
        get auth_validate_token_path, headers: headers
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with invalid headers" do
      let(:invalid_headers) { { 'uid' => 'invalid', 'client' => 'invalid', 'access-token' => 'invalid' } }
    
      it "does not sign out the user" do
        delete destroy_user_session_path, headers: invalid_headers
        expect(response).to have_http_status(:not_found) # ここを修正
      end
    end
  end
end
