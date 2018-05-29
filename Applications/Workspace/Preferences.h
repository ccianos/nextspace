/*
   Preferences.h
   The preferences panel controller.

   Copyright (C) 2005 Saso Kiselkov

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#import <AppKit/AppKit.h>

#import "Protocols/PrefsModule.h"

@interface Preferences : NSObject
{
  id box;
  id panel;
  id popup;

  NSDictionary * prefs;
}

+ shared;
- (void)loadModules;
- (void) activate;

- (void) switchModule: (id)sender;

@end
