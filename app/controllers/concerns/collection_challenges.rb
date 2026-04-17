module CollectionChallenges
  extend ActiveSupport::Concern

  # Lazy fix to prevent passing unsafe values to eval via challenge_type
  # In both CollectionsController#create and CollectionsController#update there are a vulnerable usages of eval
  # For now just make sure the values passed to it are safe
  def validate_challenge_type
    return render status: :bad_request, text: "invalid challenge_type" if params[:challenge_type] and !["", "GiftExchange", "PromptMeme"].include?(params[:challenge_type])
  end

  # display challenges that are currently taking signups
  def list_challenges
    @page_subtitle = "Open Challenges"
    @hide_dashboard = true

    @challenge_collections = (CollectionSearchForm.new(challenge_type: "GiftExchange", signup_open: true, sort_column: "signups_close_at", page: 1, per_page: 15).search_results.to_a +
                             CollectionSearchForm.new(challenge_type: "PromptMeme", signup_open: true, sort_column: "signups_close_at", page: 1, per_page: 15).search_results.to_a)
  end

  def list_ge_challenges
    @page_subtitle = "Open Gift Exchange Challenges"
    @challenge_collections = CollectionSearchForm.new(challenge_type: "GiftExchange", signup_open: true, sort_column: "signups_close_at", page: 1, per_page: 15).search_results
  end

  def list_pm_challenges
    @page_subtitle = "Open Prompt Meme Challenges"
    @challenge_collections = CollectionSearchForm.new(challenge_type: "PromptMeme", signup_open: true, sort_column: "signups_close_at", page: 1, per_page: 15).search_results
  end
end
