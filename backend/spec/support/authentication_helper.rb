# spec/support/authentication_helper.rb

module AuthenticationHelper
    def authentication_headers_for(user)
      post user_session_path, params: { email: user.email, password: user.password }
      {
        'uid' => response.headers['uid'],
        'client' => response.headers['client'],
        'access-token' => response.headers['access-token']
      }
    end
  end
  