#!/bin/bash

set -euxo pipefail

TESTCASE=""

assert_ret ()
{
	RET="$1"
	EXPECTED="$2"

	if [ "$RET" -ne "$EXPECTED" ]
	then
		echo "Return code invalid! Expected '${EXPECTED}', actual:'${RET}', testcase:'${TESTCASE}'"
		exit 2
	fi
}

assert_file_exists ()
{
	if [ ! -f "$1" ]
	then
		echo "File not found: $1. testcase:'${TESTCASE}'"
		exit 3
	fi
}

assert_expected_and_actual_pdf ()
{
	FILEPDFEXPECTED="$1"
	FILEPDFACTUAL="$2"

	if [ -f $FILEPDFEXPECTED ]
	then
		# compare returns 0 when should return 1??? grep kludge to do the assert as retval having issues
		compare -verbose -metric AE $FILEPDFEXPECTED $FILEPDFACTUAL null: 2>/tmp/compareoutput || assert_ret $? 0
		cat /tmp/compareoutput
		grep "all: 0" /tmp/compareoutput || assert_ret $? 0
	else
		echo "Expected PDF $FILEPDFEXPECTED not found. Will not attempt document comparison."
	fi	
}

create_pdf ()
{
	FILEMD="$1"
	TEMPLATETYPE="$2"
	REPORTLANGUAGE="$3"

	assert_file_exists $FILEMD

	FILEPDF="${FILEMD}_actual_${TEMPLATETYPE}_${REPORTLANGUAGE}.pdf"
	FILEPDFEXPECTED="${FILEMD}_expected_${TEMPLATETYPE}_${REPORTLANGUAGE}.pdf"

	# Ensure that PDF conversion completes successfully
	pandoc --verbose --from markdown --template hhtemplate.tex --filter pandoc-tablenos --filter pandoc-fignos --filter pandoc-citeproc --pdf-engine=xelatex --listings --variable=hhdocumentfont:FreeSans -o $FILEPDF $FILEMD --variable=hhtemplatetype:$TEMPLATETYPE --variable=hhreportlanguage:$REPORTLANGUAGE || assert_ret $? 0

	assert_file_exists $FILEPDF

	assert_expected_and_actual_pdf $FILEPDFEXPECTED $FILEPDF
}

assert_md_template_processing ()
{
	FILE="$1"
	TESTCASE=$FILE

	create_pdf $FILE short finnish
	create_pdf $FILE short english

	create_pdf $FILE long finnish
	create_pdf $FILE long english

	create_pdf $FILE thesis finnish
	create_pdf $FILE thesis english

	echo TEST CASE $TESTCASE SUCCESS
}

shopt -s globstar

# NOTE: repo's README.md is duplicated to case directory
#       to prevent GitHub status badge volatility

for FILE in cases/**/*.md
do
	assert_md_template_processing "$FILE"
done

