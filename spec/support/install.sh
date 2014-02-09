cp -R /mnt/rpush /rpush
gem install --no-ri --no-rdoc rails
cd /tmp
export HOME=/
export RAILS_NAME=rpush_`date +"%Y%m%d%H%M%S"`
rails new $RAILS_NAME -BJTS -d mysql
cd $RAILS_NAME
for gem in sdoc coffee-rails uglifier sass-rails jquery-rails jbuilder turbolinks
do
  sed -i.bak -e "s/^gem '$gem'/\# gem '$gem'/g" Gemfile
done
echo 'gem "rpush", path: "/rpush"' >> Gemfile
bundle
/etc/init.d mysql start
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
EOF
rails runner create_app.rb
export RPUSH_GCM_HOST=`IP=$(/sbin/ip route | awk '/default/ { print $3 }')`
rpush development
