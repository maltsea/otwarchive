module LayoutHelpers
  extend ActiveSupport::Concern

  included do
    helper_method :process_title, :get_page_title
    before_action :load_admin_banner
    before_action :load_tos_popup
    before_action :hide_banner
  end

  TITLE_ABBREVIATIONS = {
    "Faq" => "FAQ",
    "Tos" => "TOS",
    "Dmca" => "DMCA"
  }.freeze

  def process_title(string)
    title = string.to_s.humanize.titleize
    TITLE_ABBREVIATIONS.reduce(title) do |memo, (source, replacement)|
      memo.sub(source, replacement)
    end
  end

  def load_admin_banner
    if Rails.env.development?
      @admin_banner = AdminBanner.where(active: true).last
    else
      # http://stackoverflow.com/questions/12891790/will-returning-a-nil-value-from-a-block-passed-to-rails-cache-fetch-clear-it
      # Basically we need to store a nil separately.
      @admin_banner = Rails.cache.fetch("v1/admin_banner") do
        banner = AdminBanner.where(active: true).last
        banner.nil? ? "" : banner
      end
      @admin_banner = nil if @admin_banner == ""
    end
  end

  def load_tos_popup
    # Integers only, YYYY-MM-DD format of date Board approved TOS
    @current_tos_version = 2024_11_19 # rubocop:disable Style/NumericLiterals
  end

  def hide_banner
    session[:hide_banner] = true if params[:hide_banner]
  end

  def get_page_title(fandom, author, title, options = {})
    if options[:truncate]
      fandom = fandom.gsub(/^(.{15}[\w.]*)(.*)/) { Regexp.last_match(2).empty? ? Regexp.last_match(1) : Regexp.last_match(1) + "..." }
      author = author.gsub(/^(.{15}[\w.]*)(.*)/) { Regexp.last_match(2).empty? ? Regexp.last_match(1) : Regexp.last_match(1) + "..." }
      title = title.gsub(/^(.{15}[\w.]*)(.*)/) { Regexp.last_match(2).empty? ? Regexp.last_match(1) : Regexp.last_match(1) + "..." }
    end

    if logged_in? && current_user.preference.try(:work_title_format).present?
      page_title = current_user.preference.work_title_format.dup
      page_title.gsub!(/FANDOM/, fandom)
      page_title.gsub!(/AUTHOR/, author)
      page_title.gsub!(/TITLE/, title)
    else
      page_title = "#{title} - #{author} - #{fandom}"
    end

    page_title += " [#{ArchiveConfig.APP_NAME}]" unless options[:omit_archive_name]
    page_title.html_safe
  end
end
