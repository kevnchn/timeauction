class AuctionsController < ApplicationController

  before_filter :authenticate_user!, :except => [:index, :show]
  # before_filter :check_creator, :only => [:edit, :update, :destroy]
  before_filter :check_submitted, :only => [:edit, :update, :destroy]

  def index
    @auctions = Auction.where(:submitted => true).where("start <= ?", Time.now.utc).order("created_at DESC")
  end

  def show
    @auction = Auction.find(params[:id])
    @fb_url = Rails.env.production? ? request.original_url : "http://www.google.com"
    params_to_send = {
      :access_token => ENV['BITLY_TOKEN'],
      :longUrl => @fb_url
    }
    results = JSON.parse(RestClient.get "https://api-ssl.bitly.com/v3/shorten", { :params => params_to_send })
    @short_url = results["data"]["url"]
  end

  def user_auctions
    @participated_auctions = current_user.rewards.order("created_at DESC").map{ |reward| reward.auction }.uniq
    @saved_auctions = Auction.where(:submitted => false).where(:user_id => current_user.id).order("created_at DESC")
    @submitted_auctions = Auction.not_approved.where(:submitted => true).where(:user_id => current_user.id).order("created_at DESC")
    @approved_auctions = Auction.where(:approved => true).where(:user_id => current_user.id).order("created_at DESC")
  end

  def new
    @auction = Auction.new
    @auction.rewards.build
  end

  def create
    @auction = Auction.new(auction_params)
    @auction.user_id = current_user.id
    if params[:submit]
      @auction.submitted = true
      if @auction.save
        flash[:notice] = "#{@auction.title} has been successfully submitted."
        redirect_to auction_path(@auction)
      else
        flash[:alert] = "Please make sure all fields are filled in correctly :)"
        render "new"
      end
    else
      if @auction.save(:validate => false)
        flash[:notice] = "Your auction has been successfully saved."
        redirect_to edit_auction_path(@auction)
      else
        flash[:alert] = "Woah! Something happened..."
        render "new"
      end
    end
  end

  def edit
    @auction = Auction.find(params[:id])
    @auction.rewards.build
  end

  def update
    @auction = Auction.find(params[:id])
    @auction.assign_attributes(auction_params)
    if params[:submit]
      @auction.submitted = true
      if @auction.save
        flash[:notice] = "#{@auction.title} has been successfully submitted."
        redirect_to auction_path(@auction)
      else
        flash[:alert] = "Please make sure all fields are filled in correctly :)"
        render "edit"
      end
    else
      if @auction.save(:validate => false)
        flash[:notice] = "Your auction has been successfully saved."
        redirect_to edit_auction_path(@auction)
      else
        flash[:alert] = "Woah! Something happened..."
        render "new"
      end
    end
  end

  def destroy
    auction = Auction.find(params[:id]).destroy
    flash[:notice] = "#{auction.title} has been deleted."
    redirect_to auctions_path
  end

  private 

  def auction_params
    params.require(:auction).permit(
      :title,
      :approved,
      :short_description,
      :description,
      :about,
      :limitations,
      :target,
      :start,
      :end,
      :volunteer_end_date,
      :user_id,
      :banner,
      :image,
      :submitted,
      :_destroy,
      rewards_attributes: [
        :id,
        :title,
        :description,
        :amount,
        :max,
        :auction_id,
        :limit_bidders,
        :_destroy
      ]
    )
  end

  def check_creator
    auction = Auction.find(params[:id])
    if auction.user != current_user
      flash[:alert] = "You are not authorized to edit this auction."
      redirect_to auction_path(auction) || root_path
    end
  end

  def check_submitted
    auction = Auction.find(params[:id])
    if auction.submitted
      contact_link = view_context.mail_to "dstwen@gmail.com", "contact us", :encode => "hex"
      flash[:alert] = "An auction cannot be edited once submitted. Please #{contact_link} if you have any concerns.".html_safe
      redirect_to auction_path(auction) || root_path
    end
  end
end