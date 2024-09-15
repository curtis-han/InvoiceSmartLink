#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Filename: ocr_mac.py
Description: 识别一个发票的内容，读取发票的金额和日期
Author: [TangPing.co]
Date: [2024-09-15]
Version: [V0.1]
Dependencies: [T.B.D]
"""
import os
import sys
import subprocess
import argparse
import common


def OCR_MAC(file_path, lang, dpi):
    """
    Perform OCR (Optical Character Recognition) on the given file.
    
    Args:
        file_path (str): The path to the file to be processed.
        lang (str): The language code for OCR recognition. Use "ja" for Japanese, "en" for English.
        dpi (int): The DPI (dots per inch) of the file.
    
    Returns:
        str: The recognized text from the file.
    
    Raises:
        subprocess.CalledProcessError: If the OCR process encounters an error.
    
    Example:
        result = OCR("/path/to/file.pdf", "en", 300)
        print(result)
    """

    script = '''
    use framework "Quartz"
    use framework "Vision"
    global CA, request
    set CA to current application
    set request to CA's VNRecognizeTextRequest's alloc's init
    request's setRecognitionLevel:(CA's VNRequestTextRecognitionLevelAccurate)
    request's setUsesLanguageCorrection:true
    on ocrPDF(filePath, dpi)
        set doc to CA's PDFDocument's alloc's initWithURL:(CA's NSURL's fileURLWithPath:filePath)
        set pageCount to doc's pageCount
        set resultTexts to CA's NSMutableArray's new()
        repeat with i from 1 to pageCount
            set scaleFactor to (dpi / (72.0 * (CA's NSScreen's mainScreen's backingScaleFactor)))
            set pdfImageRep to (CA's NSPDFImageRep's imageRepWithData:((doc's pageAtIndex:(i - 1))'s dataRepresentation))
            set originalSize to pdfImageRep's |bounds|
            set originalWidth to CA's NSWidth(originalSize)
            set originalHeight to CA's NSHeight(originalSize)
            set scaledSize to CA's NSMakeSize(originalWidth * scaleFactor, originalHeight * scaleFactor)
            set targetRect to CA's NSMakeRect(0, 0, scaledSize's width, scaledSize's height)
            set image to (CA's NSImage's alloc's initWithSize:(targetRect's item 2))
            image's lockFocus()
            CA's NSColor's whiteColor's |set|()
            (CA's NSBezierPath's fillRect:targetRect)
            (pdfImageRep's drawInRect:targetRect)
            image's unlockFocus()
            set tiff to image's TIFFRepresentation
            set ocrText to my ocrTIFF(tiff)
            (resultTexts's addObject:ocrText)
        end repeat
        return (resultTexts's componentsJoinedByString:linefeed) as text
    end ocrPDF
    on ocrImage(filePath)
        set scaleFactor to CA's NSScreen's mainScreen's backingScaleFactor
        set bitmapImageRep to (CA's NSBitmapImageRep's imageRepWithData:((CA's NSImage's alloc's initWithContentsOfFile:(filePath))'s TIFFRepresentation))
        set srcSize to CA's NSMakeSize((bitmapImageRep's pixelsWide as real) / scaleFactor, (bitmapImageRep's pixelsHigh as real) / scaleFactor)
        set srcImage to (CA's NSImage's alloc's initWithSize:srcSize)
        srcImage's addRepresentation:bitmapImageRep
        set newImage to (CA's NSImage's alloc's initWithSize:srcSize)
        set targetRect to CA's NSMakeRect(0, 0, srcSize's width, srcSize's height)
        newImage's lockFocus()
        CA's NSColor's whiteColor's |set|()
        (CA's NSBezierPath's fillRect:targetRect)
        (srcImage's drawInRect:targetRect)
        newImage's unlockFocus()
        set tiff to newImage's TIFFRepresentation
        return my ocrTIFF(tiff)
    end ocrImage
    on ocrTIFF(tiff)
        set resultTexts to CA's NSMutableArray's new()
        set requestHandler to (CA's VNImageRequestHandler's alloc's initWithData:tiff options:(missing value))
        (requestHandler's performRequests:[request] |error|:(missing value))
        set results to request's results()
        repeat with aResult in results
            (resultTexts's addObject:(((aResult's topCandidates:1)'s objectAtIndex:0)'s |string|()))
        end repeat
        return (resultTexts's componentsJoinedByString:linefeed) as text
    end ocrTIFF
    on ocr(filePath, lang, dpi)
        if lang is "ja" then
            request's setRecognitionLanguages:["ja", "en"]
        else
            request's setRecognitionLanguages:["en"]
        end if
        set pathExtension to ((CA's NSString's stringWithString:filePath)'s pathExtension as text)
        if pathExtension is "pdf" then
            my ocrPDF(filePath, dpi)
        else
            my ocrImage(filePath)
        end if
    end ocr
    my ocr("{file_path}", "{lang}", {dpi})
    '''.format(file_path=file_path, lang=lang, dpi=dpi)
    
    result = subprocess.run(['osascript', '-e', script], capture_output=True, text=True)
    return result.stdout

def parse_arguments():
    parser = argparse.ArgumentParser(description='OCR script')
    parser.add_argument('--lang', default='ja', help='Set OCR language (ja/en)')
    parser.add_argument('--dpi', type=int, default=200, help='Set DPI value for PDF rasterization')
    parser.add_argument('inputs', nargs='+', help='Input files')
    
    args = parser.parse_args()
    
    if not args.inputs:
        print("script.py: too few arguments", file=sys.stderr)
        print("Try 'script.py --help' for more information.", file=sys.stderr)
        sys.exit(1)
    
    return args


def recognize_text(image_path, lang='ja', dpi=200):
            """
            Recognizes text from an image using OCR_MAC.

            Args:
                image_path (str): The path to the image file.
                lang (str, optional): The language of the text in the image. Defaults to 'ja'.
                dpi (int, optional): The resolution of the image in dots per inch. Defaults to 200.

            Returns:
                str: The recognized text from the image.
            """
            result = OCR_MAC(common.realpath(image_path), lang, dpi)
            return result



def main():
    args = parse_arguments()
    
    for file in args.inputs:
        result = OCR_MAC(common.realpath(file), args.lang, args.dpi)
        print(result)

if __name__ == "__main__":
    main()
