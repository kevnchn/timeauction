def banner_root
  Rails.root + "app/assets/images/nicaragua.jpeg"
end

def image_root
  Rails.root + "app/assets/images/boshin.jpg"
end

def fill_in_initial_auction_fields
  fill_in :auction_title, :with => "The best auction"
  fill_in :auction_short_description, :with => "If you bid on this, you are smart"
  fill_in :auction_description, :with => "Some longer description..."
  fill_in :auction_about, :with => "This is what we're all about"
  fill_in :auction_start, :with => Time.now.strftime("%b %d, %Y (%a)")
  fill_in :auction_end, :with => (Time.now + 3.days).strftime("%b %d, %Y (%a)")
  fill_in :auction_volunteer_end_date, :with => (Time.now + 1.month).strftime("%b %d, %Y (%a)")
end

def fill_in_latter_auction_fields
  attach_file :auction_banner, banner_root
  attach_file :auction_image, image_root
  find(".add-a-reward-icon").click
  all(".auction_rewards_title").each_with_index do |title, i|
    title.find("input").set("Awesome reward #{i + 1}")
  end
  all(".auction_rewards_description").each_with_index do |description, i|
    description.find("textarea").set("Awesome reward description #{i + 1}")
  end
  all(".auction_rewards_amount").each_with_index do |reward_amount, i|
    reward_amount.find("input").set(20 * (i + 1))
  end
  fill_in :auction_target, :with => 50
end