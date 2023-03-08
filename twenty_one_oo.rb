module MessageFormatable
  private

  def prompt(message)
    puts "=> #{message}"
  end

  def joinor(array, delimiter = ', ', word = 'or')
    case array.size
    when 0 then ''
    when 1 then array.first.to_s
    when 2 then "#{array.first} #{word} #{array.last}"
    else
      array[0..-2].join(delimiter) + "#{delimiter}#{word} #{array.last}"
    end
  end
end

module Inputable
  include MessageFormatable

  REGEXP_STRICT_POS_INTEGER = /\A0*[1-9]+([0-9])*\z/
  REGEXP_POS_INTEGER = /\A([0-9])+\z/

  private

  def possible_choices(list, str)
    possible_list = []
    list.each do |elt|
      possible_list << elt if elt.match(/\A#{Regexp.quote(str)}/)
    end
    possible_list
  end

  def input_formatted
    gets.chomp.downcase.strip
  end

  def input_yes_no(message)
    message = message.strip
    answer = ''

    loop do
      prompt "#{message} (y/n)"
      answer = input_formatted
      break if ['y', 'n', 'yes', 'no'].include?(answer)
      prompt "Sorry, must be y or n"
    end
    answer[0]
  end

  def input_regexp_condition(regexp, msg)
    loop do
      prompt(msg)
      str = gets.chomp.strip

      return str if str.match(regexp)
      prompt("Sorry, invalid input.")
    end
  end

  def input_positive_int(msg)
    input_regexp_condition(REGEXP_POS_INTEGER, msg).to_i
  end

  def input_strict_positive_int(msg)
    input_regexp_condition(REGEXP_STRICT_POS_INTEGER, msg).to_i
  end

  def input_choice(arr, choice_msg = "Please choose",
                   display_choices: true, downcase_input: true)

    choice_msg = "#{choice_msg.strip} #{joinor(arr)}" if display_choices

    loop do
      prompt(choice_msg)
      str = downcase_input ? input_formatted : gets.chomp.strip
      return str if arr.include?(str)

      list_possibles = possible_choices(arr, str)
      return list_possibles.first if list_possibles.size == 1
      display_error_input_choice(arr.size, list_possibles)
    end
  end

  def display_error_input_choice(nb_of_choices, list_possibles)
    case list_possibles.size
    when 0, nb_of_choices then prompt("Sorry, invalid choice.")
    else prompt("Do you mean #{joinor(list_possibles)}?")
    end
  end
end

class Participant
  include MessageFormatable

  attr_reader :hand

  def initialize
    @hand = []
  end

  def <<(card)
    @hand << card
  end

  def busted?
    total > Game::HAND_VALUE_LIMIT
  end

  def total
    total_int = @hand.map(&:value).sum

    if @hand.any?(&:ace?)
      nb_of_aces = @hand.select(&:ace?).size

      nb_of_aces.times do
        break unless total_int > Game::HAND_VALUE_LIMIT
        total_int -= 10
      end
    end

    total_int
  end
end

class Player < Participant
  def display_hand
    prompt "You have a #{joinor(hand, ', a ', 'and a')}"
    prompt "Your hand value is #{total}"
    puts
  end
end

class Dealer < Participant
  def display_hand
    prompt "Dealer has a #{joinor(hand, ', a ', 'and a')}"
    prompt "Dealer's hand value is #{total}"
  end

  def display_first_card
    prompt "The dealer has a #{hand.first}"
    puts
  end
end

class Deck
  def initialize
    @deck = []
    shuffle!
  end

  def size
    @deck.size
  end

  def deal(participant)
    shuffle! if empty?
    participant << @deck.shift
  end

  def shuffle!
    Card::SUITS.each do |suit|
      Card::RANKS.each do |rank|
        @deck << Card.new(suit, rank)
      end
    end
    @deck.shuffle!
  end

  def empty?
    @deck.empty?
  end
end

class Card
  SUITS = %w(hearts diamonds clubs spades)
  RANKS = (2..10).map(&:to_s) + %w(J Q K A)

  def initialize(suit, rank)
    @suit = suit
    @rank = rank
  end

  def to_s
    "#{@rank} of #{@suit}"
  end

  def value
    return @rank.to_i if lower_rank?
    return 10 if higher_rank?
    return 11 if ace?
  end

  def lower_rank?
    (2..10).map(&:to_s).include?(@rank)
  end

  def higher_rank?
    %w(J Q K).include?(@rank)
  end

  def ace?
    @rank == 'A'
  end
end

class Game
  include Inputable

  HAND_VALUE_LIMIT = 21
  DEALER_HIT_LIMIT = 17

  def initialize
    @deck = Deck.new
    @player = Player.new
    @dealer = Dealer.new
  end

  def start
    deal_cards
    show_initial_cards
    player_turn
    dealer_turn
    show_result
  end

  private

  def deal_cards
    2.times do
      @deck.deal(@player)
      @deck.deal(@dealer)
    end
  end

  def show_initial_cards
    @player.display_hand
    @dealer.display_first_card
  end

  def player_turn
    input_msg = "Please choose if you want to"
    player_choice = nil
    loop do
      break if player_choice == 'stay' || @player.busted?

      player_choice = input_choice(['hit', 'stay'], input_msg)
      if player_choice == 'hit'
        @deck.deal(@player)
        @player.display_hand
        prompt "You busted!"if @player.busted?
      end
    end
  end

  def dealer_turn
    return if @player.busted?

    @dealer.display_hand


    loop do
      break if @dealer.busted? || @dealer.total >= DEALER_HIT_LIMIT
      prompt "Press enter to continue"
      gets
      @deck.deal(@dealer)
      @dealer.display_hand
      prompt "Dealer busted!"if @dealer.busted?
    end
  end

  def show_result
    case result
    when :dealer_win
      prompt 'Dealer won!'
    when :player_win
      prompt 'Player won!'
    when :tie
      prompt "It's a tie!"
    end
  end

  def result
    case
    when @player.busted? then :dealer_win
    when @dealer.busted? then :player_win
    when @dealer.total > @player.total then :dealer_win
    when @player.total > @dealer.total then :player_win
    else :tie
    end
  end
end


Game.new.start

















