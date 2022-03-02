# rubocop: disable Layout/LineLength
=begin
I didn't use a class for score (integer), and for the history of moves (array)

I found that creating subclasses for each move made the code less readable. However, it permitted to simpify the < and > methods for the Move objects and permitted to get rid of the Move objects instance variable @name.
In the same way, making subclasses for computers permitted to simplify the set_behavior method.
=end
# rubocop: enable Layout/LineLength

module Interactivable
  def prompt(message)
    puts "=> #{message}"
  end

  def possible_choices(list, str)
    possible_list = []
    list.each do |elt|
      possible_list << elt if elt.match(/\A#{str}/)
    end
    possible_list
  end

  def list_to_str_choice(arr)
    arr[0..-2].join(', ') + " or #{arr.last}"
  end

  def input_formatted
    gets.chomp.downcase.strip
  end

  def input_yes_no(message)
    answer = ''
    loop do
      prompt "#{message} (y/n)"
      answer = input_formatted
      break if ['y', 'n', 'yes', 'no'].include?(answer)
      prompt "Sorry, must be y or n"
    end
    answer
  end

  # rubocop: disable Metrics/MethodLength
  def input_choice(list_str)
    choices_str = list_to_str_choice(list_str)

    loop do
      prompt("Please choose #{choices_str}")
      str = input_formatted
      list_possibles = possible_choices(list_str, str)

      case list_possibles.size
      when 0 then prompt("Sorry, invalid choice.")
      when 1 then return list_possibles.first
      else prompt("Do you mean #{list_to_str_choice(list_possibles)}?")
      end
    end
  end
  # rubocop: enable Metrics/MethodLength
end

class Move
  VALUES = ['rock', 'paper', 'scissors', 'lizard', 'spock']
  VALUES_STR = Move::VALUES.map(&:capitalize).join(', ')

  def self.create_object(symbol)
    case symbol
    when :rock then Rock.new
    when :paper then Paper.new
    when :scissors then Scissors.new
    when :lizard then Lizard.new
    when :spock then Spock.new
    end
  end

  def self.subclasses
    [Rock, Paper, Scissors, Lizard, Spock]
  end

  def comparable?(other_move)
    Move.subclasses.include?(self.class) &&
      Move.subclasses.include?(other_move.class)
  end

  def to_s
    self.class.to_s.downcase
  end

  def >(other_move)
    unless comparable?(other_move)
      puts :not_comparable
      return nil
    end

    self.class.win_against.include?(other_move.class)
  end

  def <(other_move)
    unless comparable?(other_move)
      puts :not_comparable
      return nil
    end

    self.class.lose_against.include?(other_move.class)
  end
end

class Rock < Move
  def self.win_against
    [Lizard, Scissors]
  end

  def self.lose_against
    [Paper, Spock]
  end
end

class Paper < Move
  def self.win_against
    [Rock, Spock]
  end

  def self.lose_against
    [Scissors, Lizard]
  end
end

class Scissors < Move
  def self.win_against
    [Paper, Lizard]
  end

  def self.lose_against
    [Rock, Spock]
  end
end

class Lizard < Move
  def self.win_against
    [Paper, Spock]
  end

  def self.lose_against
    [Rock, Scissors]
  end
end

class Spock < Move
  def self.win_against
    [Scissors, Rock]
  end

  def self.lose_against
    [Paper, Lizard]
  end
end

class Player
  attr_accessor :move, :name, :score, :move_history

  def initialize
    @score = 0
    @move_history = []
    set_name
  end

  def add_move_to_history
    move_history.prepend(move.to_s)
  end
end

class Human < Player
  def set_name
    n = ''
    loop do
      prompt "What's your name?"
      n = input_formatted
      break unless n.empty?
      prompt "Sorry, must enter a value."
    end
    self.name = n
  end

  def choose
    choice = input_choice(Move::VALUES)

    self.move = Move.create_object(choice.to_sym)
    add_move_to_history
  end
end

class Computer < Player
  def self.subclasses
    [R2D2, Hal, Chappie, Sonny, Number5]
  end

  def self.create_object
    Computer.subclasses.sample.new
  end

  def initialize
    super
    set_behavior
  end

  def set_name
    self.name = self.class.to_s
  end

  def choose
    self.move = Move.create_object(behavior.choose_move)
    add_move_to_history
  end

  private

  attr_accessor :behavior
end

class Behavior
  def initialize(r, p, s, li, sp)
    @ratios = {
      rock: r,
      paper: p,
      scissors: s,
      lizard: li,
      spock: sp
    }
    puts "not valid cpu behavior" unless valid?
  end

  def valid?
    @ratios.values.sum == 1
  end

  def choose_move
    unless valid?
      puts "Can't choose cpu move"
      return nil
    end

    random_nb = rand
    total_ratio = 0

    @ratios.each do |move, ratio|
      total_ratio += ratio
      return move if random_nb < total_ratio
    end
  end
end

class R2D2 < Computer
  def set_behavior
    self.behavior = Behavior.new(1, 0, 0, 0, 0)
  end
end

class Hal < Computer
  def set_behavior
    self.behavior = Behavior.new(0.3, 0, 0.7, 0, 0)
  end
end

class Chappie < Computer
  def set_behavior
    self.behavior = Behavior.new(0.2, 0.2, 0.2, 0.2, 0.2)
  end
end

class Sonny < Computer
  def set_behavior
    self.behavior = Behavior.new(0, 0.25, 0, 0.5, 0.25)
  end
end

class Number5 < Computer
  def set_name
    self.name = 'Number 5'
  end

  def set_behavior
    self.behavior = Behavior.new(0.3, 0.3, 0.2, 0.1, 0.1)
  end
end

class RPSGame
  attr_accessor :human, :computer

  SCORE_LIMIT = 3
  HISTORY_LENGTH = 5

  RULES = <<~MSG
  Rock crushes Lizard / crushes Scissors
     Paper covers Rock / disproves Spock
     Spock smashes Scissors / vaporizes Rock
     Scissors cuts Paper / decapitates Lizard
     Lizard eats Paper / poisons Spock
  MSG

  def initialize
    system 'clear'
    @human = Human.new
    @computer = Computer.create_object
  end

  def display_welcome_message
    prompt "Welcome to #{Move::VALUES_STR}! " \
           "First one to score #{SCORE_LIMIT} points win!"
    answer = input_yes_no("Do you want to display the rules?")
    system 'clear'
    prompt RULES if answer == 'y'
  end

  def display_goodbye_message
    prompt "Thanks for playing #{Move::VALUES_STR}. Good bye!"
  end

  def display_moves
    prompt "#{human.name} chose #{human.move}."
    prompt "#{computer.name} chose #{computer.move}."
  end

  def display_winner
    if human.move > computer.move
      prompt "#{human.name} won!"
    elsif human.move < computer.move
      prompt "#{computer.name} won!"
    else
      prompt "It's a tie!"
    end
  end

  def update_score
    if human.move > computer.move
      human.score += 1
    elsif human.move < computer.move
      computer.score += 1
    end
  end

  def display_score
    prompt(
      <<~MSG
      The score is: #{human.score} for you,
                       #{computer.score} for the computer.

      MSG
    )
  end

  def play_again?
    answer = input_yes_no("Would you like to play again?")

    return false if answer == 'n'
    return true if answer == 'y'
  end

  def play_round
    human.choose
    computer.choose
    system 'clear'
    display_moves
    display_winner
    update_score
    display_score
  end

  def end_tournament?
    (human.score >= SCORE_LIMIT) || (computer.score >= SCORE_LIMIT)
  end

  def display_tournament_winner
    if human.score >= SCORE_LIMIT
      prompt "Congratulations on winning the tournament!"
    elsif computer.score >= SCORE_LIMIT
      prompt "Computer won the tournament!"
    end
  end

  def play_tournament
    reset_scores
    loop do
      play_round
      break if end_tournament?
    end
    display_tournament_winner
  end

  def reset_scores
    human.score = 0
    computer.score = 0
  end

  def play
    system 'clear'
    display_welcome_message
    loop do
      play_tournament
      display_move_history
      break unless play_again?
      system 'clear'
    end

    display_goodbye_message
  end

  def display_move_history
    prompt "Last moves played by you, #{human.name}: " \
           "#{human.move_history[0, HISTORY_LENGTH]}"
    prompt "Last moves played by by #{computer.name}: " \
           "#{computer.move_history[0, HISTORY_LENGTH]}"
  end
end

include Interactivable
RPSGame.new.play
