#!/usr/bin/perl
#
# Play out hands for testing basic strategy and betting regressions
#

use Games::Blackjack;
use Data::Dumper;
use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($DEBUG);

my $DECKS = 6;
my $STOPLOSS = -250;
my $STOPWIN = 350;

my %BASIC_STRATEGY = (
    # H=hit, S=stand, D=double-down, s=split
    # Dealer has  2 3 4 5 6 7 8 9 10 11
    9 =>  [qw(0 0 H D D D D H H H  H  H)],
    10 => [qw(0 0 D D D D D D D D  H  H)],
    11 => [qw(0 0 D D D D D D D D  H  H)],
    12 => [qw(0 0 H H S S S H H H  H  H)],
    13 => [qw(0 0 S S S S S H H H  H  H)],
    14 => [qw(0 0 S S S S S H H H  H  H)],
    15 => [qw(0 0 S S S S S H H H  H  H)],
    16 => [qw(0 0 S S S S S H H H  H  H)],
    As => [qw(0 0 s s s s s s s s  s  s)],
    2s => [qw(0 0 s s s s s s s s  s  s)],
    3s => [qw(0 0 s s s s s s s s  s  s)],
    4s => [qw(0 0 s s s s s s s s  s  s)],
    5s => [qw(0 0 s s s s s s s s  s  s)],
    6s => [qw(0 0 s s s s s s s s  s  s)],
    7s => [qw(0 0 s s s s s s s s  s  s)],
    8s => [qw(0 0 s s s s s s s s  s  s)],
    9s => [qw(0 0 s s s s s s s s  s  s)],
    10s=> [qw(0 0 s s s s s s s s  s  s)],
    Js => [qw(0 0 s s s s s s s s  s  s)],
    Qs => [qw(0 0 s s s s s s s s  s  s)],
    Ks => [qw(0 0 s s s s s s s s  s  s)],
);

my @BET = qw(10 15 20 25 30 35 40 45 50);

# Create new shoe of cards
my $SHOE = Games::Blackjack::Shoe->new(nof_decks => $DECKS);

my $last_winner;
my $bank_roll = 0;
my $hands=1;
while ( $SHOE->remaining() > 10 ) {
    print "\nHand $hands\n";

    # randomize bet for now
    my $init_bet = $BET[int(rand(9))];
    my $final_bet = $init_bet;

    # Create two hands, player/dealer
    my $player = Games::Blackjack::Hand->new(shoe => $SHOE);
    my $dealer = Games::Blackjack::Hand->new(shoe => $SHOE);

    # get the dealer up card
    my $up_card = start_hand($player, $dealer);

    # we need a simple array of the start cards for initial processing
    my @cards = hand_to_array($player);

    # split
    #### THESE DONT WORK YET
    my $additional_bet = preprocces_hand($up_card, $player, @cards);

    # Play the players hand
    my $player_done;
    while ($player_done < 1) {
        # Bust?
        last unless $player->count();

        # what do we do?
        my $hit = process_hand($up_card, $player);
        hit_me($player) if $hit =~ /[HD]/;

        # We are done on Stand and Double
        $player_done++ if $hit =~ /[SD]/;

        # Double down?
        $final_bet=$init_bet * 2 if $hit eq 'D';

    }

    #### TODO: FIGURE OUT SPLITS
    #### THIS INCLUDES MULTIPLE PLAYER HANDS

    # Play the dealers hand
    my $dealer_done;
    while ($dealer_done < 1) {
        my $count = $dealer->count("hard");

        # Bust?
        last unless $count;

        # Hit to 17
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
    print "bet:$init_bet\tfinal_bet:$final_bet\tw/l:$result\t\$$bank_roll\tdealer_up:$up_card\tdealer_final:$sc_dealer\tplayer_final:$sc_player\n";

    $bank_roll += $result * $final_bet;
    $hands++;

    # stop-loss stop-win
    last if $bank_roll <= $STOPLOSS;
    last if $bank_roll >= $STOPWIN;


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

    # we might split on dupes
    if ($cards[0] eq $cards[1]) {
        print "split @cards?\n";
    }

    # we might surrender on a dealers 9+
    if ($up_card > 9) {
        print "surrender our $count?\n";
    }
 
    #return more betting?
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


=head 

example output:

New Hand
S 16 against 3
hit dealers 13
bet:44  w/l:1   $0  dealer_up:3 dealer_final:BUST   player_final:6

New Hand
double down against 7?
H 5 against 7
H 15 against 7
hit dealers 13
bet:26  w/l:-1  $44 dealer_up:7 dealer_final:21 player_final:BUST

New Hand
H 12 against 2
S 20 against 2
hit dealers 12
bet:83  w/l:1   $18 dealer_up:2 dealer_final:18 player_final:20

New Hand
S 19 against 5
hit dealers 6
hit dealers 13
bet:86  w/l:1   $101    dealer_up:5 dealer_final:18 player_final:19

New Hand
S 17 against 3
hit dealers 9
hit dealers 16
bet:91  w/l:-1  $187    dealer_up:3 dealer_final:20 player_final:17

New Hand
S 14 against 5
hit dealers 9
bet:72  w/l:-1  $96 dealer_up:5 dealer_final:19 player_final:14

New Hand
surrender our 19?
S 19 against 11
hit dealers 11
hit dealers 13
bet:72  w/l:0   $24 dealer_up:11    dealer_final:19 player_final:19

New Hand
double down against 3?
D 11 against 3
hit dealers 13
bet:12  w/l:1   $24 dealer_up:3 dealer_final:BUST   player_final:11

Total W/L: $36

=cut
