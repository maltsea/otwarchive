module WorkImporting
  extend ActiveSupport::Concern

  def import
    @urls = params[:urls].split
    if @urls.empty?
      flash.now[:error] = ts("Did you want to enter a URL?")
      render(:new_import) && return
    end

    @language_id = params[:language_id]
    if @language_id.empty?
      flash.now[:error] = ts("Language cannot be blank.")
      render(:new_import) && return
    end

    importing_for_others = params[:importing_for_others] != "false" && params[:importing_for_others]

    if (params[:external_author_name].present? || params[:external_author_email].present?) && !importing_for_others
      flash.now[:error] = ts('You have entered an external author name or e-mail address but did not select "Import for others." Please select the "Import for others" option or remove the external author information to continue.')
      render(:new_import) && return
    end

    if importing_for_others && !current_user.archivist
      flash.now[:error] = ts("You may not import stories by other users unless you are an approved archivist.")
      render(:new_import) && return
    end

    if params[:import_multiple] == "works" && ((!current_user.archivist && @urls.length > ArchiveConfig.IMPORT_MAX_WORKS) || @urls.length > ArchiveConfig.IMPORT_MAX_WORKS_BY_ARCHIVIST)
      flash.now[:error] = ts("You cannot import more than %{max} works at a time.", max: current_user.archivist ? ArchiveConfig.IMPORT_MAX_WORKS_BY_ARCHIVIST : ArchiveConfig.IMPORT_MAX_WORKS)
      render(:new_import) && return
    elsif params[:import_multiple] == "chapters" && @urls.length > ArchiveConfig.IMPORT_MAX_CHAPTERS
      flash.now[:error] = ts("You cannot import more than %{max} chapters at a time.", max: ArchiveConfig.IMPORT_MAX_CHAPTERS)
      render(:new_import) && return
    end

    options = build_options(params)
    options[:ip_address] = request.remote_ip

    if params[:import_multiple] == "works" && @urls.length > 1
      import_multiple(@urls, options)
    else
      import_single(@urls, options)
    end
  end

  def import_single(urls, options)
    storyparser = StoryParser.new

    begin
      @work = if urls.size == 1
                storyparser.download_and_parse_story(urls.first, options)
              else
                storyparser.download_and_parse_chapters_into_story(urls, options)
              end
    rescue Timeout::Error
      flash.now[:error] = ts("Import has timed out. This may be due to connectivity problems with the source site. Please try again in a few minutes, or check Known Issues to see if there are import problems with this site.")
      render(:new_import) && return
    rescue StoryParser::Error => e
      flash.now[:error] = ts("We couldn't successfully import that work, sorry: %{message}", message: e.message)
      render(:new_import) && return
    end

    unless @work && @work.save
      flash.now[:error] = ts("We were only partially able to import this work and couldn't save it. Please review below!")
      @chapter = @work.chapters.first
      @series = current_user.series.distinct
      render(:new) && return
    end

    send_external_invites([@work])
    @chapter = @work.first_chapter if @work
    if @work.posted
      redirect_to(work_path(@work)) && return
    else
      redirect_to(preview_work_path(@work)) && return
    end
  end

  def import_multiple(urls, options)
    storyparser = StoryParser.new
    @works, failed_urls, errors = storyparser.import_from_urls(urls, options)

    unless failed_urls.empty?
      error_msgs = 0.upto(failed_urls.length).map { |index| "<dt>#{failed_urls[index]}</dt><dd>#{errors[index]}</dd>" }
        .join("\n")
      flash.now[:error] = "<h3>#{ts('Failed Imports')}</h3><dl>#{error_msgs}</dl>".html_safe
    end

    render(:new_import) && return if @works.empty?

    flash[:notice] = ts("Importing completed successfully for the following works! (But please check the results over carefully!)")
    send_external_invites(@works)
  end

  def send_external_invites(works)
    return unless params[:importing_for_others]

    @external_authors = works.collect(&:external_authors).flatten.uniq
    return if @external_authors.empty?

    @external_authors.each do |external_author|
      external_author.find_or_invite(current_user)
    end

    message = " " + ts("We have notified the author(s) you imported works for. If any were missed, you can also add co-authors manually.")
    flash[:notice] ? flash[:notice] += message : flash[:notice] = message
  end
end
