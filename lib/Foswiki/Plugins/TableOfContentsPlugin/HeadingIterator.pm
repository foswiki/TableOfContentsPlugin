# Plugin for Foswiki - The Free and Open Source Wiki, https://foswiki.org/
#
# TableOfContentsPlugin is Copyright (C) 2023-2026 Michael Daum http://michaeldaumconsulting.com
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details, published at
# http://www.gnu.org/copyleft/gpl.html

package Foswiki::Plugins::TableOfContentsPlugin::HeadingIterator;

=begin TML

---+ package Foswiki::Plugins::TableOfContentsPlugin::HeadingIterator

returns an iterator for all headings contained in a given html fragment

=cut

use strict;
use warnings;

use Foswiki::ListIterator ();
our @ISA = ('Foswiki::ListIterator');

=begin TML

---++ ClassMethod new($html) -> $iter

creates an heading iterator for the given piece of html

=cut

sub new {
  my ($class, $html) = @_;

  die "no html" unless defined $html;

  my $this = $class->SUPER::new();

  $this->parse($html);

  return $this;
}

sub parse {
  my ($this, $html) = @_;

  my @list;

  while ($html =~ /(?:<(h)(\d)(?:.*?id=['"](.*?)["'][^>]*?)?>(.*?)<\/h\2>)|(?:<(span)\s+class='TOC2'\s+id='(toc_\d+)'>.*?<\/span>)/gi) {
    my $tag = lc($1 // $5);
    if ($tag eq 'h') {
      my $level = $2;
      my $id = $3;
      my $text = $4;

      next unless $id;

      while ($text =~ s/<(\w+)\s+[^>]*?>(.*?)<\/\1>/$2/g) {
        # nop
      }

      $text =~ s/^\s+//;
      $text =~ s/\s+$//;

      push @list, {
        tag => $tag,
        id => $id,
        level => $level,
        text => $text,
      };
    } 

    if ($tag eq 'span') {
      my $id = $6;

      push @list, {
        tag => $tag,
        id => $id,
        class => "TOC2",
      };
    }
  }

  $this->{list} = \@list;
}

=begin TML

---++ ObjectMethod finish()

=cut

sub finish {
  my $this = shift;

  undef $this->{list};
}

=begin TML

---++ ObjectMethod skip($count) -> $countRemaining

skips a certain amount of headings, negative skips are allowed
as well, returns the number of remaining headings

=cut

sub skip {
  my ($this, $count) = @_;

  if ($count < 0) {
    $count = $this->{index} + $count;
    $this->reset();
  }

  return $this->SUPER::skip($count);
}

1;
