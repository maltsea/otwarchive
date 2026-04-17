module WorkForm
  extend ActiveSupport::Concern

  def new
    @hide_dashboard = true
    @unposted = current_user.unposted_work

    if @collection&.closed? && !@collection&.user_is_maintainer?(current_user)
      flash[:error] = t(".closed_collection", collection_title: @collection.title)
      redirect_to collection_path(@collection) and return
    end

    if params[:load_unposted] && @unposted
      @work = @unposted
      @chapter = @work.first_chapter
    else
      @work = Work.new
      @chapter = @work.chapters.build
    end

    @work.challenge_assignments << @challenge_assignment if params[:assignment_id] && (@challenge_assignment = ChallengeAssignment.find(params[:assignment_id])) && @challenge_assignment.offering_user == current_user

    @work.challenge_claims << @challenge_claim if params[:claim_id] && (@challenge_claim = ChallengeClaim.find(params[:claim_id])) && User.find(@challenge_claim.claiming_user_id) == current_user

    @work.add_to_collection(@collection) if @collection

    @work.set_challenge_info
    @work.set_challenge_claim_info
    set_work_form_fields

    if params[:import]
      @page_subtitle = ts("Import New Work")
      render(:new_import)
    elsif @work.persisted?
      render(:edit)
    else
      render(:new)
    end
  end

  def create
    @work = Work.new(work_params)

    @chapter = @work.first_chapter
    @chapter.attributes = work_params[:chapter_attributes] if work_params[:chapter_attributes]
    @work.ip_address = request.remote_ip

    @work.set_challenge_info
    @work.set_challenge_claim_info
    set_work_form_fields

    if work_cannot_be_saved?
      render :new
    else
      @work.posted = @chapter.posted = true if params[:post_button]
      @work.set_revised_at_by_chapter(@chapter)

      render :new and return unless @work.save

      if @work.posted
        flash[:notice] = t(".posted_notice")
        in_moderated_collection
        redirect_to work_path(@work)
      else
        flash[:notice] = t(".draft_notice_html", scheduled_for_deletion_bold: helpers.tag.strong(t(".scheduled_for_deletion")), deletion_date: view_context.date_in_zone(@work.created_at + 29.days))
        in_moderated_collection
        redirect_to preview_work_path(@work)
      end
    end
  end

  def edit
    @hide_dashboard = true
    if @work.number_of_chapters > 1
      @chapters = @work.chapters_in_order(include_content: false,
                                          include_drafts: true)
    end
    set_work_form_fields
  end

  def update
    @work.preview_mode = !!(params[:preview_button] || params[:edit_button])
    @work.attributes = work_params
    @chapter.attributes = work_params[:chapter_attributes] if work_params[:chapter_attributes]
    @work.ip_address = request.remote_ip
    @work.set_word_count(@work.preview_mode)

    @work.set_challenge_info
    @work.set_challenge_claim_info
    set_work_form_fields

    if params[:edit_button] || work_cannot_be_saved?
      render :edit
    elsif params[:preview_button]
      flash[:notice] = t(".unposted_notice") unless @work.posted?

      in_moderated_collection
      @preview_mode = true
      render :preview
    else
      @work.posted = @chapter.posted = true if params[:post_button]
      @work.set_revised_at_by_chapter(@chapter)
      posted_changed = @work.posted_changed?

      if @chapter.save && @work.save
        flash[:notice] = ts("Work was successfully #{posted_changed ? 'posted' : 'updated'}.")
        flash[:notice] << ts(" It should appear in work listings within the next few minutes.") if posted_changed
        in_moderated_collection
        redirect_to work_path(@work)
      else
        @chapter.errors.full_messages.each { |err| @work.errors.add(:base, err) }
        render :edit
      end
    end
  end

  def preview
    @preview_mode = true
  end

  private

  def work_cannot_be_saved?
    !(@work.errors.empty? && @work.valid?)
  end
end
