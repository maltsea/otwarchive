module CollectionForm
  extend ActiveSupport::Concern

  def new
    @hide_dashboard = true
    @collection = Collection.new
    @collection.parent_name = @collection_parent.name if params[:collection_id] && (@collection_parent = Collection.find_by(name: params[:collection_id]))
  end

  def edit
  end

  def create
    @hide_dashboard = true
    @collection = Collection.new(collection_params)

    # add the owner
    owner_attributes = []
    (params[:owner_pseuds] || [current_user.default_pseud_id]).each do |pseud_id|
      pseud = Pseud.find(pseud_id)
      owner_attributes << { pseud: pseud, participant_role: CollectionParticipant::OWNER } if pseud
    end
    @collection.collection_participants.build(owner_attributes)

    if @collection.save
      flash[:notice] = ts("Collection was successfully created.")
      if params[:challenge_type].blank?
        redirect_to collection_path(@collection)
      elsif params[:challenge_type] == "PromptMeme"
        redirect_to new_collection_prompt_meme_path(@collection) and return
      elsif params[:challenge_type] == "GiftExchange"
        redirect_to new_collection_gift_exchange_path(@collection) and return
      end
    else
      @challenge_type = params[:challenge_type]
      render action: "new"
    end
  end

  def update
    if @collection.update(collection_params)
      flash[:notice] = ts("Collection was successfully updated.")
      if params[:challenge_type].blank?
        if @collection.challenge
          # trying to destroy an existing challenge
          flash[:error] = ts("Note: if you want to delete an existing challenge, please do so on the challenge page.")
        end
      elsif @collection.challenge
        if @collection.challenge.class.name != params[:challenge_type]
          flash[:error] = ts("Note: if you want to change the type of challenge, first please delete the existing challenge on the challenge page.")
        elsif params[:challenge_type] == "PromptMeme"
          redirect_to edit_collection_prompt_meme_path(@collection) and return
        elsif params[:challenge_type] == "GiftExchange"
          redirect_to edit_collection_gift_exchange_path(@collection) and return
        end
      elsif params[:challenge_type] == "PromptMeme"
        redirect_to new_collection_prompt_meme_path(@collection) and return
      elsif params[:challenge_type] == "GiftExchange"
        redirect_to new_collection_gift_exchange_path(@collection) and return
      end
      redirect_to collection_path(@collection)
    else
      render action: "edit"
    end
  end
end
