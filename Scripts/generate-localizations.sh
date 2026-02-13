#!/bin/bash
set -e

XCSTRINGS_DIR="./App/Resources"
OUTPUT_DIR="./App/Resources/Language"
XCSTRINGS_TEMPLATE="./Stencils/XcStrings.stencil"
STRINGS_TEMPLATE="./Stencils/L10nStrings.stencil"
L10N_OUTPUT="./App/Sources/Generated/L10n.swift"

echo "Moin! Schaun wir ma was wir ein multilinguales Gelabber wir da haben in xcstrings catalog..."

# Check if xcstrings directory exists and has catalogs
if [ ! -d "$XCSTRINGS_DIR" ]; then
    echo "[!] Diggie, hier is'n Fehler: xcstrings Ordner nich da: $XCSTRINGS_DIR"
    echo "[!] International Härte, das war nur Fair hier zu stoppen"
    exit 1
fi

# Ensure expected catalogs are included explicitly (including Purchase.xcstrings)
REQUIRED_CATALOGS=(General TimeRecords Reporting Settings Management Export Purchase)
XCSTRINGS_FILES=()

for catalog in "${REQUIRED_CATALOGS[@]}"; do
    catalog_path="$XCSTRINGS_DIR/${catalog}.xcstrings"
    if [ -f "$catalog_path" ]; then
        XCSTRINGS_FILES+=("$catalog_path")
    else
        echo "[!] Warnung: Erwarteter Catalog fehlt: $catalog_path"
    fi
done

# Include any additional xcstrings catalogs in the folder
while IFS= read -r file; do
    already_listed=false
    for listed_file in "${XCSTRINGS_FILES[@]}"; do
        if [ "$listed_file" = "$file" ]; then
            already_listed=true
            break
        fi
    done
    if [ "$already_listed" = false ]; then
        XCSTRINGS_FILES+=("$file")
    fi
done < <(find "$XCSTRINGS_DIR" -maxdepth 1 -name "*.xcstrings" -type f | sort)

if [ "${#XCSTRINGS_FILES[@]}" -eq 0 ]; then
    echo "[!] Diggie, hier is'n Fehler: Keine xcstrings gefunden in: $XCSTRINGS_DIR"
    echo "[!] International Härte, das war nur Fair hier zu stoppen"
    exit 1
fi

# Extract all language codes from xcstrings, filter empty ones
XC_LANGUAGES=$(jq -s -r '.[].strings | .[]? | .localizations? | keys[]?' "${XCSTRINGS_FILES[@]}" | grep -v '^$' | sort -u)

# Ensure required languages are generated even if missing in xcstrings
REQUIRED_LANGUAGES=(de en es fr la pt ru ar da fi ja nb nl pl sv tr)
LANGUAGES=$(printf "%s\n" "${REQUIRED_LANGUAGES[@]}" $XC_LANGUAGES | awk 'NF' | sort -u | tr '\n' ' ')

if [ -z "$LANGUAGES" ]; then
    echo "[!] Diggie, hier is'n Fehler: Keien Sprache in xcstrings gefunden!"
    echo "[!] International Härte, das war nur Fair hier zu stoppen"
    exit 1
fi

echo "Hebbt wat funnen: $LANGUAGES"
echo ""

# Step 1: Generate .strings for each language
for lang in $LANGUAGES; do
    # Skip empty language codes
    if [ -z "$lang" ]; then
        continue
    fi
    
    LPROJ_DIR="$OUTPUT_DIR/${lang}.lproj"
    
    # Create lproj directory if it doesn't exist
    if [ ! -d "$LPROJ_DIR" ]; then
        echo "[+] Mache ${lang}.lproj Ornder..."
        mkdir -p "$LPROJ_DIR"
    fi
    
    echo "[>] Mach gerade ${lang}.lproj/Localizable.strings..."
    
    swiftgen run json "$XCSTRINGS_DIR" \
        --filter ".*(General|TimeRecords|Reporting|Settings|Management|Export|Purchase)\\.xcstrings$" \
        --templatePath "$XCSTRINGS_TEMPLATE" \
        --output "$LPROJ_DIR/Localizable.strings" \
        --param language="$lang"
done

echo ""
echo "[✓] Jo, all' .strings Datein sind auf dem Feld!"
echo ""

# Step 2: Generate L10n.swift from first language's .strings
FIRST_LANG="de"

if [ -z "$FIRST_LANG" ]; then
    echo "[!] Diggie, hier is'n Fehler: Keine Sprache gefunden! International Härte, das war nur Fair hier zu stoppen."
    exit 1
fi

echo "[>] Geht doch, nun die L10n.swift mit ${FIRST_LANG}.lproj..."

L10N_OUTPUT_DIR="$(dirname "$L10N_OUTPUT")"
if [ ! -d "$L10N_OUTPUT_DIR" ]; then
    mkdir -p "$L10N_OUTPUT_DIR"
fi

swiftgen run strings "$OUTPUT_DIR/${FIRST_LANG}.lproj/Localizable.strings" \
    --templatePath "$STRINGS_TEMPLATE" \
    --output "$L10N_OUTPUT"

echo ""
echo "[✓] L10n.swift is nu am Start! Isso Diggie."
echo ""
echo "[✓] Tschüss un dat hett passt!"
echo "    All Datein für multilinguales Gelabber sünd nu aus der Botanik im xCode angekommen."
echo ""
