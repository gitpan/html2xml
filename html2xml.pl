#!/usr/bin/perl -w

$VERSION = '0.4';

#------------------------------------------------------------------------------
#
# Pod
#
#------------------------------------------------------------------------------

=head1 NAME

html2xml.pl - script for generating formatted XML from HTML

=head1 SYNOPSIS

    html2xml.pl <filename>
    cat <filename> | html2xml.pl

=head1 DESCRIPTION
This script was made to clean HTML documents in order to put data included in a XML native database.
Generated XML elements are :
<div>
<table>
<row>
<cell>
<url>
<list>
<item> 

<div> can be the BODY element or a DIV element
As everything, it's not a perfect script , so i will be pleased if you mail me bug you find.


Ce script est fait pour extraire les données "utiles" d'un document HTML, et les sauvegardes dans un document XML dont les éléments sont :
<div>
<table>
<row>
<cell>
<url>
<list>
<item> 

<div> comporte l'élément BODY ou les DIV du document HTML

Ce script n'est pas parfait et il est donc fort possible que vous en repériez un disfonctionnement. Je serai ravi que vous m'en faisiez part dans un courriel.




=head1 PREREQUISITES


HTML::TreeBuilder
Encode (included in Perl 5.8)
=head1 OSNAMES

any

=head1 AUTHOR

Francois Colombier E<lt>francois.colombier@free.fr<gt>
=head1 COPYRIGHT

This script is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SCRIPT CATEGORIES

Web

=cut

#------------------------------------------------------------------------------
#
# End of pod
#
#------------------------------------------------------------------------------

use strict;
require 5.004;

use HTML::TreeBuilder;
use Encode;

#------------------------------------------------------------------------------
#
# Public global varables
#
#------------------------------------------------------------------------------

use vars qw(
	    $html_tree
	    %equiv
	    );

#------------------------------------------------------------------------------
#
# set autoflushing
#
#------------------------------------------------------------------------------

$|++;

#------------------------------------------------------------------------------
#
# BEGIN block - create global objects
#
#------------------------------------------------------------------------------

BEGIN {
    $html_tree = new HTML::TreeBuilder;
    %equiv = ('&'=>"&amp;",
	      '<'=>"&lt;",
	      '>'=>"&gt;"
	      );
}


#------------------------------------------------------------------------------
#
# get_divs - routine for generating an array of divs from a given node
#
#------------------------------------------------------------------------------

sub get_divs
{
    my $this = shift;
    # array to save divs in
    my @divs = ();
       
    # iterate though my children ...
    foreach my $node_ref ($this->content_refs_list) 
    {
	if(ref $$node_ref)
	{
	    my $tag = $$node_ref->tag;
	    if ( $tag =~ /div/i )
	    {
		my @contenu=get_divs( $$node_ref );
		push @divs,"<div name=\"$tag\">";
		if(@contenu)
		{
		    push @divs,@contenu;
		    push @divs,"</div>";
		}
		else
		{
		    pop @divs;
		} 
	    }
	    elsif ($tag =~ /^table$/i )
	    {
		push @divs,"<table>";
		push @divs,get_tables($$node_ref );
		push @divs,"</table>";
		
	    }
	    elsif ($tag =~ /^(ol|ul|dl)$/i )
	    {

		push @divs,"<list>";
		push @divs,get_paragraphs($$node_ref );
		push @divs,"</list>";
	    }	    
	    elsif ($tag =~ /^p$/i )
	    {
		my @contenu=get_paragraphs($$node_ref );
		push @divs,"<p>";
		if(@contenu)
		{
		    if(@contenu != 1 
		       ||
		       (@contenu == 1
			&&
			$contenu[1] !~ /<br\/>/))
		    {
			push @divs,@contenu;
			push @divs,"</p>";
		    }
		    else
		    {
			pop @divs;   
		    }
		}
		else
		{
		    pop @divs;   
		}
	    }	    
	    elsif($tag !~ /^script$/i)
	    {
		push @divs,get_divs($$node_ref ) unless $tag =~ /<!--/;	
	    }
	}
	else
	{
	    my $contenu = $$node_ref;
	    $contenu =~ s/(&|<|>)/$equiv{$1}/g;
	    $contenu =~ s/\n/<br\/>/g;
	    push @divs,"<br/>".$contenu unless ($$node_ref !~ /\S/ or $$node_ref =~ /<!--/);  
	}
	
    }
    
    return @divs;
}

#------------------------------------------------------------------------------
#
# get_paragraphs - routine for generating an array of paras from a given node
#
#------------------------------------------------------------------------------

