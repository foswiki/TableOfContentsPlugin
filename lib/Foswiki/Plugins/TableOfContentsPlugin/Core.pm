# Plugin for Foswiki - The Free and Open Source Wiki, https://foswiki.org/
#
# TableOfContentsPlugin is Copyright (C) 2017-2026 Michael Daum http://michaeldaumconsulting.com
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

package Foswiki::Plugins::TableOfContentsPlugin::Core;

=begin TML

---+ package Foswiki::Plugins::TableOfContentsPlugin::Core

core class for this plugin

an singleton instance is allocated on demand

=cut

use strict;
use warnings;

use Foswiki::Func ();
use Foswiki::Plugins::TableOfContentsPlugin::HeadingIterator ();

use constant TRACE => 0; # toggle me

=begin TML

---++ ClassMethod new() -> $core

constructor for a Core object

=cut

sub new {
  my $class = shift;

  my $this = bless({
    @_
  }, $class);

  return $this;
}

=begin TML

---++ ObjectMethod finish()

make sure all sub-objects are destroyed as well

=cut

sub finish {
  my $this = shift;

  $this->{iterator}->finish() if $this->{iterator};
  undef $this->{iterator};
}

=begin TML

---++ ObjectMethod iterator($html) -> $iter

returns a Foswiki::Plgins::TableOfContentsPlugin::HeadingIterator to return an iterator
over all headings contained in the given html

=cut

sub iterator {
  my ($this, $html) = @_;

  _writeDebug("called iterator()");
  $this->{iterator} //= Foswiki::Plugins::TableOfContentsPlugin::HeadingIterator->new($html);
  return $this->{iterator};
}

=begin TML

---++ ObjectMethod TOC($session, $params) -> $html

implements the TOC/TOC2 macro. this basically only inserts a placeholder
for the toc being generated when the full page is available completeley.

=cut

sub TOC {
  my ($this, $session, $params) = @_;

  _writeDebug("called TOC()");
  my $id = $this->{id}++;
  _writeDebug("toc id=$id");
  return "\0<span class='TOC2' id='toc_$id'><literal>".$params->stringify()."</literal></span>\0";
}

=begin TML

---++ ObjectMethod beforeCommonTagsHandler($text)

escape no-toc headings 

=cut

sub beforeCommonTagsHandler {
  my $this = shift;

  $_[0] =~ s/($Foswiki::regex{headerPatternNoTOC})/$1\0NOTOC2\0/g;
}

=begin TML

---++ ObjectMethod completePageHandler($text)

clean up html and compute the TOC 

=cut

sub completePageHandler {
  my $this = shift;
  #my $html = $_[0];

  _writeDebug("called completePageHandler()");
  # clean up HTML
  $_[0] =~ s/<p>\s*(?:<br \/>)*\s*(<div .*?[^\/]>)<\/p>/$1/g;
  $_[0] =~ s/\0<span class='TOC2' id='(toc_\d+)'>(.*?)<\/span>\0/$this->handleTOC($1, $2, $_[0])/ge;
  $_[0] =~ s/\0NOTOC2\0//g;
}

=begin TML

---++ ObjectMethod handleTOC($id, $attrs, $html) -> $html

computes the TOC as found by the  completePageHandler

=cut

sub handleTOC {
  my ($this, $tocId, $attrs, $html) = @_;

  _writeDebug("called handleToc($tocId)");
  #_writeDebug("html=$html");

  my %params = Foswiki::Func::extractParameters($attrs);
  my $topic = $params{_DEFAULT};
  my $format = $params{format} // '   $indent* <a href="$params$anchor">$text</a>';
  my $header = $params{header} // '';
  my $separator = $params{separator} // "\n";
  my $footer = $params{footer} // '';
  my $depth = $params{depth} // 0;
  my $title = $params{title} // '';
  my $pattern = $params{pattern};
  my $isGlobal = Foswiki::Func::isTrue($params{global}) ? 1:0;

  _writeDebug("... isGlobal=$isGlobal");

  return "<span class='foswikiAlert'>ERROR: cannot render TOC of topic <nop>$topic, sorry</span>"
    if $topic;

  my $request = Foswiki::Func::getRequestObject();
  my $params = $request->query_string() || '';
  $params = "?$params" if $params;

  # fetch toc items
  my $start;
  my @items = ();
  my $it = $this->iterator($html);
  $it->reset if $isGlobal;
  my $startLevel;

  while ($it->hasNext()) {
    my $elem = $it->next();
    my $class = $elem->{class} // "";
    my $id = $elem->{id} // "";

    if ($class eq 'TOC2') {
      _writeDebug("... found TOC");
      if ($start && !$isGlobal) {
        $it->skip(-1);
        _writeDebug("... shortcutting this TOC ");
        last;
      }
      $start = $elem if $id eq $tocId || $isGlobal;
      next;
    }
    _writeDebug("... no start found yet") unless $start;
    next unless $start;

    my $text = $elem->{text};
    _writeDebug("... text=$text");

    if ($text =~ /\0NOTOC2\0/) {
      _writeDebug("NOTOC detected");
      next;
    }

    if ($pattern && $text =~ /$pattern/) {
      $text = $1 // $text;
    }
    next if $text eq '';

    my $level = $elem->{level};
    $startLevel //= $level;
    _writeDebug("... depth=$depth, startLevel=$startLevel, level=$level");
    next if $depth && $level > $depth;

    if ($level < $startLevel) {
      $it->skip(-1);
      last;
    }
    _writeDebug("... adding ".Encode::encode_utf8($text));

    push @items, {
      id => $elem->{id},
      level => $level,
      text => $text,
    };
  }
  $it->reset() if $isGlobal;

  return "" unless @items;

  # normalize level
  my $minLevel = 99999;
  foreach my $item (@items) {
    $minLevel = $item->{level} if $minLevel > $item->{level};
  }
  foreach my $item (@items) {
    $item->{level} -= $minLevel;
  }

  # create output
  my @lines = ();
  push @lines, "<span class='foswikiTocTitle'>$title</span>" if $title ne "";
  push @lines, "<div class='foswikiToc'><noautolink>";

  foreach my $item (@items) {
    my $indent = "   " x $item->{level};
    my $line = $format; 
    $line =~ s/\$indent/$indent/g;
    $line =~ s/\$params/$params/g;
    $line =~ s/\$anchor/#$item->{id}/g;
    $line =~ s/\$text/$item->{text}/g;
    push @lines, $line;
  }
  push @lines, "</noautolink></div>";

  my $result = Foswiki::Func::decodeFormatTokens($header.join($separator, @lines).$footer);
  return Foswiki::Func::renderText($result);
}

# statics
sub _writeDebug {
  return unless TRACE;
  print STDERR "TableOfContentsPlugin::Core - $_[0]\n";
}

1;
