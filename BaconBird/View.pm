package BaconBird::View;
use Moose;

use stfl;

has 'f' => (
	is => 'rw',
	isa => 'stfl::stfl_form',
);

has 'ctrl' => (
	is => 'rw',
	isa => 'BaconBird::Controller',
);

sub BUILD {
	my $self = shift;

	$self->f(stfl::create( <<"EOT" ));
vbox
  hbox
    .expand:0
    \@style_normal:bg=blue,fg=white,attr=bold
    label text:"[baconbird 0.1]" .expand:h
    label .tie:r text[rateinfo]:"-1/-1" .expand:0
  list[tweets]
    style_focus[listfocus]:fg=yellow,bg=blue,attr=bold
    .expand:vh
    pos_name[tweetposname]:
    pos[tweetpos]:0
  vbox
    .expand:0
    .display:1
    label text:"q:Quit ... more help" .expand:h style_normal:bg=blue,fg=white,attr=bold
  hbox[lastline]
    .expand:0
    label text[msg]:"foobar" .expand:h
EOT
}

sub next_event {
	my $self = shift;

	my $e = $self->f->run(0);
	return if (!defined($e));

	if ($e eq "q") {
		$self->ctrl->quit(1);
	} else {
		$self->status_msg("input: $e");
	}
}

sub status_msg {
	my $self = shift;
	my ($msg) = @_;

	$self->f->set("msg", $msg);
	$self->f->run(-1);
}

sub set_timeline {
	my $self = shift;
	my ($tl) = @_;

	my $list = "{list ";

    foreach my $tweet (@$tl) {
      my $text = "@" . $tweet->{user}{screen_name} . ": " . $tweet->{text};
      $list .= "{listitem text:" . stfl::quote($text) . "}";
	}

	$list .= "}";

	$self->f->modify("tweets", "replace_inner", $list);
}


no Moose;
1;
