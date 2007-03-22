package WWW::LargeFileFetcher;

use warnings;
use strict;

=head1 NAME

WWW::LargeFileFetcher - The great new WWW::LargeFileFetcher!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use WWW::LargeFileFetcher;

    my $fetcher = WWW::LargeFileFetcher->new();
    $fetcher->get('http://www.example.com/video.rm', 'video.rm');

=head1 DESCRIPTION

    C<WWW::LargeFileFetcher> is used to fetch large files (like
    videos, audios) from internet.

=head1 METHODS

=over

=item $fetcher = WWW::LargeFileFetcher->new(%opinions);

The opinions hash can be:
    agent=>'the agent string',
    timeout=>time in seconds,
    proxy=>'http proxy to be used'

=item $fetcher->get($url,$filename);

The return value can be:
    1  : success
    -1 : IO error
    -2 : internet access error

The detailed error string can be accessed from $fetcher->err_str();

=item $fetcher->test($url);

This method is used to test whether the $url is downloadable.

=back    

=head1 AUTHOR

Zhang Jun, C<< <jzhang533 at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-www-largefilefetcher at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-LargeFileFetcher>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::LargeFileFetcher

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-LargeFileFetcher>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-LargeFileFetcher>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-LargeFileFetcher>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-LargeFileFetcher>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Zhang Jun, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

use strict;
use warnings;
use LWP::UserAgent;

# Constructor new
sub new {
    my $proto  = shift;
    my $class  = ref($proto) || $proto;

    my $self = {};
    bless($self, $class);

    # Run initialisation code
    return $self->_init(@_);
}

sub _init{
    my $self = shift;
    if (@_ != 0) { # We are expecting our configuration to come as an anonymous hash
        if (ref $_[0] eq 'HASH') {
            my $hash=$_[0];
            foreach my $key (keys %$hash) {
                $self->{lc($key)}=$hash->{$key};
            }
        }else { # Using a more conventional named args
            my %args = @_;
            foreach my $key (keys %args) {
                $self->{lc($key)}=$args{$key};
            }
        }
    }

    my $ua = LWP::UserAgent->new(
        keep_alive => 1
    ) or return undef;

    if(exists $self->{'timeout'}){
        $ua->timeout($self->{'timeout'});
    }
    if(exists $self->{'proxy'}){
        $ua->proxy('http',$self->{'proxy'});
    }
    if(exists $self->{'agent'}){
        $ua->agent($self->{'agent'});
    }

    $self->{'ua'}=$ua;
    $self->{err_str}='';
    $self->{err_code}=1;
    return $self;
}

sub err_str{
    return $_[0]->{err_str};
}

# input: url, file
# return: 1 for success, -1 for IO error, -2 for internet access error
# url is stored into file
sub get{
    my ($self,$url,$file)=@_;
    $self->{err_code}=1;
    my $set=0;
    $|++;
    my $res = $self->{'ua'}->get($url, ':content_cb'=>
         sub {
            unless ($set){
                unless (open(FILE, ">$file") ){
		    $self->{err_str} = "error, Can't open $file: $!\n";
		    $self->{err_code}=-1;
		    die;
		}
                binmode FILE; 
		$set = 1;
	    }
            unless( print FILE $_[0] ){
	        $self->{err_str} = "error, Can't write to $file: $!\n";
		$self->{err_code}=-1;
		die;
	    }
	}
    );
    
    if (fileno(FILE)) {
	    unless( close(FILE) ){
		    $self->{err_str} = "error, Can't write to $file: $!\n";
		    $self->{err_code}=-1;
	    }
    }

    if($self->{err_code} == -1){
	    unlink($file);
	    return -1;
    }

    if( defined($res) && $res->code == 200 ) {
        return 1;
    }else{
	    $self->{err_str} = "error, ". $res->status_line()."\n";
	    $self->{err_code}=-2;
	return -2;
    }
}


# test if the url can be downloaded, not really download it
# input: url
# return: 1 for success, -1 for IO error, -2 for internet access error
sub test{
    my ($self,$url)=@_;
    $self->{err_code}=1;
    my $res = $self->{'ua'}->get($url, ':content_cb'=>
         sub {
		die;
	    }
    );
    
    if( defined($res) && $res->code == 200 ) {
        return 1;
    }else{
	    $self->{err_str} = "error, ". $res->status_line()."\n";
	    $self->{err_code}=-2;
	return -2;
    }
}

1; # End of WWW::LargeFileFetcher
