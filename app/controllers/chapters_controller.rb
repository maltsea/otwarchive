class ChaptersController < ApplicationController
  include WorksHelper
  include ChapterLoading
  include ChapterForm
  include ChapterDisplay
  include ChapterOwnership
  include ChapterOrdering
  include ChapterDeletion

  # only registered users and NOT admin should be able to create new chapters
  before_action :users_only, except: [:index, :show, :destroy, :confirm_delete]
  before_action :check_user_status, only: [:new, :create, :update, :update_positions]
  before_action :check_user_not_suspended, only: [:edit, :remove_user_creatorship, :confirm_delete, :destroy]
  before_action :load_work
  # only authors of a work should be able to edit its chapters
  before_action :check_ownership, except: [:index, :show]
  before_action :check_visibility, only: [:show]
  before_action :load_chapter, only: [:show, :edit, :remove_user_creatorship, :update, :preview, :post, :confirm_delete, :destroy]

  cache_sweeper :feed_sweeper
end

  def post_chapter
    @work.update_attribute(:posted, true) unless @work.posted
    flash[:notice] = ts("Chapter has been posted!")
  end

  private

  def chapter_params
    params.require(:chapter).permit(:title, :position, :wip_length, :"published_at(3i)",
                                    :"published_at(2i)", :"published_at(1i)", :summary,
                                    :notes, :endnotes, :content, :published_at,
                                    author_attributes: [:byline, ids: [], coauthors: []])
  end
end
