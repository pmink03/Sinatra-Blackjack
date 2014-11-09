require 'rubygems'
require 'sinatra'
require "sinatra/reloader" if development?

#set :sessions, true
use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'mink'

helpers do

  def update_score(who)
    if(who == 'player')
      hand = session[:player_hand]
    else
      hand = session[:dealer_hand]
    end

    face_values = hand.map{|card| card[1] }
    total = 0
      face_values.each do |val|
        if val == "ace"
          total += 11
        else
          total += (val.to_i == 0 ? 10 : val.to_i)
        end
      end

      #correct for Aces
      face_values.select{|val| val == "ace"}.count.times do
        break if total <= 21
        total -= 10
      end

      if(who == 'player')
        session[:player_score] = total
    else
      session[:dealer_score] = total
    end
  end


  def cards_html(hand)
    hand_string = ''
    hand.each do |card|
      hand_string += "<img src='/images/cards/" + card[0] + "_" + card[1] + ".jpg' class='playingcards'>"
    end
    hand_string
  end


  def setup(keep_playing = false)  

    if(keep_playing)
      temp_name = session[:player_name]
      temp_cash = session[:player_cash]
      temp_bet = session[:player_bet]
      #session.clear
      session[:player_name] = temp_name
      session[:player_cash] = temp_cash
      session[:player_bet] = temp_bet
    else
      session[:player_bet] = 1
      session[:player_cash] = 500
      session[:player_name] = ""
    end

    session[:player_score] = 0
    session[:dealer_score] = 0
    session[:player_hand] = [] 
    session[:dealer_hand] = []
    session[:deck] = []
    @show_hit_or_stay_buttons = true
    @dealers_turn = false
    create_deck
  end

  def create_deck
    suits = ['hearts', 'diamonds', 'clubs', 'spades']
    values = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'jack', 'queen', 'king', 'ace']
    session[:deck] = suits.product(values).shuffle!
  end

end

get '/' do
  if session[:player_name]
    erb :game
  else
    setup
    erb :set_name_form
  end
end

post '/set_name' do
  if params[:player_name] == ''
    @error = "You must supply a name."
    halt erb :set_name_form
  end
  session[:player_name] = params[:player_name]
  erb :bet_form
end

get '/set_name_form' do 
  erb :set_name_form
end

get '/bet_form' do
  erb :bet_form
end

post '/bet' do
  unless params[:bet_amount].to_i > 0
    @error = "Sorry, this table has a $1 minimum."
    halt erb :bet_form
  end

  if params[:bet_amount].to_i > session[:player_cash].to_i
    @error = "C'mon man! You cannot bet more money than you have!"
    halt erb :bet_form
  end
  session[:player_bet] = params[:bet_amount].to_i
  redirect '/init_game'
end

post '/keep_playing' do
  setup(true)
  redirect '/bet_form'
end

get '/new_game' do
  session.clear
  redirect '/'
end


get '/init_game' do
  session[:player_hand] << session[:deck].pop
  session[:dealer_hand] << session[:deck].pop
  session[:player_hand] << session[:deck].pop
  session[:dealer_hand] << session[:deck].pop
  update_score('player')
  update_score('dealer')
  if session[:player_score] == 21 && session[:dealer_score] == 21
    @error = "We have a tie!"
    @smiley = "Deleket-Smileys-26.png"
    @show_hit_or_stay_buttons = false
    @show_keep_playing_button = true
  elsif session[:player_score] == 21
    @error = "You have Blackjack!"
    @show_hit_or_stay_buttons = false
    session[:player_cash] += session[:player_bet]
    @show_keep_playing_button = true
  elsif session[:dealer_score] == 21
    @error = "Dealer has Blackjack!"
    @show_hit_or_stay_buttons = false
    session[:player_cash] -= session[:player_bet]
    @show_keep_playing_button = true
  else
    @show_hit_or_stay_buttons = true
  end
  erb :game
end

get '/game' do
  @dealer_cards = dealer_cards_html
  erb :game
end

post '/game/dealer' do
  if session[:dealer_score] < 17 || session[:dealer_score] < session[:player_score]
    session[:dealer_hand] << session[:deck].pop
    update_score('dealer')
  end

  if session[:dealer_score] > 21
    @error = "Dealer busted!"
    session[:player_cash] += session[:player_bet]
    @show_keep_playing_button = true
    @dealers_turn = false
  elsif session[:dealer_score] > session[:player_score] && session[:dealer_score] > 16
    @error = "Dealer wins!"
    @show_hit_or_stay_buttons = false
    session[:player_cash] -= session[:player_bet]
    @show_keep_playing_button = true
  elsif session[:player_score] == session[:dealer_score]
    @error = "We have a tie!"
    @show_hit_or_stay_buttons = false
    @show_keep_playing_button = true
    @dealers_turn = false
  else
    @dealers_turn = true
  end

  erb :game
end


post '/game/player/hit' do
  session[:player_hand] << session[:deck].pop
  update_score('player')
  if session[:player_score] > 21
    @error = "Sorry, you busted!" 
    @show_hit_or_stay_buttons = false
    session[:player_cash] -= session[:player_bet]
    if session[:player_cash] > 0
      @show_keep_playing_button = true
    end
  else
    @show_hit_or_stay_buttons = true
  end
  erb :game
end 

post '/game/player/stay' do
  #dealers turn
  if session[:dealer_score] > session[:player_score]
    @error = "Dealer wins!"
    session[:player_cash] -= session[:player_bet]
    @show_keep_playing_button = true
  elsif session[:dealer_score] > 16 && session[:dealer_score] == session[:player_score]
    @error = "We have a tie!"
    @show_hit_or_stay_buttons = false
    @show_keep_playing_button = true
    @dealers_turn = false
  else
    @show_hit_or_stay_buttons = false
    @dealers_turn = true
  end
  erb :game
end