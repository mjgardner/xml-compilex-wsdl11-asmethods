# NAME

XML::CompileX::WSDL11::AsMethods - Export SOAP operations as Perl methods

# VERSION

version 0.001

# SYNOPSIS

    use XML::CompileX::WSDL11::AsMethods;
    use URI::file;

    my $methods = XML::CompileX::WSDL11::AsMethods->new(
        URI::file->new_abs('stockquote.wsdl') );
    $methods->export('My::StockQuote');

    my ($answer_ref, $trace) = My::StockQuote->GetLastTradePrice(
        body => {tickerSymbol => 'AAPL'} );

# DESCRIPTION

This module provides a mechanism for exporting the SOAP operations defined in
one or more WSDL/schema documents as regular Perl class methods that will then
call the appropriate web service. By default it exports these methods into
the current namespace when the `export` method is called; however you can
explicitly specify a different one either during construction or when calling
`export`.

# ATTRIBUTES

## uris

Either a URI string or [URI](https://metacpan.org/pod/URI) object, or a reference to an array of them.
These will be loaded as WSDL and XSD files that define the available SOAP
operations and their input and output parameters.

## namespace

The namespace of the Perl class into which the SOAP operations will be exported
as methods. Can be overridden when the `export` method is actually called.

## user\_agent

An instance of [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent) used to load the `uris` as
well as make SOAP calls. You may want to set this to your own instance of a
subclass or otherwise customized object to add caching, logging or
other features.

## use\_loader

Defaults to true, will use
[XML::CompileX::Schema::Loader](https://metacpan.org/pod/XML::CompileX::Schema::Loader) to collect all
imported documents from `uris`. You may want to unset this if you know there
are no imports or you are handling it some other way.

## wsdl

Use this optional attribute at construction time to specify your own
[XML::Compile::WSDL11](https://metacpan.org/pod/XML::Compile::WSDL11) object, perhaps after installing
hooks or other mechanisms for correcting issues with retrieved WSDL or schemas.

# METHODS

## export

When called, this method exports the operations defined by `uris` into either
the current namespace or one passed in as a string. These methods typically
take a hash of name-value pairs as arguments, and will return their results
as a hash reference and an
[XML::Compile::SOAP::Trace](https://metacpan.org/pod/XML::Compile::SOAP::Trace) object.

# SUPPORT

## Perldoc

You can find documentation for this module with the perldoc command.

    perldoc XML::CompileX::WSDL11::AsMethods

## Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

- MetaCPAN

    A modern, open-source CPAN search engine, useful to view POD in HTML format.

    [http://metacpan.org/release/XML-CompileX-WSDL11-AsMethods](http://metacpan.org/release/XML-CompileX-WSDL11-AsMethods)

- Search CPAN

    The default CPAN search engine, useful to view POD in HTML format.

    [http://search.cpan.org/dist/XML-CompileX-WSDL11-AsMethods](http://search.cpan.org/dist/XML-CompileX-WSDL11-AsMethods)

- AnnoCPAN

    The AnnoCPAN is a website that allows community annotations of Perl module documentation.

    [http://annocpan.org/dist/XML-CompileX-WSDL11-AsMethods](http://annocpan.org/dist/XML-CompileX-WSDL11-AsMethods)

- CPAN Ratings

    The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

    [http://cpanratings.perl.org/d/XML-CompileX-WSDL11-AsMethods](http://cpanratings.perl.org/d/XML-CompileX-WSDL11-AsMethods)

- CPAN Forum

    The CPAN Forum is a web forum for discussing Perl modules.

    [http://cpanforum.com/dist/XML-CompileX-WSDL11-AsMethods](http://cpanforum.com/dist/XML-CompileX-WSDL11-AsMethods)

- CPANTS

    The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

    [http://cpants.cpanauthors.org/dist/XML-CompileX-WSDL11-AsMethods](http://cpants.cpanauthors.org/dist/XML-CompileX-WSDL11-AsMethods)

- CPAN Testers

    The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

    [http://www.cpantesters.org/distro/X/XML-CompileX-WSDL11-AsMethods](http://www.cpantesters.org/distro/X/XML-CompileX-WSDL11-AsMethods)

- CPAN Testers Matrix

    The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

    [http://matrix.cpantesters.org/?dist=XML-CompileX-WSDL11-AsMethods](http://matrix.cpantesters.org/?dist=XML-CompileX-WSDL11-AsMethods)

- CPAN Testers Dependencies

    The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

    [http://deps.cpantesters.org/?module=XML::CompileX::WSDL11::AsMethods](http://deps.cpantesters.org/?module=XML::CompileX::WSDL11::AsMethods)

## Bugs / Feature Requests

Please report any bugs or feature requests through the web
interface at
[https://github.com/mjgardner/xml-compilex-wsdl11-asmethods/issues](https://github.com/mjgardner/xml-compilex-wsdl11-asmethods/issues).
You will be automatically notified of any progress on the
request by the system.

## Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

[https://github.com/mjgardner/xml-compilex-wsdl11-asmethods](https://github.com/mjgardner/xml-compilex-wsdl11-asmethods)

    git clone git://github.com/mjgardner/xml-compilex-wsdl11-asmethods.git

# AUTHOR

Mark Gardner <mjgardner@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by ZipRecruiter.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
