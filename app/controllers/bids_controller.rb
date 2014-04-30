class BidsController < ApplicationController
  def bid
    @auction = Auction.find(params[:auction_id])
    @reward = Reward.find(params[:reward_id])
    @hours_entry = HoursEntry.new
    @bid = Bid.new
  end

  def create
    respond_to do |format|
      begin
        reward = Reward.find(params[:reward_id])
        auction = reward.auction

        unless params[:first_name].blank? && params[:last_name].blank?
          current_user.first_name = params[:first_name] if params[:first_name]
          current_user.last_name = params[:last_name] if params[:last_name]
          current_user.save
        end

        reward.users << current_user
        current_user.bids.last.update_attributes(bid_params)

        begin
          create_hours_entry(reward) if params[:use_stored_hours] == "true"
          BidMailer.successful_bid(reward, current_user).deliver
          BidMailer.notify_admin(reward, current_user, "Successful").deliver
          flash[:notice] = "Thank you! You have successfully committed to the auction: #{auction.title}"
          format.json { render :json => { :url => auction_path(auction) } }
        rescue
          format.json { render :json => { :url => auction_path(auction) } }
          BidMailer.notify_admin(reward, current_user, "Error sending user email - but still successful").deliver
        end
      rescue
        flash[:alert] = "Sorry, something went wrong and your bid didn't go through. Please try again!"
        format.json { render :json => { :url => auction_path(auction), :fail => true } }
      end
    end
  end

  private

  def bid_params
    params.require(:bid).permit(
      :application,
      :message
    )
  end

  def create_hours_entry(reward)
    hours_entry = HoursEntry.new(
      :amount => reward.amount * -1,
      :user_id => current_user.id,
      :bid_id => current_user.bids.last.id
    )
    hours_entry.save(:validate => false)
  end
end