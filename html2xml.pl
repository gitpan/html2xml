#!/usr/bin/perl -w

$VERSION = '0.5';

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
<p>
<row>
<cell>
<url>
<list>
<item> 
<br/>

<div> can be the BODY element or a DIV element
As everything, it's not a perfect script , so i will be pleased if you mail me bug you find.


Ce script est fait pour extraire les données "utiles" d'un document HTML, et les sauvegardes dans un document XML dont les éléments sont :
<div>
<table>
<p>
<row>
<cell>
<url>
<list>
<item> 
<br/>

<div> comporte l'élément BODY ou les DIV du document HTML

Ce script n'est pas parfait et il est donc fort possible que vous en repériez un disfonctionnement. Je serai ravi que vous m'en faisiez part dans un courriel.




=head1 PREREQUISITES


HTML::TreeBuilder
Encode (included in Perl 5.8)
=head1 OSNAMES

any

=head1 AUTHOR

Francois Colombier E<lt>francois.colombier@free.frE<gt>

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
	    elsif($tag !~ /^img/i &&
		  $tag !~ /^br/i)
	    {
		my @contenu=get_paragraphs($$node_ref);
		if(@contenu)
		{
		    push @divs,"<$tag>";
		    push @divs,@contenu;
		    push @divs,"</$tag>";
		}	
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
	    if($tag !~ /^a$/i &&
	       $tag !~ /^img$/i)
	    {
		my @contenu=get_paragraphs($$node_ref);
		if(@contenu)
		{
		    my $balise="";
		    if ( $tag =~ /^(ol|ul|dl)$/i )
		    {
			$balise="list";
		    }
		    
		    else
		    {
			
			if ( $tag =~ /^(li|dt)/i )
			{
			    $balise="item";
			}
			
			elsif ($tag =~ /^dd/i )
			{
			    $balise="desc";
			   			    
			}
			elsif ($tag =~ /^tr/i )
			{
			    $balise="row";
			   			    
			}
			elsif ($tag =~ /^td/i )
			{
			    $balise="cell";
			   			    
			}
			if($balise eq "")
			{
			    $balise=$tag;	
			}
		
		    }
		    if($balise !~ /^b$/i &&
		       $balise !~ /^font$/i)
		    {
			push @paras,"<$balise>";
			push @paras,@contenu;
			push @paras,"</$balise>";
		    }
		    else
		    {
			push @paras,@contenu;
		    }
		}

	    }
	    elsif($tag =~ /^a$/i)
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

