# Plugin for Foswiki - The Free and Open Source Wiki, https://foswiki.org/
#
# TableOfContentsPlugin is Copyright (C) 2023-2024 Michael Daum http://michaeldaumconsulting.com
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

use HTML::TreeBuilder ();
use Foswiki::ListIterator ();
our @ISA = ('Foswiki::ListIterator');

=begin TML

---++ ClassMethod new($html) -> $iter

creates an heading iterator for the given piece of html

=cut

sub new {
  my ($class, $html) = @_;

  die "no html" unless defined $html;

  my $tree = HTML::TreeBuilder->new_from_content($html);

  my @list = $tree->look_down(
    sub {
      my $tag = $_[0]->tag() // '';
      my $class = $_[0]->attr("class") // '';
      my $id = $_[0]->attr("id");
      return $id && ($tag =~ /^h\d$/ || $class eq 'TOC2');
    }
  );

  my $this = $class->SUPER::new(\@list);

  $this->{tree} = $tree;

  return $this;
}

=begin TML

---++ ObjectMethod finish()

deletes the HTML::TreeBuilder delegate as well

=cut

sub finish {
  my $this = shift;

  $this->{tree}->delete if $this->{tree};
  undef $this->{tree};
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
