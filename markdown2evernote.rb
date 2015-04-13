#!/usr/bin/ruby
# -*- coding: utf-8 -*-

###############################################################################
# markdown2evernote.rb - RubyCocoa edition - a version of markdown2evernote.rb
#
# $Source: /Users/dan/bin/RCS/markdown2evernote.rb-v $
# $Date: 2013-05-23 14:22:10-07 $
# $Revision: 1.2 $
#
###############################################################################

# Markdown to Evernote, RubyCocoa edition
# by Brian Gernhardt

# Adapted from Martin Kopichke's "Markdown to Evernote" service
#   https://gist.github.com/kopischke/1009149
# Which was adapted from Brett Terpstra’s original
#   http://brettterpstra.com/a-better-os-x-system-service-for-evernote-notes-with-multimarkdown/

# License: Creative Commons Attribution Share-Alike (CC BY-SA) 3.0 Unported 
#   http://creativecommons.org/licenses/by-sa/3.0/

# Changes:
# - RubyCocoa instead of shelling out to osascript
# - Separate metadata processing loop
# - Uses capturing regexes instead of manually substrings
# - Read/write contents in one call instead of line by line
# - Do not remove 1st level headers, just use first one as title
#   (Still no setext header processing though)

# Markdown executable path
# – edit to match your install location if non-default
# – pre-version 3 MMD script usually is '~/Application Support/MultiMarkDown/bin/MultiMarkDown.pl'
MARKDOWN = '/opt/local/bin/multimarkdown'
Process.exit unless File.executable?(MARKDOWN) 

# Smart typography (aka SmartyPants) switch
SMARTY = false
# – Smart typography processing via MARKDOWN extension
#   enable with '--smart' for PEG Markdown, disable using '--nosmart' in upcoming MMD version 3
SMARTY_EXT_ON  = '--smart'
SMARTY_EXT_OFF = '--nosmart'
# – Separate smart typography processor (i.e. SmartyPants.pl)
#   set to path to SmartyPants.pl (for classic Markdown and MMD pre-version 3, usually same dir as (Multi)MarkDown.pl)
#   set to '' to use SMARTY_EXT instead
SMARTY_PATH = ''
if SMARTY && !SMARTY_PATH.empty? then Process.exit unless File.executable?(SMARTY_PATH) end

# Whether or not to covert from style sheet to inline styles
INLINE = true
INLINE_PATH = '/Users/dan/bin/inline'
if INLINE && !INLINE_PATH.empty? then Process.exit unless File.executable?(INLINE_PATH) end

# utility function: enclose string in double quotes
def quote(str)
  "\"#{str}\""
end

# processed data
input    = []   # MMD input
contents = nil  # MMD output
title    = nil  # Note title
tags     = nil  # tag list (if given)
notebook = nil  # notebook name (if given)

# parse metadata
while true
  line = ARGF.readline
  case line
	# note title (either MMD metadata 'Title' – must occur before the first blank line – or atx style 1st level heading)
	when /^(Title:|#)\s(.*)$/
      title = $2.strip
	# note tags (either MMD metadata 'Keywords' or '@ <tag list>'; must occur before the first blank line)
	when /^(Keywords:|@)\s(.*)$/
	  tags = $2.split(',').map {|tag| tag.strip}
	# notebook (either MMD metadata 'Notebook' or '= <name>'; must occur before the first blank line)
	when /^(Notebook:|=)\s(.*)$/
	  notebook = $2.strip
	# Stop processing metadata on blank line
    when /^\s?$/
      input << line
      break
    # Pass through unknown metadata
    else
      input << line
  end
end
input << ARGF.read

# Grab first 1st level heading if we have no other title
if !title and input.any? {|s| s =~ /^#([^#]+)#?.*$/}
  title = $1.strip
end

# Markdown processing
mmd_cmd = quote MARKDOWN
if SMARTY_PATH
  mmd_cmd << ' ' + ( SMARTY ? SMARTY_EXT_ON : SMARTY_EXT_OFF )
else
  mmd_cmd << '|' + quote(SMARTY_PATH) if SMARTY
end

if INLINE_PATH
  mmd_cmd << ' | ' + quote(INLINE_PATH)
end

IO.popen(mmd_cmd, 'r+') do |io|
  io << input
  io.close_write
  contents = io.read
end

# create note, using localized date and time stamp as fallback for title
require 'osx/cocoa'

# Use OS X localization, since we're loading RubyCocoa anyway
unless title
  formatter = OSX::NSDateFormatter.alloc.init
  formatter.dateStyle = NSDateFormatterLongStyle
  formatter.timeStyle = NSDateFormatterShortStyle
  title = formatter.stringFromDate OSX::NSDate.alloc.init
end

# Send note to Evernote
OSX.require_framework 'ScriptingBridge'
evernote = OSX::SBApplication.applicationWithBundleIdentifier 'com.evernote.Evernote'
evernote.objc_send( # Sadly, we have to include *every* option...
                   :createNoteFromFile, nil,
                   :fromUrl,            nil,
                   :withText,           nil,
                   :withHtml,           contents,
                   :withEnml,           nil,
                   :title,              title,
                   :notebook,           notebook,
                   :tags,               tags,
                   :attachments,        nil,
                   :created,            nil
                  )
