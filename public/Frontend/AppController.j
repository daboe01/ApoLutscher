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

@implementation AppController : CPObject
{   id  store @accessors;    

	id	searchTerm @accessors;
    id  accountsController;
    id  transactionsController;
}

- (void) applicationDidFinishLaunching:(CPNotification)aNotification
{
    store=[[FSStore alloc] initWithBaseURL:"/DBI"];
    [CPBundle loadRessourceNamed:"model.gsmarkup" owner:self];
    [CPBundle loadRessourceNamed:"gui.gsmarkup" owner:self];
}

-(void) setSearchTerm:(id)aTerm
{
	if(aTerm && aTerm.length)
	{   var term= aTerm.toLowerCase();
        [transactionsController setFilterPredicate:[CPPredicate predicateWithFormat:"description CONTAINS[cd] %@", term]];
	} else [transactionsController setFilterPredicate:nil];
}

// number formatting
- (CPString)stringForObjectValue:(id)theObject
{	return [CPString stringWithFormat:"%.2f", parseFloat(theObject)];
}
- (id)objectValueForString:(CPString)aString error:(CPError)theError
{	return parseFloat(aString);
}

@end

