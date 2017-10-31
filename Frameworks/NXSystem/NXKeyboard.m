/*
  Class:               NXKeyboard
  Inherits from:       NSObject
  Class descritopn:    Keyboard configuration manipulation (type, rate, layouts)

  Copyright (C) 2017 Sergii Stoian <stoyan255@ukr.net>

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

#import "NXKeyboard.h"
#include <X11/XKBlib.h>
#include <X11/extensions/XKBrules.h>

NSString *InitialRepeat = @"NXKeyboardInitialKeyRepeat";
NSString *RepeatRate = @"NXKeyboardRepeatRate";
NSString *Layouts = @"NXKeyboardLayouts";
NSString *Variants = @"NXKeyboardVariants";
NSString *Model = @"NXKeyboardModel";
NSString *Options = @"NXKeyboardOptions";
NSString *SwitchLayout = @"SwitchLayoutKey";
NSString *Compose = @"ComposeKey";


@implementation NXKeyboard : NSObject

+ (void)configureWithDefaults:(NXDefaults *)defs
{
  NSInteger initialRepeat, repeatRate;
  NXKeyboard *keyb = [NXKeyboard new];
  
  if ((initialRepeat = [defs integerForKey:InitialRepeat]) < 0)
    initialRepeat = 0;
  if ((repeatRate = [defs integerForKey:RepeatRate]) < 0)
    repeatRate = 0;
  [keyb setInitialRepeat:initialRepeat rate:repeatRate];  
}

// Converts string like
// "us: English (US, alternative international)" into dictionary:
// {
//   Layout = us;
//   Language = English;
//   Description = "US, alternative international";
// }
- (NSDictionary *)_parseVariantString:(NSString *)value
{
  NSArray *comps;
  NSArray *layout;
  NSArray *language;
  NSArray *keys;
  NSMutableDictionary *dictionary;

  layout = [value componentsSeparatedByString:@": "];
  language = [[layout objectAtIndex:1] componentsSeparatedByString:@" ("];

  comps = [[NSArray arrayWithObject:[layout objectAtIndex:0]]
            arrayByAddingObjectsFromArray:language];

  // NSLog(@"Variant array: %@", comps);

  dictionary = [NSMutableDictionary dictionary];
  [dictionary setObject:[comps objectAtIndex:0] forKey:@"Layout"];
  if ([comps count] > 1)
    [dictionary setObject:[comps objectAtIndex:1] forKey:@"Language"];
  if ([comps count] > 2)
    [dictionary setObject:[[[comps objectAtIndex:2] componentsSeparatedByString:@")"] objectAtIndex:0]
                   forKey:@"Description"];
    
  return dictionary;
}

- (NSDictionary *)_xkbBaseListDictionary
{
  NSMutableDictionary	*dict = [[NSMutableDictionary alloc] init];
  NSMutableDictionary	*modeDict = [[NSMutableDictionary alloc] init];
  NSString		*baseLst;
  NSScanner		*scanner;
  NSString		*lineString = @" ";
  NSString		*sectionName;
  // NSString		*fileName;

  baseLst = [NSString stringWithContentsOfFile:XKB_BASE_LST];
  scanner = [NSScanner scannerWithString:baseLst];

  while ([scanner scanUpToString:@"\n" intoString:&lineString] == YES)
    {
      // New section start encountered
      if ([lineString characterAtIndex:0] == '!')
        {
          if ([[modeDict allKeys] count] > 0)
            {
              [dict setObject:[modeDict copy] forKey:sectionName];
              // fileName = [NSString
              //              stringWithFormat:@"/Users/me/Library/XKB_%@.list",
              //             sectionName];
              // [modeDict writeToFile:fileName atomically:YES];
              [modeDict removeAllObjects];
              [modeDict release];
              modeDict = [[NSMutableDictionary alloc] init];
            }
          
          sectionName = [lineString substringFromIndex:2];
          
          NSLog(@"Keyboard: found section: %@", sectionName);
        }
      else
        { // Parse line and add into 'modeDict' dictionary
          NSMutableArray	*lineComponents;
          NSString		*key;
          NSMutableString	*value = [[NSMutableString alloc] init];
          BOOL			add = NO;
          
          lineComponents = [[lineString componentsSeparatedByString:@" "]
                             mutableCopy];
          key = [lineComponents objectAtIndex:0];

          for (NSUInteger i = 1; i < [lineComponents count]; i++)
            {
              if (add == NO &&
                  ![[lineComponents objectAtIndex:i] isEqualToString:@""])
                {
                  add = YES;
                  [value appendFormat:@"%@", [lineComponents objectAtIndex:i]];
                }
              else if (add == YES)
                [value appendFormat:@" %@", [lineComponents objectAtIndex:i]];
            }

          // homophonic = {
          //   Layout = ua;
          //   Description = "Ukrainian (homophonic)";
          // }
          if ([sectionName isEqualToString:@"variant"])
            {
              [modeDict setObject:[self _parseVariantString:value] forKey:key];
            }
          else
            {
              [modeDict setObject:value forKey:key];
              [value release];
            }
          
          [lineComponents release];
        }
    }
  
  [dict setObject:[modeDict copy] forKey:sectionName];
  // fileName = [NSString stringWithFormat:@"/Users/me/Library/XKB_%@.list",
  //                      sectionName];
  // [modeDict writeToFile:fileName atomically:YES];
  [modeDict removeAllObjects];
  [modeDict release];

  [dict writeToFile:@"/Users/me/Library/Keyboards.list" atomically:YES];
  
  return [dict autorelease];
}

- (void)dealloc
{
  if (layoutDict)  [layoutDict release];
  if (modelDict)   [modelDict release];
  if (variantDict) [variantDict release];
  if (optionDict)  [optionDict release];

  [super dealloc];
}

- (NSDictionary *)modelList
{
  if (!modelDict)
    {
      modelDict = [[NSDictionary alloc]
                    initWithDictionary:[[self _xkbBaseListDictionary]
                                         objectForKey:@"model"]];
    }

  return modelDict;
}

// TODO
- (NSString *)model
{
  return nil;
}

// TODO
- (void)setModel:(NSString *)name
{
}

//
// Layout
// 
- (NSDictionary *)layoutList
{
  if (!layoutDict)
    {
      layoutDict = [[NSDictionary alloc]
                     initWithDictionary:[[self _xkbBaseListDictionary]
                                          objectForKey:@"layout"]];
    }

  return layoutDict;
}

// TODO
+ (NSDictionary *)currentServerConfig
{
  Display 		*dpy;
  char			*file = NULL;
  XkbRF_VarDefsRec	vd;
  NSMutableDictionary	*config = [NSMutableDictionary dictionary];

  dpy = XkbOpenDisplay(NULL, NULL, NULL, NULL, NULL, NULL);
  if (!XkbRF_GetNamesProp(dpy, &file, &vd) || !file)
    {
      NSLog(@"NXKeyboard: error reading XKB properties!");
      return nil;
    }

  NSLog(@"NXKeyboard Model: '%s'; Layouts: '%s'; Variants: '%s' Rules file: %s",
        vd.model, vd.layout, vd.variant, file);
  NSArray *layouts, *variants, *options;
  layouts = [[NSString stringWithCString:vd.layout]
              componentsSeparatedByString:@","];
  variants = [[NSString stringWithCString:vd.variant]
               componentsSeparatedByString:@","];
  options = [[NSString stringWithCString:vd.options]
              componentsSeparatedByString:@","];

  // NSUInteger lc = [layouts count];
  // NSUInteger vc = [variants count];
  // NSUInteger length = lc > vc  ? lc : vc;
  // NSString   *l, *v;
  // NSMutableDictionary *layoutConfig = [NSMutableDictionary dictionary];

  NSLog(@"NXKeyboard Layouts: %@", layouts);
  NSLog(@"NXKeyboard Variants: %@", variants);
  
  // for (NSUInteger i = 0; i < length; i++)
  //   {
  //     l = (i >= lc) ? @"" : [layouts objectAtIndex:i];
  //     v = (i >= vc) ? @"" : [variants objectAtIndex:i];
  //     [layoutConfig setObject:v forKey:l];
  //   }
  // [config setObject:layoutConfig forKey:@"NXKeyboardLayouts"];

  [config setObject:layouts forKey:Layouts];
  [config setObject:variants forKey:Variants];
  [config setObject:options forKey:Options];
  [config setObject:[NSString stringWithCString:vd.model] forKey:Model];
  
  [config writeToFile:@"/Users/me/Library/NXKeyboard" atomically:YES];
  
  return config;
}
// TODO
- (void)addLayout:(NSString *)name
{
}
// TODO
- (void)removeLayout:(NSString *)name
{
}
// TODO
- (void)setLayoutList:(NSArray *)layouts variants:(NSArray *)variants
{
}

- (NSString *)nameForLayout:(NSString *)layoutCode
{
  if (!layoutDict)
    {
      layoutDict = [[NSDictionary alloc]
                     initWithDictionary:[[self _xkbBaseListDictionary]
                                          objectForKey:@"layout"]];
    }

  return [layoutDict objectForKey:layoutCode];
}

- (NSDictionary *)variantListForKey:(NSString *)field
                              value:(NSString *)value
{
  NSMutableDictionary	*layoutVariants;
  NSDictionary		*variant;
    
  if (!variantDict)
    {
      variantDict = [[NSDictionary alloc]
                      initWithDictionary:[[self _xkbBaseListDictionary]
                                           objectForKey:@"variant"]];
    }

  layoutVariants = [[NSMutableDictionary alloc] init];
  for (NSString *key in [variantDict allKeys])
    {
      variant = [variantDict objectForKey:key];
      if ([[variant objectForKey:field] isEqualToString:value])
        {
          [layoutVariants setObject:variant forKey:key];
        }
    }

  return [layoutVariants autorelease];
}
  
- (NSDictionary *)variantListForLayout:(NSString *)layout
{
  return [self variantListForKey:@"Layout" value:layout];
}

- (NSDictionary *)variantListForLanguage:(NSString *)language
{
  return [self variantListForKey:@"Language" value:language];
}

//
// Initial Repeat and Repeat Rate
// 

- (void)_setXKBRepeat:(NSInteger)repeat rate:(NSInteger)rate
{
  XkbDescPtr xkb = XkbAllocKeyboard();
  Display    *dpy = XOpenDisplay(NULL);

  if (!dpy)
    {
      NSLog(@"Can't open Display! This program must be run in X Window System.");
      return;
    }
  if (!xkb)
    {
      NSLog(@"No X11 XKB extension found!");
      return;
    }
  
  XkbGetControls(dpy, XkbRepeatKeysMask, xkb);
  if (repeat)
    xkb->ctrls->repeat_delay = (int)repeat;
  if (rate)
    xkb->ctrls->repeat_interval = (int)rate;
  XkbSetControls(dpy, XkbRepeatKeysMask, xkb);
  
  XCloseDisplay(dpy);
}
- (XkbDescPtr)_xkbControls
{
  XkbDescPtr xkb = XkbAllocKeyboard();
  Display    *dpy = XOpenDisplay(NULL);

  if (!dpy)
    {
      NSLog(@"Can't open Display! This program must be run in X Window System.");
      return NULL;
    }
  if (!xkb)
    {
      NSLog(@"No X11 XKB extension found!");
      return NULL;
    }
  
  XkbGetControls(dpy, XkbRepeatKeysMask, xkb);
  XCloseDisplay(dpy);

  return xkb;
}

- (NSInteger)initialRepeat
{
  return [self _xkbControls]->ctrls->repeat_delay;
}
- (void)setInitialRepeat:(NSInteger)delay
{
  [self _setXKBRepeat:delay rate:0];
}
- (NSInteger)repeatRate
{
  return [self _xkbControls]->ctrls->repeat_interval;
}
- (void)setRepeatRate:(NSInteger)rate
{
  [self _setXKBRepeat:0 rate:rate];
}
- (void)setInitialRepeat:(NSInteger)delay rate:(NSInteger)rate
{
  [self _setXKBRepeat:delay rate:rate];
}

@end
