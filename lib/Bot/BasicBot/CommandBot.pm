package Bot::BasicBot::CommandBot;

use strict;
use warnings;
use 5.014;

use Tie::RegexpHash 0.16;
use List::Util qw(any);
use Data::Dumper;

use Exporter 'import';
use base qw/Bot::BasicBot/;

our @EXPORT_OK = qw(command);

my %command;

sub command {
    (caller)[0]->declare_command(@_);
}

sub declare_command {
    my $package = shift;
    my $sub = pop;
    my $command = pop;

    my %options = @_;

    $options{events} //= ['said'];

    if (not exists $command{$package}) {
        $command{$package} = {};
        tie %{$command{$package}}, 'Tie::RegexpHash';
    }

    $command{$package}{$command} = {
        sub => $sub,
        %options,
    };
}


sub new {
    my $class = shift;
    my %opts = @_;

    my $address = delete $opts{address};
    my $trigger = delete $opts{trigger};

    my $self = $class->SUPER::new(%opts);
    $self->{trigger} = $trigger if defined $trigger;
    $self->{address} = $address if defined $address;

    return $self;
}

sub said {
    my $self = shift;
    my ($data) = @_;

    my $package = ref $self;

    if (my @auto = $self->_auto) {
        return join " ", @auto;
    }

    if ($self->{address} and not $data->{address}) {
        return;
    }

    if ($self->{trigger} and $data->{body} !~ s/^\Q$self->{trigger}//) {
        return;
    }

    my ($cmd, $message) = split ' ', $data->{body}, 2;
    my $found = $command{$package}{$cmd} or return "What is $cmd?";

    any { $_ eq 'said' } @{$found->{events}} or return;

    $found->{sub}->($self, $cmd, $message);
}

sub emoted {
}

sub noticed {
}

sub _auto { }


1;
