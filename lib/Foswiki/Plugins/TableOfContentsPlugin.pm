# Plugin for Foswiki - The Free and Open Source Wiki, https://foswiki.org/
#
# TableOfContentsPlugin is Copyright (C) 2017-2024 Michael Daum http://michaeldaumconsulting.com
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

package Foswiki::Plugins::TableOfContentsPlugin;

=begin TML

---+ package Foswiki::Plugins::TableOfContentsPlugin

base class to hook into the foswiki core

=cut

use strict;
use warnings;

use Foswiki::Func ();

our $VERSION = '1.00';
our $RELEASE = '%$RELEASE%';
our $SHORTDESCRIPTION = 'Yet another TOC plugin';
our $LICENSECODE = '%$LICENSECODE%';
our $NO_PREFS_IN_TOPIC = 1;
our $core;

=begin TML

---++ initPlugin($topic, $web, $user) -> $boolean

initialize the plugin, automatically called during the core initialization process

=cut

sub initPlugin {

  Foswiki::Func::registerTagHandler("TOC2", sub { return getCore()->TOC(@_); });
  Foswiki::Func::registerTagHandler("TOC", sub { return getCore()->TOC(@_); }) 
    if $Foswiki::cfg{TableOfContentsPlugin}{ReplaceOriginalTOC};

  return 1;
}

=begin TML

---++ beforeCommonTagsHandler($text)

escape headings that aren't supposed to be included into the TOC

=cut

sub beforeCommonTagsHandler {
  return getCore()->beforeCommonTagsHandler(@_);
}

=begin TML

---++ ObjectMethod completePageHandler($text)

inserts the TOC

=cut

sub completePageHandler {
  return getCore()->completePageHandler(@_);
}


=begin TML

---++ getCore() -> $core

returns a singleton Foswiki::Plugins::TableOfContentsPlugin::Core object for this plugin

=cut

sub getCore {
  unless (defined $core) {
    require Foswiki::Plugins::TableOfContentsPlugin::Core;
    $core = Foswiki::Plugins::TableOfContentsPlugin::Core->new();
  }
  return $core;
}

=begin TML

---++ finishPlugin

finish the plugin and the core if it has been used

=cut

sub finishPlugin {
  undef $core;
}

1;
