require 'spec_helper'

describe "bids" do
  subject { page }

  set(:creator) { FactoryGirl.create :user }
  set(:auction) { FactoryGirl.create :auction_with_rewards, :rewards_count => 2, :user => creator }
  set(:user) { FactoryGirl.create :user, :email => "johndoe@email.com" }

  before do
    auction.update_attributes(:target => 10)
  end

  context "not logged in" do
    it "opens signup modal", :js => true do
      visit auction_path(auction)
      find("body")
      all(".bid-button").first.click
      page.should have_selector('#signup-modal', visible: true)
    end
  end

  context "logged in" do
    before do
      login(user)
      visit auction_path(auction)
      page.find("body")
      sleep 1
    end

    it "opens bid modal", :js => true do
      all(".bid-button").first.click
      page.should have_selector('#bid-modal', visible: true)
    end

    context "within bid modal" do
      it "shows correct reward details", :js => true do
        all(".bid-button").first.click
        page.should have_content(auction.title, visible: true)
        page.should have_content(auction.rewards.first.title, visible: true)
        page.should have_content(auction.rewards.first.description, visible: true)
        page.should have_content("#{auction.rewards.first.amount} volunteer hours", visible: true)
      end

      it "shows correct user details without first or last name", :js => true do
        all(".bid-button").first.click
        page.should have_content(user.email, visible: true)
      end

      it "shows correct user details including first or last name if provided", :js => true do
        all(".bid-button").first.click
        page.should have_content(user.email, visible: true)
        page.should have_content(user.first_name, visible: true)
        page.should have_content(user.last_name, visible: true)
      end

      it "can place bid with first and last name", :js => true do
        all(".bid-button").first.click
        sleep 1
        expect do
          click_on "Commit"
          sleep 1
        end.to change(Bid, :count).by(1)
      end

      it "cannot place bid without first and last name", :js => true do
        user.update_attributes(:first_name => "", :last_name => "")
        all(".bid-button").first.click
        sleep 1
        expect do
          click_on "Commit"
          sleep 1
        end.to change(Bid, :count).by(0)
        page.should have_css(".error")
      end
    end

    # context "max bidders reached on reward", :js => true do
    #   it "cannot bid" do
    #     page.should_not have_content("No more left!")
    #     auction.rewards.first.update_attributes(:max => 1, :limit_bidders => true)
    #     sleep 1
    #     all(".bid-button").first.click
    #     sleep 1
    #     click_on "Commit"
    #     sleep 1
    #     page.should have_content("No more left!")
    #   end
    # end

    context "already bid on reward", :js => true do
      it "cannot bid" do
        all(".bid-button").first.click
        page.should_not have_content("You have already bid on this reward")
        sleep 1
        click_on "Commit"
        find("body")
        sleep 1
        all(".bid-button").first.click
        page.should have_content("You have already bid on this reward", visible: true)
      end
    end

    context "successful bid" do
      it "sends bid confirmation email to bidder after bidding", :js => true do
        all(".bid-button").first.click
        sleep 1
        click_on "Commit"
        sleep 1
        mail = ActionMailer::Base.deliveries.select{ |m| m.subject.include?("Thank you for bidding") }.first
        mail.to.should eq([user.email])
      end

      it "sends bid confirmation email to admin after bidding", :js => true do
        all(".bid-button").first.click
        sleep 1
        click_on "Commit"
        sleep 1
        mail = ActionMailer::Base.deliveries.select{ |m| m.subject.include?("bid on the reward") }.first
        mail.to.should eq(["team@timeauction.org"])
      end

      it "shows after-bid-modal", :js => true do
        all(".bid-button").first.click
        sleep 1
        click_on "Commit"
        sleep 1
        page.should have_content("Thank you for committing", visible: true)
      end

      it "does not show after-bid-modal after it's been seen once", :js => true do
        all(".bid-button").first.click
        sleep 1
        click_on "Commit"
        visit terms_and_conditions_path
        visit auction_path(auction)
        page.should_not have_content("Thank you for committing", visible: true)
      end
    end
  end

  context "using earned hours", :js => true do
    before do
      entry1 = HoursEntry.create(:amount => 10000, :user_id => user.id, :verified => true)
      entry2 = HoursEntry.create(:amount => 10000, :user_id => user.id, :verified => true)
      entry1.save(:validate => false)
      entry2.save(:validate => false)
      login(user)
      visit auction_path(auction)
      all(".bid-button").first.click
      sleep 8
    end

    it "shows checkbox" do
      page.should have_content("stored volunteer hours", visible: true)
    end

    it "uses earned hours" do
      find(".use-volunteer-hours-holder")
      find("#use-volunteer-hours").set(true)
      expect do
        click_on "Commit"
        sleep 1
      end.to change(HoursEntry, :count).by(1)
    end
  end
end
