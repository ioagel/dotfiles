#!/usr/bin/env bash

# --------- get_raw_variable_value ---------
# This function extracts the value of a variable from a string.
# It removes the optional 'export ' prefix and the variable name and '=' (up to the first '=')
# It then removes leading/trailing double quotes if they both exist
# It then removes leading/trailing single quotes if they both exist
# It then returns the value of the variable

# --- Example Usage ---
# You can uncomment these lines to test the function in your shell:
# line1='export MY_VAR="Hello World"'
# line2='OTHER_VAR=\'Another value with spaces\''
# line3='SIMPLE_VAR=NoQuotesAroundValue'
# line4='export EQ_VAR="value=with=equals"'
# line5='QUOTED_EQ_VAR=\'another=val=with=equals\''
# line6='NO_QUOTE_EQ_VAR=val=without=quotes'
# line7='EMPTY_VAL_DQ="val"' # Variable name is EMPTY_VAL_DQ, value is "val"
# line8='export EMPTY_VAL_SQ=\'val\''
# line9='export VAR_WITH_NO_VALUE=' # Value is empty string
# line10='VAR_WITH_NO_VALUE_NO_EXPORT=' # Value is empty string
# line11='MALFORMED_VAR' # No '=' sign
# line12='export TRICKY="  spaced value with internal \"quotes\"  "'

# echo "Input: '$line1' -> Output: '$(get_raw_variable_value "$line1")'"
# echo "Input: '$line2' -> Output: '$(get_raw_variable_value "$line2")'"
# echo "Input: '$line3' -> Output: '$(get_raw_variable_value "$line3")'"
# echo "Input: '$line4' -> Output: '$(get_raw_variable_value "$line4")'"
# echo "Input: '$line5' -> Output: '$(get_raw_variable_value "$line5")'"
# echo "Input: '$line6' -> Output: '$(get_raw_variable_value "$line6")'"
# echo "Input: '$line7' -> Output: '$(get_raw_variable_value "$line7")'" # Should be "val"
# echo "Input: '$line8' -> Output: '$(get_raw_variable_value "$line8")'" # Should be "val"
# echo "Input: '$line9' -> Output: '$(get_raw_variable_value "$line9")'" # Should be empty
# echo "Input: '$line10' -> Output: '$(get_raw_variable_value "$line10")'" # Should be empty
# echo "Input: '$line11' -> Output: '$(get_raw_variable_value "$line11")'" # Should be empty
# echo "Input: '$line12' -> Output: '$(get_raw_variable_value "$line12")'" # Should be "  spaced value with internal \"quotes\"  " (inner quotes preserved)

