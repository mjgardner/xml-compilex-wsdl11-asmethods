#!perl

use Modern::Perl '2010';    ## no critic (Modules::ProhibitUseQuotedVersion)
use Test::Most;
use Test::LWP::UserAgent;
use Const::Fast;
use HTTP::Response;
use HTTP::Status qw(:constants status_message);
use Path::Tiny;
use URI;
use URI::file;
use XML::Compile::WSDL11;
use XML::Compile::SOAP11;
use XML::Compile::SOAP::Util 'SOAP11ENV';
use XML::Compile::Transport::SOAPHTTP;
use XML::LibXML;
use XML::LibXML::XPathContext;
use XML::CompileX::Schema::Loader;
use XML::CompileX::WSDL11::AsMethods;

#use Log::Report mode => 'DEBUG';

const my $SERVICE_WSDL => 't/stockquote/stockquoteservice.wsdl';
const my %PARAMS       => ( body => { tickerSymbol => 'AAPL' } );
const my $EXPECTED     => 34.5;
const my $XPC          => XML::LibXML::XPathContext->new;
const my $XPATH        => '/SOAPENV:Envelope/SOAPENV:Body/*';

$XPC->registerNs( SOAPENV => SOAP11ENV );
$XPC->registerNs( xsd1    => 'http://example.com/stockquote/schemas' );

my $user_agent = Test::LWP::UserAgent->new( network_fallback => 1 );
$user_agent->map_response( 'example.com' => \&examplecom_responder );
$user_agent->map_response(
    sub { 'POST' eq $_[0]->method and 'localhost' eq $_[0]->uri->host } =>
        \&localhost_responder );

my $methods = new_ok( 'XML::CompileX::WSDL11::AsMethods' =>
        [ URI::file->new_abs($SERVICE_WSDL), user_agent => $user_agent ] );

subtest 'no namespace' => sub {
    lives_ok( sub { $methods->export } => 'export' );
    is( ref *GetLastTradePrice{CODE}, 'CODE' => 'GetLastTradePrice coderef' );
    cmp_ok( GetLastTradePrice(%PARAMS)->{body}{price},
        '==', $EXPECTED => 'GetLastTradePrice response' );
};

subtest 'with namespace' => sub {
    lives_ok(
        sub { $methods->export('Local::Test::StockQuote') } => 'export' );
    is( ref *Local::Test::StockQuote::GetLastTradePrice{CODE},
        'CODE' => 'GetLastTradePrice coderef' );
    cmp_ok(
        Local::Test::StockQuote->GetLastTradePrice(%PARAMS)->{body}{price},
        '==', $EXPECTED => 'GetLastTradePrice response' );
};

done_testing;

sub examplecom_responder {
    my $request = shift;

    my $path = $request->uri->path;
    $path =~ s(^/)();

    my $response = HTTP::Response->new( HTTP_OK => status_message(HTTP_OK) );
    $response->content( path( 't', $path )->slurp );
    return $response;
}

sub localhost_responder {
    return HTTP::Response->new(
        HTTP_OK => status_message(HTTP_OK),
        [ 'Content-Type' => 'text/xml' ] => path(
            't/stockquote',
            (   split ':' => $XPC->findnodes(
                    $XPATH => XML::LibXML->load_xml(
                        string => shift->decoded_content,
                    ),
                )->get_node(1)->nodeName,
                )[1]
                . '.xml',
        )->slurp,
    );
}
