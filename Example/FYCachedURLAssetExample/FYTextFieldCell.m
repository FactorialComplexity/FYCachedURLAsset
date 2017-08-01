/*
 MIT License
 
 Copyright (c) 2015 Factorial Complexity
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 
 */

#import "FYTextFieldCell.h"

@implementation FYTextFieldCell {
    __weak IBOutlet UITextField *_textField;
	__weak IBOutlet UIButton *_addButton;
}

- (void)awakeFromNib {
	[super awakeFromNib];
	
	_textField.layer.borderColor = [[UIColor colorWithRed:232.0 / 255 green:232.0 / 255 blue:232.0 / 255 alpha:1] CGColor];
	_textField.layer.borderWidth = 1;
	
	_textField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 16, 0)];
	_textField.leftViewMode = UITextFieldViewModeAlways;
	
	[_addButton setTitleColor:[UIColor colorWithRed:75.0 / 255 green:90.0 / 255 blue:191.0 / 255 alpha:0.5] forState:UIControlStateDisabled];
	_addButton.enabled = NO;
}
    
#pragma mark - Dynamic Properties
    
- (void)setItem:(FYTextFieldItem *)item {
	_textItem = item;
	
    _textField.text = item.text;
    _textField.placeholder = item.placeholder;
}

- (IBAction)textChanged:(id)sender {
	_textItem.text = _textField.text;
	
	_addButton.enabled = _textField.text.length > 0;
}

- (IBAction)textDidEndOnExit:(id)sender {
	!_textAddedCallback ?: _textAddedCallback(_textField.text);
}

- (IBAction)addClicked:(id)sender {
	!_textAddedCallback ?: _textAddedCallback(_textField.text);
}

@end
