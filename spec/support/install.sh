set -e
cp -R /mnt/rpush /rpush
cd /tmp
export HOME=/
export RAILS_NAME=rpush_`date +"%Y%m%d%H%M%S"`
gem install --no-ri --no-rdoc rails bundler
rails new $RAILS_NAME -BJTS -d mysql
cd $RAILS_NAME
for gem in sdoc coffee-rails uglifier sass-rails jquery-rails jbuilder turbolinks
do
  sed -i.bak -e "s/^[ \t]*gem '$gem'/\# gem '$gem'/g" Gemfile
done
echo 'gem "rpush", path: "/rpush"' >> Gemfile
bundle
/etc/init.d/mysql start
mysqladmin create `echo $RAILS_NAME`_development
rails g rpush
rake db:migrate
cat > create_app.rb <<EOF
app = Rpush::Gcm::App.new
app.name = "android_app"
app.auth_key = "123"
app.save!

n = Rpush::Gcm::Notification.new
n.app = app
n.registration_ids = ["abc"]
n.data = {:message => "hi mom!"}
n.save!
puts n.id
EOF
export NOTIFICATION_ID=`rails runner create_app.rb`
export RPUSH_GCM_HOST=http://`/sbin/ip route | awk '/default/ { print $3 }'`
rpush development
cat > check_notification_status.rb <<EOF
n = Rpush::Gcm::Notification.find(ENV["NOTIFICATION_ID"])

while true do
  if n.failed
    puts "FAILED"
    break
  elsif n.delivered
    puts "DELIVERED"
    break
  else
    STDOUT.write(".")
    STDOUT.flush
  end

  sleep 0.2
  n.reload
end
EOF
rails runner check_notification_status.rb
