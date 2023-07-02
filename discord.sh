#!/bin/sh

node_archive()
{
    node_address="https://nodejs.org/dist/v18.16.1/node-v18.16.1-linux-x64.tar.xz"
    node_archive="$directory/$(basename "$node_address")"

    if [ ! -f "$node_archive" ]
    then
        if ! wget --quiet --no-check-certificate --output-document "$node_archive" "$node_address"
        then
            echo "Error: Cannot download node archive."
            exit
        fi
    fi
}

node_directory()
{
    node_directory="$directory/node"

    if [ ! -d "$node_directory" ]
    then
        mkdir "$node_directory"

        if ! tar --extract --file "$node_archive" --directory "$node_directory" --strip-components 1
        then
            echo "Error: Cannot extract node archive."
            exit
        fi
    fi
}

node_packages()
{
    PATH="$node_directory/bin:$PATH"

    if ! npm install -g asar 1> /dev/null 2> /dev/null
    then
        echo "Error: Cannot install node packages."
        exit
    fi
}

core_archive()
{
    core_archive="$1"

    if [ ! -f "$core_archive" ]
    then
        echo "Error: Cannot read core archive."
        exit
    fi
}

core_directory()
{
    core_directory="$directory/$core_archive-extracted"

    if [ ! -d "$core_directory" ]
    then
        if ! asar extract "$core_archive" "$core_directory" 1> /dev/null 2> /dev/null
        then
            echo "Error: Cannot extract core archive."
            exit
        fi
    fi
}

core_file()
{
    core_file="$core_directory/app/mainScreen.js"

    if [ ! -f "$core_file" ]
    then
        echo "Error: Cannot read core file."
        exit
    fi
}

core_file_line()
{
    core_file_line="$(grep -n "mainWindow.webContents.setWindowOpenHandler" "$core_file")"

    if [ -z "$core_file_line" ]
    then
        echo "Error: Cannot find core file line."
        exit
    fi
}

core_file_line_number()
{
    core_file_line_number="$(echo "$core_file_line" | awk -F ':' '{ print $1 }')"
    core_file_line_number="$(($core_file_line_number - 1))"

    if [ -z "$core_file_line_number" ]
    then
        echo "Error: Cannot read core file line number."
        exit
    fi
}

core_file_insertion()
{
    core_file_insertion="$1"

	cat <<- EOF | sed -i "$core_file_line_number r /dev/stdin" "$core_file"
		const fs = require('fs');
		const content = fs.readFileSync('$core_file_insertion', 'UTF-8');
		mainWindow.webContents.on('dom-ready', () => {
			mainWindow.webContents.executeJavaScript(content);
		});
	EOF
}

core_archive_new()
{
    if ! asar pack "$core_directory" "$core_archive"
    then
        echo "Error: Cannot pack core archive."
        exit
    fi
}

main()
{
    directory="$(pwd)"

    if [ "$#" -ne 2 ]
    then
        echo "Usage: $0 <core> <script>"
        exit
    fi

    node_archive
    node_directory
    node_packages
    core_archive "$1"
    core_directory
    core_file
    core_file_line
    core_file_line_number
    core_file_insertion "$2"
    core_archive_new
}

main "$@"
