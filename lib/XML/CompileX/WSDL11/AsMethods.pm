package XML::CompileX::WSDL11::AsMethods;

use Modern::Perl '2010';    ## no critic (Modules::ProhibitUseQuotedVersion)

# VERSION
use utf8;
use Carp;
use LWP::UserAgent;
use Moo;
use MooX::Types::MooseLike::Base qw(ArrayRef Bool InstanceOf);
use Package::Stash;
use Params::Util '_CLASS';
use Scalar::Util 'blessed';
use Try::Tiny;
use URI;
use XML::Compile::SOAP11;
use XML::Compile::Transport::SOAPHTTP;
use XML::Compile::WSDL11;
use XML::CompileX::Schema::Loader;

has namespace => (
    is  => 'lazy',
    isa => sub { $_[0] !~ / \P{ASCII} /xms and _CLASS( $_[0] ) },
    default => sub { ( caller 2 )[0] },
);

has user_agent => (
    is      => 'lazy',
    isa     => InstanceOf ['LWP::UserAgent'],
    default => sub { LWP::UserAgent->new },
);

has uris => (
    is       => 'ro',
    isa      => ArrayRef [ InstanceOf ['URI'] ],
    required => 1,
    coerce   => sub {
        'ARRAY' eq ref $_[0]
            ? [ map { URI->new($_) } @{ $_[0] } ]
            : [ URI->new( $_[0] ) ];
    },
);

sub export {
    my $self = shift;
    my $stash = Package::Stash->new( shift // $self->namespace );
    for my $method ( map { $_->name } $self->wsdl->operations ) {
        $stash->add_symbol( "&$method" => $self->_method_closure($method) );
    }
    return;
}

sub _method_closure {
    my ( $self, $method ) = @_;
    return sub {
        if ( 1 == @_ % 2 ) {shift}
        try {
            $self->wsdl->compileCall( $method,
                transport => $self->_transport );
        }
        catch {
            croak $_
                if 'Log::Report::Exception' ne ref
                and 'a compiled call for {name} already exists' ne
                $_->message->msgid;
        };
        my @results = $self->wsdl->call( $method => @_ );
        if ( not $results[0] ) {
            for ( $results[1]->errors ) { $_->throw }
        }
        return wantarray ? @results : $results[0];
    };
}

has wsdl => ( is => 'lazy', isa => InstanceOf ['XML::Compile::WSDL11'] );

sub _build_wsdl {
    my $self = shift;
    my $wsdl = XML::Compile::WSDL11->new;
    if ( $self->use_loader ) {
        my $loader = XML::CompileX::Schema::Loader->new(
            wsdl => $wsdl,
            map { ( $_ => $self->$_ ) } qw(uris user_agent),
        );
        $loader->collect_imports;
    }
    return $wsdl;
}

has use_loader => ( is => 'ro', isa => Bool, default => 1 );

has _transport => (
    is      => 'lazy',
    isa     => InstanceOf ['XML::Compile::Transport'],
    default => sub {
        XML::Compile::Transport::SOAPHTTP->new(
            user_agent => shift->user_agent );
    },
);

## no critic (Subroutines::RequireArgUnpacking)
sub BUILDARGS {
    shift;
    return @_ if 'HASH' eq ref $_[0];
    return { ( 1 == @_ % 2 ) ? ( uris => @_ ) : @_ };
}

1;

# ABSTRACT: Export SOAP operations as Perl methods

__END__

=for Pod::Coverage BUILDARGS

=head1 SYNOPSIS

    use XML::CompileX::WSDL11::AsMethods;
    use URI::file;

    my $methods = XML::CompileX::WSDL11::AsMethods->new(
        URI::file->new_abs('stockquote.wsdl') );
    $methods->export('My::StockQuote');

    my ($answer_ref, $trace) = My::StockQuote->GetLastTradePrice(
        body => {tickerSymbol => 'AAPL'} );

=head1 DESCRIPTION

This module provides a mechanism for exporting the SOAP operations defined in
one or more WSDL/schema documents as regular Perl class methods that will then
call the appropriate web service. By default it exports these methods into
the current namespace when the C<export> method is called; however you can
explicitly specify a different one either during construction or when calling
C<export>.

=attr uris

Either a URI string or L<URI|URI> object, or a reference to an array of them.
These will be loaded as WSDL and XSD files that define the available SOAP
operations and their input and output parameters.

If you pass an odd number of arguments to the C<new> constructor method (and
you're not just passing in a hash reference), the first argument will be
used as the value for this attribute.

=attr namespace

The namespace of the Perl class into which the SOAP operations will be exported
as methods. Can be overridden when the C<export> method is actually called.

=attr user_agent

An instance of L<LWP::UserAgent|LWP::UserAgent> used to load the C<uris> as
well as make SOAP calls. You may want to set this to your own instance of a
subclass or otherwise customized object to add caching, logging or
other features.

=attr use_loader

Defaults to true, will use
L<XML::CompileX::Schema::Loader|XML::CompileX::Schema::Loader> to collect all
imported documents from C<uris>. You may want to unset this if you know there
are no imports or you are handling it some other way.

=attr wsdl

Use this optional attribute at construction time to specify your own
L<XML::Compile::WSDL11|XML::Compile::WSDL11> object, perhaps after installing
hooks or other mechanisms for correcting issues with retrieved WSDL or schemas.

=method export

When called, this method exports the operations defined by C<uris> into either
the current namespace or one passed in as a string. These methods typically
take a hash of name-value pairs as arguments, and will return their results
as a hash reference and an
L<XML::Compile::SOAP::Trace|XML::Compile::SOAP::Trace> object.
