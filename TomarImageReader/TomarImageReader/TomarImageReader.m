//
//  TomarImageReader.h
//  TomarImageReader
//
//  Created by Prabhat Singh on 12/16/16.
//  Copyright © 2016 Prabhat Singh Tomar. All rights reserved.
//

#import "TomarImageReader.h"
#import <TesseractOCR/TesseractOCR.h>

@implementation TomarImageReader

- (void) performRecognitionWithImage:(UIImage*)image {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        G8Tesseract* tesseract = [[G8Tesseract alloc] initWithLanguage:@"eng"];
        tesseract.language = @"eng";
        tesseract.engineMode = G8OCREngineModeTesseractCubeCombined;
        tesseract.pageSegmentationMode = G8PageSegmentationModeAuto;
        tesseract.maximumRecognitionTime = 60.0;
        tesseract.image = [image g8_blackAndWhite];
        BOOL recognized = [tesseract recognize];
        if (recognized == YES) {
            NSDictionary*array = [self parseValidLines:tesseract.recognizedText];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate sucessWithText:array];
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate failedTextReader:nil];
            });
        }
    });
}

-(NSDictionary*) parseValidLines:(NSString*)text {
    NSMutableArray* lines = [text componentsSeparatedByString:@"\n"].mutableCopy;
    NSMutableArray *array = [NSMutableArray array];
    int index = 0;
    for (NSString* text in lines) {
        if ([text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0) {
            [array addObject:[NSNumber numberWithInt:index]];
        }else if ([self isValidText:text] == NO) {
            [array addObject:[NSNumber numberWithInt:index]];
        }
        index++;
    }
    for (int i = array.count-1; i>=0; i--) {
        [lines removeObjectAtIndex:[array[i] intValue]];
    }
    return [self recognizeLines:lines];
}

-(BOOL) isValidText:(NSString*) text {
    int length = text.length;
    NSCharacterSet * set = [NSCharacterSet characterSetWithCharactersInString:@"\"\\!@#$%^&*()-_=+/[]{},.?<>`~:; "];
    text = [[text componentsSeparatedByCharactersInSet:set] componentsJoinedByString: @""];
    if (text.length < 3 || length/2 > text.length) return NO;
    return YES;
}

-(NSDictionary*) recognizeLines:(NSMutableArray*) array {
    NSMutableArray *email = [NSMutableArray array];
    NSMutableArray *website = [NSMutableArray array];
    NSMutableArray *address = [NSMutableArray array];
    NSMutableArray *designation = [self getDesignation:array];
    if (designation == nil ){ designation = [NSMutableArray array]; }
    for (NSString* text in designation) { [array removeObject:text]; }
    NSMutableArray *names = [self getNames:array];
    for (NSString* text in names) { [array removeObject:text]; }
    NSMutableArray *numbers = [self getTelephone:array];
    if (numbers == nil ){ numbers = [NSMutableArray array]; }
    for (NSString* text in numbers) { [array removeObject:text]; }
    
    for (NSString* text in array) {
        if ([text rangeOfString:@"@"].location != NSNotFound && [text rangeOfString:@"."].location != NSNotFound) {
            [email addObject:[self getEmail:text]];
        }else if ([text rangeOfString:@"www."].location != NSNotFound) {
            [website addObject:[self getWebsite:text]];
            continue;
        }
        [address addObject:text];
    }
    return @{@"name":names, @"email":email, @"contact":numbers, @"website":website, @"designation":designation, @"others":address};
    
}

-(NSMutableArray *) getNames:(NSArray*) array {
    NSMutableArray *names = [NSMutableArray array];
    NSCharacterSet * set = [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ "];
    for (NSString*text in array) {
        if ([text rangeOfCharacterFromSet:[set invertedSet]].location == NSNotFound) {
            [names addObject:text];
        }
    }
    return names;
}


-(NSString*) getWebsite:(NSString*) text {
    NSArray*array = [text componentsSeparatedByString:@" "];
    for (NSString* string in array) {
        if ([string rangeOfString:@"www."].location != NSNotFound) {
            return string;
        }
    }
    return nil;
}

-(NSString*) getEmail:(NSString*) text {
    NSArray*array = [text componentsSeparatedByString:@" "];
    for (NSString* string in array) {
        if ([string rangeOfString:@"@"].location != NSNotFound) {
            return string;
        }
    }
    return nil;
}

-(NSMutableArray*) getTelephone:(NSArray*) array {
    NSMutableArray* all = [NSMutableArray array];
    for (NSString* string in array) {
        if ([string rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location == NSNotFound) continue;
        NSError *error;
        NSDataDetector* detector = [[NSDataDetector alloc] initWithTypes:NSTextCheckingTypePhoneNumber error:&error];
        NSArray* matches = [detector matchesInString:string options:nil range:NSMakeRange(0, string.length)];
        if (matches.count > 0) {
            NSTextCheckingResult* result = matches[0];
            [all addObject:[string substringWithRange:result.range]];
        }
    }
    return all;
}

/*-(NSString*) getContact:(NSString*) text {
    int length = text.length;
    BOOL isComma = [text containsString:@","];
    NSCharacterSet * set = [NSCharacterSet characterSetWithCharactersInString:@"0123456789+-() "];
    text = [[text componentsSeparatedByCharactersInSet:[set invertedSet]] componentsJoinedByString:@""];
    text = [text stringByReplacingOccurrencesOfString:@"()" withString:@""];
    text = [text stringByReplacingOccurrencesOfString:@"--" withString:@"-"];
    text = [text stringByReplacingOccurrencesOfString:@"  " withString:@" "];
    if ([text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length < 4 || [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length > 15) {
        return  nil;
    }
    if (isComma && text.length < length/2) {
        return  nil;
    }
    return text;
}*/

-(NSMutableArray*) getDesignation:(NSArray*) array {
    NSArray* designations = @[@"manager", @"engineer", @"president", @"associate", @"director", @"consultant"
                               ,@"inspector",@"coordinator",@"superintendent",
                              @"supervisor",@"administrator",@"operator"
                              ,@"technician"];
    NSMutableArray* all = [NSMutableArray array];
    for (NSString* string in array) {
        for (NSString* position in designations) {
            if ([[string lowercaseString] rangeOfString:position].location != NSNotFound) {
                [all addObject:[self identifyDesignationIn:string position:position]];
                break;
            }
        }
    }
    return all;
}

-(NSString*) identifyDesignationIn:(NSString*) string position:(NSString*)position {
    NSArray * all = [string componentsSeparatedByString:@"  "];
    for (NSString* designation in all) {
        if ([[designation lowercaseString] rangeOfString:position].location != NSNotFound) {
            return designation;
        }
    }
    return nil;
}



@end
