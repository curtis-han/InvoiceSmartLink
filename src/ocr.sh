#!/bin/bash
SCRIPTNAME=$(basename "$0")

function realpath () {
  f=$@;
  if [ -d "$f" ]; then
    base="";
    dir="$f";
  else
    base="/$(basename "$f")";
    dir=$(dirname "$f");
  fi;
  dir=$(cd "$dir" && /bin/pwd);
  echo "$dir$base"
}

function OCR () {
    /usr/bin/osascript \
        -e 'use framework "Quartz"' \
        -e 'use framework "Vision"' \
        -e "global CA, request" \
        -e "set CA to current application" \
        -e "set request to CA's VNRecognizeTextRequest's alloc's init" \
        -e "request's setRecognitionLevel:(CA's VNRequestTextRecognitionLevelAccurate)" \
        -e "request's setUsesLanguageCorrection:true" \
        -e "on ocrPDF(filePath, dpi)" \
        -e "set doc to CA's PDFDocument's alloc's initWithURL:(CA's NSURL's fileURLWithPath:filePath)" \
        -e "set pageCount to doc's pageCount" \
        -e "set resultTexts to CA's NSMutableArray's new()" \
        -e "repeat with i from 1 to pageCount" \
        -e "set scaleFactor to (dpi / (72.0 * (CA's NSScreen's mainScreen's backingScaleFactor)))" \
        -e "set pdfImageRep to (CA's NSPDFImageRep's imageRepWithData:((doc's pageAtIndex:(i - 1))'s dataRepresentation))" \
        -e "set originalSize to pdfImageRep's |bounds|" \
        -e "set originalWidth to CA's NSWidth(originalSize)" \
        -e "set originalHeight to CA's NSHeight(originalSize)" \
        -e "set scaledSize to CA's NSMakeSize(originalWidth * scaleFactor, originalHeight * scaleFactor)" \
        -e "set targetRect to CA's NSMakeRect(0, 0, scaledSize's width, scaledSize's height)" \
        -e "set image to (CA's NSImage's alloc's initWithSize:(targetRect's item 2))" \
        -e "image's lockFocus()" \
        -e "CA's NSColor's whiteColor's |set|()" \
        -e "(CA's NSBezierPath's fillRect:targetRect)" \
        -e "(pdfImageRep's drawInRect:targetRect)" \
        -e "image's unlockFocus()" \
        -e "set tiff to image's TIFFRepresentation" \
        -e "set ocrText to my ocrTIFF(tiff)" \
        -e "(resultTexts's addObject:ocrText)" \
        -e "end repeat" \
        -e "return (resultTexts's componentsJoinedByString:linefeed) as text" \
        -e "end ocrPDF" \
        -e "on ocrImage(filePath)" \
        -e "set scaleFactor to CA's NSScreen's mainScreen's backingScaleFactor" \
        -e "set bitmapImageRep to (CA's NSBitmapImageRep's imageRepWithData:((CA's NSImage's alloc's initWithContentsOfFile:(filePath))'s TIFFRepresentation))" \
        -e "set srcSize to CA's NSMakeSize((bitmapImageRep's pixelsWide as real) / scaleFactor, (bitmapImageRep's pixelsHigh as real) / scaleFactor)" \
        -e "set srcImage to (CA's NSImage's alloc's initWithSize:srcSize)" \
        -e "srcImage's addRepresentation:bitmapImageRep" \
        -e "set newImage to (CA's NSImage's alloc's initWithSize:srcSize)" \
        -e "set targetRect to CA's NSMakeRect(0, 0, srcSize's width, srcSize's height)" \
        -e "newImage's lockFocus()" \
        -e "CA's NSColor's whiteColor's |set|()" \
        -e "(CA's NSBezierPath's fillRect:targetRect)" \
        -e "(srcImage's drawInRect:targetRect)" \
        -e "newImage's unlockFocus()" \
        -e "set tiff to newImage's TIFFRepresentation" \
        -e "return my ocrTIFF(tiff)" \
        -e "end ocrImage" \
        -e "on ocrTIFF(tiff)" \
        -e "set resultTexts to CA's NSMutableArray's new()" \
        -e "set requestHandler to (CA's VNImageRequestHandler's alloc's initWithData:tiff options:(missing value))" \
        -e "(requestHandler's performRequests:[request] |error|:(missing value))" \
        -e "set results to request's results()" \
        -e "repeat with aResult in results" \
        -e "(resultTexts's addObject:(((aResult's topCandidates:1)'s objectAtIndex:0)'s |string|()))" \
        -e "end repeat" \
        -e "return (resultTexts's componentsJoinedByString:linefeed) as text" \
        -e "end ocrTIFF" \
        -e "on ocr(filePath, lang, dpi)" \
        -e 'if lang is "ja" then' \
        -e "request's setRecognitionLanguages:[\"ja\", \"en\"]" \
        -e "else" \
        -e "request's setRecognitionLanguages:[\"en\"]" \
        -e "end if" \
        -e "set pathExtension to ((CA's NSString's stringWithString:filePath)'s pathExtension as text)" \
        -e 'if pathExtension is "pdf" then' \
        -e "my ocrPDF(filePath, dpi)" \
        -e "else" \
        -e "my ocrImage(filePath)" \
        -e "end if" \
        -e "end ocr" \
        -e "my ocr(\"$1\", \"$2\", $3)" 
}

function usage() {
    echo "Usage: $SCRIPTNAME [--lang <LANG>] [--dpi <VALUE>] <input1> <input2> ..."
    echo
    echo "Input file types: pdf/jpg/png"
    echo "Options:"
    echo "  -h, --help      Show help"
    echo "  --lang <LANG>   Set OCR language (ja/en) (default: ja)"
    echo "  --dpi <VALUE>   Set DPI value for PDF rasterization (default: 200)"
    echo
}

# parse arguments
declare -a args=("$@")
declare -a params=()

LANG=ja
DPI=200

I=0
while [ $I -lt ${#args[@]} ]; do
    OPT="${args[$I]}"
    case $OPT in
        -h | --help )
            usage
            exit 0
            ;;
        --lang )
            if [[ -z "${args[$(($I+1))]}" ]]; then
                echo "$SCRIPTNAME: option requires an argument -- $OPT" 1>&2
                exit 1
            fi
            LANG="${args[$(($I+1))]}"
            I=$(($I+1))
            ;;
        --dpi )
            if [[ -z "${args[$(($I+1))]}" ]]; then
                echo "$SCRIPTNAME: option requires an argument -- $OPT" 1>&2
                exit 1
            fi
            DPI="${args[$(($I+1))]}"
            I=$(($I+1))
            ;;
        -- | -)
            I=$(($I+1))
            while [ $I -lt ${#args[@]} ]; do
                params+=("${args[$I]}")
                I=$(($I+1))
            done
            break
            ;;
        -*)
            echo "$SCRIPTNAME: illegal option -- '$(echo $OPT | sed 's/^-*//')'" 1>&2
            exit 1
            ;;
        *)
            if [[ ! -z "$OPT" ]] && [[ ! "$OPT" =~ ^-+ ]]; then
                params+=( "$OPT" )
            fi
            ;;
    esac
    I=$(($I+1))
done

# handle invalid arguments
if [ ${#params[@]} -eq 0 ]; then
    echo "$SCRIPTNAME: too few arguments" 1>&2
    echo "Try '$SCRIPTNAME --help' for more information." 1>&2
    exit 1
fi

for FILE in "${params[@]}"; do
    OCR "$(realpath $FILE)" $LANG $DPI
done