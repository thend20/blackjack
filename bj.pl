#!/usr/bin/perl

use Games::Blackjack;
use Data::Dumper;
use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($DEBUG);

my $DECKS = 1;
my $HANDS = 100;

my %BASIC_STRATEGY = (
    # Dealer has  2 3 4 5 6 7 8 9 10 11
    9 =>  [qw(0 0 H D D D D H H H  H  H)],
    10 => [qw(0 0 D D D D D D D D  H  H)],
    11 => [qw(0 0 D D D D D D D D  D  H)],
    12 => [qw(0 0 H H S S S H H H  H  H)],
    13 => [qw(0 0 S S S S S H H H  H  H)],
    14 => [qw(0 0 S S S S S H H H  H  H)],
    15 => [qw(0 0 S S S S S H H H  H  H)],
    16 => [qw(0 0 S S S S S H H H  H  H)],

);


# Create new shoe of cards
my $SHOE = Games::Blackjack::Shoe->new(nof_decks => $DECKS);

my $last_winner;
my $bank_roll = 0;
while ( $SHOE->remaining() > 10 ) {
    print "\nNew Hand\n";


    # randomize bet for now
    my $init_bet = int(rand(90)) + 10;

    # Create two hands, player/dealer
    my $player = Games::Blackjack::Hand->new(shoe => $SHOE);
    my $dealer = Games::Blackjack::Hand->new(shoe => $SHOE);

    # get the dealer up card
    my $up_card = start_hand($player, $dealer);

    my @cards = hand_to_array($player);

    # split or double?
    my $additional_bet = preprocces_hand($up_card, $player, @cards);
    my $double = double_down($up_card, $player);

    # Play the players hand
    my $player_done;
    while ($player_done < 1) {
        # Bust?
        last unless $player->count();

        # what do we do?
        my $hit = process_hand($up_card, $player);
        hit_me($player) if $hit eq 'H';
        $player_done++ if $hit eq 'S';

        #tmp
        $player_done++ unless $hit eq 'H';
    }

    #### FIGURE OUT SPLITS AND DOUBLES

    # Play the dealers hand
    my $dealer_done;
    while ($dealer_done < 1) {
        my $count = $dealer->count("hard");

        # Bust?
        last unless $count;

        if ($count < 17) {
            print "hit dealers $count\n";
            hit_me($dealer);
        } else {
            $dealer_done++;
        }
    }

    $result = $player->score($dealer);

    my $sc_player = $player->count("hard") || "BUST";
    my $sc_dealer = $dealer->count("hard") || "BUST";
    print "bet:$init_bet\tw/l:$result\t\$$bank_roll\tdealer_up:$up_card\tdealer_final:$sc_dealer\tplayer_final:$sc_player\n";

    $bank_roll += $result * $init_bet;
}

print "\nTotal W/L: \$$bank_roll\n";


exit;

sub process_hand {
    my $up_card = shift;
    my $player = shift;
    my $count = $player->count("soft");

    if ($count < 9) {
        print "H $count against $up_card\n";
        return 'H';
    }
    if ($count > 16) {
        print "S $count against $up_card\n";
        return 'S';
    }


    if ($BASIC_STRATEGY{$count}) {
        print $BASIC_STRATEGY{$count}[$up_card];
        print " $count against $up_card\n";
        return $BASIC_STRATEGY{$count}[$up_card];
    }
}

sub hit_me {
    my $player = shift;
    $player->draw();
}

# Determine if we need to do special stuff before first hit
# mainly split...and maybe surrender
sub preprocces_hand {
    my $up_card = shift;
    my $player = shift;
    my @cards = @_;

    my $count = $player->count("soft");

    if ($cards[0] eq $cards[1]) {
        print "split @cards?\n";
    }

    if ($up_card > 9) {
        print "surrender our $count?\n";
    }
 
    #return more betting?
}

sub double_down {
    my $up_card = shift;
    my $player = shift;

    my $count = $player->count("soft");

    if ($count <= 11) {
        print "double down against $up_card?\n";
    }
}

# deals out cards, returns the dealers up card
sub start_hand {
    my $player = shift;
    my $dealer = shift;

    $player->draw();

    $dealer->draw();
    my $up_card = $dealer->count_as_string();

    $player->draw();
    $dealer->draw();

    return $up_card;
}

# grabs the value of each card dealt to a player
sub hand_to_array {
    my $player = shift;
    my @cards;
    foreach my $card (@{$player->{cards}}) {
         push @cards, @$card[1];
    }
    return @cards;
}