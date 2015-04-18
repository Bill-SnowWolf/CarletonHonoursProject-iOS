//
//  FormViewController.m
//  CustomerServiceClient
//
//  Created by Xingnan Zhou on 2015-04-17.
//  Copyright (c) 2015 SnowWolf. All rights reserved.
//

#import "FormViewController.h"
#import "AudioCallViewController.h"

@interface FormViewController ()
@property (nonatomic) IBOutlet UITextField *nameTextField;
@property (nonatomic) IBOutlet UITextField *phoneTextField;
@property (nonatomic) IBOutlet UITextField *emailTextField;
@property (nonatomic) IBOutlet UITextView *commentsTextView;

- (IBAction)submit:(id)sender;
@end

@implementation FormViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)submit:(id)sender {
    NSDictionary *data = @{
                           @"name": self.nameTextField.text,
                           @"phone": self.phoneTextField.text,
                           @"email": self.emailTextField.text,
                           @"comments": self.commentsTextView.text
                           };
    
    AudioCallViewController *viewController = [[AudioCallViewController alloc] initWithCustomerData:data];
    [self.navigationController pushViewController:viewController animated:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