get_raw_variable_value() {
    local input_string="$1"
    local value

    # 1. Remove optional 'export ' prefix
    #    Uses shell parameter expansion: ${string#substring_to_remove_from_start}
    if [[ "$input_string" == "export "* ]]; then
        value="${input_string#export }"
    else
        value="$input_string"
    fi

    # 2. Remove variable name and '=' (up to the first '=')
    #    Ensures that if the value itself contains '=', it's preserved.
    #    Uses shell parameter expansion: ${string#pattern_to_remove_from_start}
    #    The '*' in '*=' greedily matches the variable name.
    if [[ "$value" == *"="* ]]; then
        value="${value#*=}"
    else
        # If there's no '=', we can't determine a value part,
        # or the input format is unexpected.
        # Depending on desired behavior, you could echo "" or an error,
        # or echo the reminder of 'value' if that makes sense for other use cases.
        # For this specific request, if no '=', assume no value to extract according to format.
        echo ""
        return
    fi

    # 3. Remove leading/trailing double quotes if they both exist
    if [[ "$value" == \"*\" && "$value" == *\" ]]; then
        value="${value#\"}" # Remove leading "
        value="${value%\"}" # Remove trailing "
    fi

    # 4. Remove leading/trailing single quotes if they both exist
    #    This is done *after* double quotes in case of weird nesting,
    #    though typical shell assignments wouldn't have mixed matched quotes like 'foo"
    if [[ "$value" == \'*\' && "$value" == *\' ]]; then
        value="${value#\'}" # Remove leading '
        value="${value%\'}" # Remove trailing '
    fi

    echo "$value"
}

# --------- clean_config_file ---------
# This function removes comment lines starting with # or // or ; (and any leading whitespace before the comment)
# and removes empty lines from a config file.
# It then returns the cleaned config file.
clean_config_file() {
    if [ -z "$1" ]; then
        echo "Usage: clean_config_file <filepath>"
        return 1
    fi

    if [ ! -f "$1" ]; then
        echo "Error: File not found - $1"
        return 1
    fi

    # 1. Remove lines starting with # (and any leading whitespace before #)
    # 2. Remove lines starting with // (and any leading whitespace before //)
    # 3. Remove lines starting with ; (and any leading whitespace before ;)
    # 4. Remove empty lines
    sed -e 's/^[[:space:]]*#.*//' -e 's%^[[:space:]]*//.*%%' -e 's/^[[:space:]]*;.*//' -e '/^[[:space:]]*$/d' "$1"
}

# --------- generate_config_file ---------
# Function to generate a configuration file from a template using envsubst
# and a custom cleaning function.
#
# Usage: generate_config_file <vars_to_substitute> <template_file> <target_file> <temp_prefix> <comment_char> <script_name>
#
# Arguments:
#   $1: vars_to_substitute       - String of variables for envsubst (e.g., '$VAR1 $VAR2')
#   $2: template_file            - Path to the template file
#   $3: target_file              - Path to the output configuration file
#   $4: comment_char             - Character(s) to use for comments in the header (e.g., "#" or "//")
#   $5: script_name              - The name of the calling script (for the autogenerated header)
#
generate_config_file() {
    local vars_to_substitute="$1"
    local template_file="$2"
    local target_file="$3"
    local comment_char="$4"
    local script_name="$5" # Basename of the script calling this function

    local temp_envsubst_output_file="/tmp/${script_name}.envsubst.tmp"
    local temp_cleaned_body_file="/tmp/${script_name}.cleaned_body.tmp"

    # Ensure script_name is provided
    if [ -z "$script_name" ]; then
        echo "Error (generate_config_file): Script name not provided for header." >&2
        return 1 # Or handle error as appropriate
    fi

    log "Generating '$target_file' from '$template_file' using envsubst..."

    if [ ! -f "$template_file" ]; then
        warning "Template file not found: $template_file. Skipping generation of $target_file."
        return 1
    fi

    if [ -n "$vars_to_substitute" ]; then
        # Substitute variables
        envsubst "$vars_to_substitute" <"$template_file" >"$temp_envsubst_output_file"
        # Clean the envsubst output
        # Assuming clean_config_file is available and outputs to stdout
        clean_config_file "$temp_envsubst_output_file" >"$temp_cleaned_body_file"

        # Write the autogenerated header to the target file (overwrite)
        echo "${comment_char} AUTOGENERATED by ${script_name}, DO NOT EDIT MANUALLY" >"$target_file"
        echo "${comment_char} Instead, edit the template file: $template_file" >>"$target_file"

        # Append the cleaned body to the target file
        cat "$temp_cleaned_body_file" >>"$target_file"

        rm -f "$temp_envsubst_output_file" # Clean up first temp file
        rm -f "$temp_cleaned_body_file"    # Clean up second temp file

        log "'$target_file' generated successfully."
    else
        warning "No variables provided for envsubst for '$template_file'. Appending template content without substitution."
        # Write the autogenerated header
        echo "${comment_char} AUTOGENERATED by ${script_name} (template copied, no vars substituted), DO NOT EDIT MANUALLY" >"$target_file"
        echo "${comment_char} Instead, edit the template file: $template_file" >>"$target_file"
        # Append the original template content if no variables are to be substituted
        cat "$template_file" >>"$target_file"
        log "Appended template to output as no variables were identified for substitution."
    fi
}