sub get_paragraphs
{
    my $this = shift;
    my @paras = ();
    
    foreach my $node_ref ($this->content_refs_list) 
    {
	if(ref $$node_ref)
	{
	    my $tag = $$node_ref->tag;
	    if ( $tag =~ /^(ol|ul|dl)$/i )
	    {
		push @paras,get_paragraphs($$node_ref);
		
	    }
	    if ( $tag =~ /^p$/i )
	    {
		push @paras,get_paragraphs($$node_ref);
	
	    }
	    else
	    {
		
		if ( $tag =~ /^(li|dt)/i )
		{
		    
		    push @paras,"<item>";
		    push @paras,get_paragraphs($$node_ref);
		    push @paras,"</item>";
		}
		
		elsif ($tag =~ /^dd/i )
		{
		    my @contenu=get_paragraphs($$node_ref);

		    push @paras,"<desc>";
		    if(@contenu)
		    {
			push @paras,@contenu;
			push @paras,"</desc>";
		    }
		    else
		    {
			pop @paras;
		    }
		    
		}
		elsif ($tag =~ /^a$/i )
		{
		    if(my $url = $$node_ref->attr('href'))
		    {
			if(!(length $url ==1))
			{
			    if($url =~ /^[hf]tt?p/)#!liens internes éliminés
			    {
				push @paras,"<url>";
			
				$url =~ s/&/&amp;/g;
				push @paras,"$url";
				push @paras,"</url>";
			    }
			}	
		    }
		    push @paras,get_paragraphs($$node_ref);
		    
		}
		elsif($tag !~ /^script$/i)
		{
		    push @paras,get_paragraphs($$node_ref) unless $tag =~ /<!--/;
		}
		
	    }
	}
	else
	{
	    my $contenu = $$node_ref;
	    $contenu =~ s/(&|<|>)/$equiv{$1}/g;
	    $contenu =~ s/\n/<br\/>/g;
	    push @paras, "<br/>".$contenu unless ($$node_ref !~ /\S/ or $$node_ref =~ /<!--/);
	}
    }
    return @paras;
}
#------------------------------------------------------------------------------
#
# get_tables - routine for generating an array of table (which is array or rows)
#              from a given node
#
#------------------------------------------------------------------------------

sub get_tables
{
    my $this = shift;
    my @tables = ();
    
   
    foreach my $node_ref ($this->content_refs_list) 
    {
	if (ref $$node_ref)
	{
	    my $tag = $$node_ref->tag;
	    if ( $tag =~ /^table$/i )
	    {
		push @tables,get_tables($$node_ref);
	    }
	    	    
	    elsif($tag =~ /^tr$/i )
	    {
		push @tables,"<row>";
		my @contenu = get_tables($$node_ref);
		if(@contenu)
		{
		    push @tables,@contenu;
		    push @tables,"</row>";
		}	
		else
		{
		    pop @tables;
		}
	
	    }
	    elsif($tag =~ /^td$/i )
	    {
		push @tables,"<cell>";
		my @contenu = get_tables($$node_ref);
		if(@contenu)
		{
		    push @tables,@contenu;
		    push @tables,"</cell>";
		}	
		else
		{
		    pop @tables;
		}
	    }
	    elsif($tag !~ /^script$/i)
	    {
		push @tables,get_divs($$node_ref) unless $tag =~ /<!--/ ; 
	    }
	    
	}
	else
	{
	    
	    my $contenu = $$node_ref;
	    $contenu =~ s/(&|<|>)/$equiv{$1}/g;
	    $contenu =~ s/\n/<br\/>/g;
	    push @tables, "<br/>".$contenu unless ($$node_ref =~ /<!--/ or $$node_ref !~ /\S/ or $$node_ref !~ /^\c.?$/);
	}
	
    }
return @tables;
}
#------------------------------------------------------------------------------
#
# Main
#
#------------------------------------------------------------------------------
my $input = join( '', <> );
my @doc=();
eval{
$html_tree->parse($input);
};

foreach my $node_ref ($html_tree->content_refs_list) 
{
    next if !ref $$node_ref;
    my $tag = $$node_ref->tag;
    if( $tag =~ /head/i )
    {
	foreach my $head_node_ref ($$node_ref->content_refs_list) 
	{
	    if(ref $$head_node_ref)
	    {
		$tag = $$head_node_ref->tag;
		if($tag =~ /^meta$/i)
		{
		 #qq chose d'interessant ?  
		}
		
	    }    
	}
    }
    elsif ( $tag =~ /body/i ||
	    $tag =~ /div/i)
    {
	push @doc,"<?xml version=\"1.0\" encoding=\"ISO-8859-1\" standalone=\"yes\"?>";
	push @doc,"<div name=\"$tag\">";
	
	if( my @div=get_divs($$node_ref))
	{
	    while(@div)
	    {
		my $line = shift(@div);
		utf8::decode($line);
	
		push @doc,$line;
	    }
	    
	}
	push @doc,"</div>"; 
	
    }   
    while (@doc)
    {
	my $ligne = shift(@doc);
	print $ligne;
    }
}  

