#encoding: utf-8
require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'pony'
require 'sqlite3'

def get_db
	db = SQLite3::Database.new 'barbershop.db'
	db.results_as_hash = true
	return db	
end

configure do
	db = get_db
	db.execute 'CREATE  TABLE IF NOT EXISTS
		"Users"
		(
			"id" INTEGER PRIMARY KEY  AUTOINCREMENT  UNIQUE,
			"username" TEXT,
			"phone" TEXT,
			"datestamp" TEXT,
			"barber" TEXT,
			"color" TEXT
		)'
	db.execute 'CREATE  TABLE IF NOT EXISTS
		"Barbers"
		(
			"id" INTEGER PRIMARY KEY  AUTOINCREMENT  UNIQUE,
			"barber" TEXT UNIQUE
		)'
	barbers = ['Walter White', 'Jessie Pinkman', 'Gus Fring', 'Mike Ehrmantra']
	barbers.each do |barber|
		db.execute 'INSERT OR IGNORE INTO Barbers ( barber ) VALUES ( ? )', barber
	end

	# db.execute 'INSERT OR IGNORE INTO Barbers ( barber ) VALUES ( ? )', ['Walter White']
end	

# before do
# 	db = get_db
# 	@barbers = db.execute 'SELECT * FROM Barbers'
# end	

get '/' do
	erb "Здравствуйте! Добро пожаловать на сайт парикмахерской \"Burber Shop\". Для записи перейдите по <a href=\"/visit\">ссылке</a>."
end

get '/visit' do
	erb :visit
end

post '/visit' do
	@client_name = params[:client_name]
	@client_phone = params[:client_phone]
	@client_date = params[:client_date]
	@barber = params[:barber]
	@color = params[:color]
	
	hh = { :client_name => "Введите имя", 
		   :client_phone => "Введите телефон",
		   :client_date => "Выберите дату и время" }

#	hh.each do |key,value|
#		if params[key] == ''
#			@error = hh[key]
#			return erb :visit
#		end
#	end

	@error = hh.select {|key,_| params[key] == ""}.values.join(", ")

	if @error != ''
		return erb :visit
	end
	
	db = get_db
	db.execute 'INSERT INTO
		Users
		(
			username,
			phone,
			datestamp,
			barber,
			color
		)
		VALUES
		( ?, ?, ?, ? , ? )', [@client_name, @client_phone, @client_date, @barber, @color]

	erb "Спасибо! #{@client_name.capitalize}, мы будем ждать вас #{@client_date}"
end

get '/contacts' do
	erb :contacts
end

post '/contacts' do
	@client_email = params[:client_email]
	@client_text = params[:client_text]

	hh = { :client_email => "Введите Ваш адрес e-mail", 
		   :client_text => "Введите текст сообщения" }

	@error = hh.select {|key,_| params[key] == ""}.values.join(", ")

	if @error != ''
		return erb :contacts
	end
	
    Pony.mail({
	  	:to => 'MAIL@gmail.com',
	  	:from => @client_email,
	  	:subject => "Question from #{@client_email}",
	  	:body => @client_text,
	  	:via => :smtp,
	  	:via_options => {
	    	:address              => 'smtp.gmail.com',
	    	:port                 => '587',
	    	:enable_starttls_auto => true,
	    	:user_name            => 'LOGIN',
	    	:password             => 'PASSWORD',
	    	:authentication       => :plain, # :plain, :login, :cram_md5, no auth by default
	    	:domain               => "localhost.localdomain" # the HELO domain provided by the client to the server
	  	}
	})

	f = File.open "./public/contacts.txt", "a"
	f.write "E-Mail: #{@client_email}, Text: #{@client_text}<br />\n"
	f.close
	erb "Спасибо! Мы напишем вам ответ на адрес #{@client_email}"
end

get '/about' do
	erb :about
end

get '/message' do
	erb :message
end

get '/admin' do
	erb :admin
end

post '/admin' do
	@login = params[:login]
	@password = params[:password]

	if @login == "admin" && @password == "secret"
		@title = "User data:"
		@message = File.read("./public/users.txt",  :encoding => "utf-8")
		@title2 = "User contacts:"
		@message2 = File.read("./public/contacts.txt",  :encoding => "utf-8")
		erb :message
	else
		@error = "Wrong login or password!"
		erb :admin 
	end
	
end

get '/showusers' do
	db = get_db
	@results = db.execute 'SELECT * FROM Users ORDER BY Datestamp'
	erb :showusers
end