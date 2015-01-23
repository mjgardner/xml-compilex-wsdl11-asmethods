package XML::CompileX::WSDL11::AsMethods;

use Modern::Perl '2010';    ## no critic (Modules::ProhibitUseQuotedVersion)

# VERSION
use utf8;
use Carp;
use LWP::UserAgent;
use Moo;
use MooX::Types::MooseLike::Base qw(ArrayRef InstanceOf);
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
    default => sub { (caller 2)[0] },
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

has _wsdl => (
    is  => 'lazy',
    isa => InstanceOf ['XML::Compile::WSDL11'],
);

sub _build__wsdl {
    my $self   = shift;
    my $wsdl   = XML::Compile::WSDL11->new;
    my $loader = XML::CompileX::Schema::Loader->new(
        wsdl => $wsdl,
        map { ( $_ => $self->$_ ) } qw(uris user_agent),
    );
    $loader->collect_imports;
    return $wsdl;
}

has _transport => (
    is      => 'lazy',
    isa     => InstanceOf ['XML::Compile::Transport'],
    default => sub {
        XML::Compile::Transport::SOAPHTTP->new(
            user_agent => shift->user_agent );
    },
);

sub _method_closure {
    my ( $self, $method ) = @_;
    return sub {
        try {
            $self->_wsdl->compileCall( $method,
                transport => $self->_transport );
        }
        catch {
            croak $_
                if 'Log::Report::Exception' ne ref
                and 'a compiled call for {name} already exists' ne
                $_->message->msgid;
        };
        my @results = $self->_wsdl->call( $method => @_ );
        if ( not $results[0] ) {
            for ( $results[1]->errors ) { $_->throw }
        }
        return wantarray ? @results : $results[0];
    };
}

## no critic (Subroutines::RequireArgUnpacking)
sub export {
    my $self = __PACKAGE__ eq ref $_[0] ? shift : __PACKAGE__;
    for my $method ( map { $_->name } $self->_wsdl->operations ) {
        ## no critic (ProhibitNoStrict,ProhibitNoWarnings)
        no strict 'refs';
        no warnings 'redefine';
        *{ $self->namespace . "::$method" } = $self->_method_closure($method);
    }
    return;
}

1;

# ABSTRACT: Export SOAP operations as Perl methods

__END__

=head1 SYNOPSIS

    use XML::CompileX::WSDL11::AsMethods;

    XML::CompileX::WSDL11::AsMethods->export('foo.wsdl');
