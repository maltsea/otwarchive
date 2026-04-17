module ErrorHandling
  extend ActiveSupport::Concern

  included do
    rescue_from ActionController::InvalidAuthenticityToken, with: :display_auth_error

    rescue_from Pundit::NotAuthorizedError do
      admin_only_access_denied
    end

    rescue_from ActionController::UnknownFormat, with: :raise_not_found

    rescue_from Elastic::Transport::Transport::Errors::ServiceUnavailable do
      # Non-standard code to distinguish Elasticsearch errors from standard 503s.
      # We can't use 444 because nginx will close connections without sending
      # response headers.
      head 445
    end

    rescue_from Rack::Timeout::RequestTimeoutException, with: :raise_timeout
  end

  def display_auth_error
    respond_to do |format|
      format.html do
        redirect_to auth_error_path
      end
      format.any(:js, :json) do
        render json: {
          errors: {
            auth_error: "Your current session has expired and we can't authenticate your request. Try logging in again, refreshing the page, or <a href='https://en.wikipedia.org/wiki/Wikipedia:Bypass_your_cache'>clearing your cache</a> if you continue to experience problems.".html_safe
          }
        }, status: :unprocessable_entity
      end
    end
  end

  def raise_not_found
    redirect_to "/404"
  end

  def raise_timeout
    redirect_to timeout_error_path
  end
end
