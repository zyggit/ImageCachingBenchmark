//
//  BPTMCacheViewController.m
//
//  Copyright (c) 2014 Bogdan Poplauschi
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

#import "BPTMCacheViewController.h"
#import <TMCache.h>

static CGFloat totalRetrieveTimeFromDisk        = 0.0f;
static NSInteger numberOfRetrievesFromDisk      = 0;

static CGFloat totalRetrieveTimeFromMemory      = 0.0f;
static NSInteger numberOfRetrievesFromMemory    = 0;

static CGFloat totalRetrieveTimeFromWeb         = 0.0f;
static NSInteger numberOfRetrievesFromWeb       = 0;

@interface BPTMCacheViewController ()

@end

@implementation BPTMCacheViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"TMCache";
    }
    return self;
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    BPTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kBPCellID];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%d %d", indexPath.section, indexPath.row];
    NSURL *url = [self imageUrlForIndexPath:indexPath];
    cell.imageUrl = url;
    cell.customImageView.image = nil;
        
    NSDate *initialDate = [NSDate date];
    __weak typeof(cell)weakCell = cell;
    
    [[TMCache sharedCache] objectForKey:[url absoluteString] block:^(TMCache *cache, NSString *key, id object, TMCacheType cacheType) {
        __strong typeof(weakCell)strongCell = weakCell;
        
        if (object) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([strongCell.imageUrl isEqual:url]) {
                    strongCell.customImageView.image = object;
                    
                    CGFloat retrieveTime = [[NSDate date] timeIntervalSinceDate:initialDate];
                    switch (cacheType) {
                        case TMCacheTypeDisk:
                            numberOfRetrievesFromDisk ++;
                            totalRetrieveTimeFromDisk += retrieveTime;
                            NSLog(@"[TMCache][Disk Cache] - retrieved image in %.4f seconds. Average is %.4f", retrieveTime, totalRetrieveTimeFromDisk/numberOfRetrievesFromDisk);
                            break;
                        case TMCacheTypeMemory:
                            numberOfRetrievesFromMemory ++;
                            totalRetrieveTimeFromMemory += retrieveTime;
                            NSLog(@"[TMCache][Memory Cache] - retrieved image in %.4f seconds. Average is %.4f", retrieveTime, totalRetrieveTimeFromMemory/numberOfRetrievesFromMemory);
                            break;
                        default:
                            break;
                    }
                }
            });
            return;
        }
        
        NSURLResponse *response = nil;
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
        
        UIImage *image = [[UIImage alloc] initWithData:data scale:[[UIScreen mainScreen] scale]];
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakCell)strongCell = weakCell;
            
            if ([strongCell.imageUrl isEqual:url]) {
                strongCell.customImageView.image = image;
                
                CGFloat retrieveTime = [[NSDate date] timeIntervalSinceDate:initialDate];
                numberOfRetrievesFromWeb ++;
                totalRetrieveTimeFromWeb += retrieveTime;
                NSLog(@"[TMCache][Web] - retrieved image in %.4f seconds. Average is %.4f", retrieveTime, totalRetrieveTimeFromWeb/numberOfRetrievesFromWeb);
            }
        });
        
        [[TMCache sharedCache] setObject:image forKey:[url absoluteString]];
    }];
    return cell;
}

@end
