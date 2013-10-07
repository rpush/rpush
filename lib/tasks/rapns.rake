namespace :rapns do
  namespace :notifications do
    desc "Delete completed notifications older than number of days (DAYS > 0)"
    task clean: :environment do
      date = (ENV['DAYS'].blank? || ENV['DAYS'].to_i <= 0)  ? nil : Time.zone.now.end_of_day - (ENV['DAYS'].to_i).days
      count = 0
    
      if(date.nil?)
        puts "DAYS is required and must be greater than 0"
      else
        puts "BEG: Delete completed notifications before '#{date}'\n"
    
        deleted_count = Rapns::Notification.completed_and_older_than(date).delete_all
      
        puts "END: Deleted #{deleted_count} notifications"
      end
    end
  end
end