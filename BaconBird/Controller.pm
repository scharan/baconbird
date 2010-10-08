package BaconBird::Controller;
use Moose;

use IO::Handle;

has 'model' => (
	is => 'rw',
	isa => 'BaconBird::Model',
);

has 'view' => (
	is => 'rw',
	isa => 'BaconBird::View',
);

has 'shortener' => (
	is => 'rw',
	isa => 'BaconBird::Shortener',
);

has 'pinfile' => (
	is => 'rw',
	isa => 'Str',
);

has 'configdir' => (
	is => 'rw',
	isa => 'Str',
	default => $ENV{'HOME'} . "/.baconbird",
);

has 'quit' => (
	is => 'rw',
	isa => 'Bool',
);


sub BUILD {
	my $self = shift;
	mkdir($self->configdir, 0755);
	$self->pinfile($self->configdir . "/authcode");
}

sub run {
	my $self = shift;
	my $ts = time + $self->model->get_wait_time;

	eval {
		$self->login;
	};
	if (my $err = $@) {
		die "Error: authorization failed.\nAre you sure you provided the correct authentication information?\n";
	}

	$self->view->set_rate_limit($self->model->get_rate_limit);
	$self->reload_all;

	$self->view->prepare;

	while (!$self->quit) {
		eval {
			$self->view->set_rate_limit($self->model->get_rate_limit);
			$self->view->next_event();

			if (!$self->quit && time >= $ts) {
				$self->reload_all_and_update_view;
				$ts = time + $self->model->get_wait_time;
			}
		};
		if (my $err = $@) {
			$self->view->status_msg("Error: $err");
		}
	}
}

sub status_msg {
	my $self = shift;
	my ($msg) = @_;
	$self->view->status_msg($msg);
}

sub reload_all {
	my $self = shift;
	$self->status_msg("Loading...");
	$self->reload_all_and_update_view;
	$self->status_msg("");
}

sub reload_all_and_update_view {
	my $self = shift;
	$self->model->reload_all;
	$self->view->get_timeline;
}

sub load_tokens {
	my $self = shift;
	open(my $fh, "<", $self->pinfile) or return (undef, undef);
	my $access_token = <$fh>;
	chomp($access_token);
	my $access_token_secret = <$fh>;
	chomp($access_token_secret);
	close($fh);
	return ($access_token, $access_token_secret);
}

sub save_tokens {
	my $self = shift;
	my ($access_token, $access_token_secret) = @_;
	open(my $fh,">",$self->pinfile) or die "Error: couldn't open $self->pinfile: $!\n";
	print $fh "$access_token\n$access_token_secret\n";
	close($fh);
}

sub get_pin {
	my $self = shift;
	my ($auth_url) = @_;

	print "Please authorize this app at ", $auth_url, " and enter the PIN: ";
	STDOUT->flush;
	my $pin = <STDIN>;
	chomp($pin);
	return $pin;
}

sub login {
	my $self = shift;
	$self->model->login;
}

sub post_update {
	my $self = shift;
	my ($tweet, $in_reply_to_status_id) = @_;
	$self->model->post_update($tweet, $in_reply_to_status_id);
	$self->reload_all_and_update_view;
}

sub retweet {
	my $self = shift;
	my ($tweetid) = @_;
	$self->model->retweet($tweetid);
	$self->reload_all_and_update_view;
}

sub lookup_author {
	my $self = shift;
	my ($tweetid) = @_;
	return $self->model->lookup_author($tweetid);
}

sub get_timeline {
	my $self = shift;
	return $self->model->get_timeline;
}

sub select_timeline {
	my $self = shift;
	my ($timeline) = @_;
	$self->model->select_timeline($timeline);
}

sub get_message_by_id {
	my $self = shift;
	my ($id) = @_;
	return $self->model->get_message_by_id($id);
}

sub get_dm_by_id {
	my $self = shift;
	my ($id) = @_;
	return $self->model->get_dm_by_id($id);
}

sub shorten {
	my $self = shift;
	my ($text) = @_;
	return $self->shortener->shorten_text($text);
}

sub is_direct_message {
	my $self = shift;
	return $self->model->is_direct_message;
}

sub send_dm {
	my $self = shift;
	my ($tweet, $rcpt) = @_;
	$self->model->send_dm($tweet, $rcpt);
}

sub set_search_phrase {
	my $self = shift;
	my ($searchphrase) = @_;
	$self->model->set_search_phrase($searchphrase);
}

sub get_search_phrase {
	my $self = shift;
	return $self->model->get_search_phrase;
}

sub set_user_name {
	my $self = shift;
	my ($name) = @_;
	$self->model->set_user_name($name);
};

sub get_user_name {
	my $self = shift;
	return $self->model->get_user_name;
}

sub toggle_favorite {
	my $self = shift;
	my ($tweetid) = @_;
	$self->model->toggle_favorite($tweetid);
}

no Moose;
1;
