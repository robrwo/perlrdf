# RDF::SPARQLResults::Graph
# -------------
# $Revision $
# $Date $
# -----------------------------------------------------------------------------

=head1 NAME

RDF::SPARQLResults::Graph - Stream (iterator) class for graph query results.

=head1 SYNOPSIS

    use RDF::SPARQLResults;
    my $query	= RDF::Query->new( '...query...' );
    my $stream	= $query->execute();
    while (my $row = $stream->next) {
    	my @vars	= @$row;
    	# do something with @vars
    }

=head1 METHODS

=over 4

=cut

package RDF::SPARQLResults::Graph;

use strict;
use warnings;
use JSON;
use List::Util qw(max);

use base qw(RDF::SPARQLResults);
our ($REVISION, $VERSION, $debug);
use constant DEBUG	=> 0;
BEGIN {
	$debug		= DEBUG;
	$REVISION	= do { my $REV = (qw$Revision: 293 $)[1]; sprintf("%0.3f", 1 + ($REV/1000)) };
	$VERSION	= '1.000';
}

=item C<new ( \@results, %args )>

=item C<new ( \&results, %args )>

Returns a new SPARQL Result interator object. Results must be either
an reference to an array containing results or a CODE reference that
acts as an iterator, returning successive items when called, and
returning undef when the iterator is exhausted.

$type should be one of: bindings, boolean, graph.

=cut

sub new {
	my $class		= shift;
	my $stream		= shift || sub { undef };
	my %args		= @_;
	
	my $type		= 'graph';
	return $class->SUPER::new( $stream, $type, [], %args );
}

=item C<as_xml ( $max_size )>

Returns an XML serialization of the stream data.

=cut

sub as_xml {
	my $self			= shift;
	my $max_result_size	= shift || 0;
	my $bridge			= $self->_bridge;
	
	my $count	= 0;
	my $xml		= <<"END";
<?xml version="1.0" encoding="utf-8"?>
<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
END
	while (my $stmt = $self->next) {
		if ($max_result_size) {
			last if ($count++ >= $max_result_size);
		}
		my $p		= $bridge->uri_value( $bridge->predicate( $stmt ) );
		my $pos		= max( rindex( $p, '/' ), rindex( $p, '#' ) );
		my $ns		= substr($p,0,$pos+1);
		my $local	= substr($p, $pos+1);
		my $subject	= $bridge->subject( $stmt );
		my $subjstr	= ($bridge->is_resource( $subject ))
					? 'rdf:about="' . $bridge->uri_value( $subject ) . '"'
					: 'rdf:nodeID="' . $bridge->blank_identifier( $subject ) . '"';
		my $object	= $bridge->object( $stmt );
		
		$xml		.= qq[<rdf:Description $subjstr>\n];
		if ($bridge->is_resource( $object )) {
			my $uri	= $bridge->uri_value( $object );
			$xml	.= qq[\t<${local} xmlns="${ns}" rdf:resource="$uri"/>\n];
		} elsif ($bridge->is_blank( $object )) {
			my $id	= $bridge->blank_identifier( $object );
			$xml	.= qq[\t<${local} xmlns="${ns}" rdf:nodeID="$id"/>\n];
		} else {
			my $value	= $bridge->literal_value( $object );
			# escape < and & and ' and " and >
			$value	=~ s/&/&amp;/g;
			$value	=~ s/'/&apos;/g;
			$value	=~ s/"/&quot;/g;
			$value	=~ s/</&lt;/g;
			$value	=~ s/>/&gt;/g;
			
			my $tag		= qq[${local} xmlns="${ns}"];
			if (defined($bridge->literal_value_language( $object ))) {
				my $lang	= $bridge->literal_value_language( $object );
				$tag	.= qq[ xml:lang="${lang}"];
			} elsif (defined($bridge->literal_datatype( $object ))) {
				my $dt	= $bridge->literal_datatype( $object );
				$tag	.= qq[ rdf:datatype="${dt}"];
			}
			$xml	.= qq[\t<${tag}>${value}</${local}>\n];
		}
		$xml		.= qq[</rdf:Description>\n];
	}
	$xml	.= "</rdf:RDF>\n";
	return $xml;
}

=item C<as_json ( $max_size )>

Returns a JSON serialization of the stream data.

=cut

sub as_json {
	my $self			= shift;
	my $max_result_size	= shift || 0;
	throw RDF::Query::Error::SerializationError ( -text => 'There is no JSON serialization specified for graph query results' );
}

1;

__END__

=back

=head1 DEPENDENCIES

L<JSON|JSON>

L<Scalar::Util|Scalar::Util>


=head1 AUTHOR

Gregory Todd Williams  C<< <greg@evilfunhouse.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Gregory Todd Williams C<< <gwilliams@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


