/*
 * Cappuccino frontend for apobank
 *
 * Created by daboe01 on Jul, 2016.
 * Copyright 2016, All rights reserved.
 *
 * todo:
 * 1. show sum of current selection via bindings (selection.@sum)
 *
 */

@import <Foundation/CPObject.j>
@import <Renaissance/Renaissance.j>
@import "TimelineView.j"

@implementation RightAlignedTextField : CPTextField

- (id)initWithFrame:(CGRect)aFrame {
    self = [super initWithFrame:aFrame];

    if (self) {
        [self setValue:CPRightTextAlignment forThemeAttribute:'alignment'];
    }

    return self;
}
-(void) setObjectValue:(id)aVal
{
    [super setObjectValue:[CPString stringWithFormat:"%5.2f", aVal]];
}
@end

@implementation GSMarkupTagRightAlignedTextField:GSMarkupTagControl
+ (Class) platformObjectClass
{
	return [RightAlignedTextField class];
}
@end

@implementation AppController : CPObject
{   id       store @accessors;    

	id       searchTerm @accessors;
    id       accountsController;
    id       transactionsController;

    CPWindow timelineWindow;
    id       timelineView;
}

- (void) applicationDidFinishLaunching:(CPNotification)aNotification
{
    store=[[FSStore alloc] initWithBaseURL:"/DBI"];
    [CPBundle loadRessourceNamed:"model.gsmarkup" owner:self];
    [CPBundle loadRessourceNamed:"gui.gsmarkup" owner:self];

    [timelineView setLaneKey:nil];
    [timelineView setTimeKey:'wertstellungstag'];
    [timelineView setValueKey:'betrag'];

    var myLane=[TLVTimeLane new];
    [myLane setHasVerticalRuler:YES];
    [myLane addStyleFlags:TLVLanePolygon|TLVLaneCircle];
    [timelineView addLane:myLane withIdentifier:nil];
}

-(void) setSearchTerm:(id)aTerm
{
	if(aTerm && aTerm.length)
	{   var term= aTerm.toLowerCase();
        [transactionsController setFilterPredicate:[CPPredicate predicateWithFormat:"description CONTAINS[cd] %@", term]];
	} else [transactionsController setFilterPredicate:nil];
}

-(void) openTimeline:(id)sender
{
    [timelineView bind:CPValueBinding toObject:transactionsController withKeyPath:'arrangedObjects' options:nil];
    [timelineWindow makeKeyAndOrderFront:self];
}


// number formatting
- (CPString)stringForObjectValue:(id)theObject
{	return [CPString stringWithFormat:"%.2f", parseFloat(theObject)];
}
- (id)objectValueForString:(CPString)aString error:(CPError)theError
{	return parseFloat(aString);
}

@end

