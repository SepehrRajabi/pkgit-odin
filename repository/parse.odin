package repository

import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:slice"
import "core:strings"
import "core:text/regex"

Package :: struct {
	name:          string,
	url:           string,
	build_command: string,
}

File_Error :: enum {
	nil,
	Unsupported_Extension,
	File_Not_Found,
	Reading_File,
	Parsing_File,
	Empty_File,
}


is_package_name_valid :: proc(name: string) -> bool {
	name := strings.trim_space(name)
	if len(name) < 3 || !is_ascii_letters(name) {
		fmt.println("Invalid package name:", name)
		return false
	}
	return true
}

validate_package :: proc(pkg: ^Package) -> bool {
	if !is_package_name_valid(pkg.name) {
		return false
	}

	url_regex := initialize_url_regex()
	_, success := regex.match(url_regex, pkg.url)
	if !success {
		fmt.printfln("Invalid URL: %s", pkg.url)
		return false
	}

	if pkg.name == "" {
		parts := strings.split(pkg.url, "/", context.temp_allocator)
		pkg.name = parts[len(parts) - 1]
	}

	if pkg.build_command == "" {
		return false
	}

	return true
}

parse_json_file :: proc(data: []byte) -> ([]Package, File_Error) {
	packages := []Package{}
	err := json.unmarshal(data, &packages)
	if err != nil {
		return nil, File_Error.Parsing_File
	}
	return packages, nil
}

parse_jsonl_file :: proc(data: []byte) -> ([]Package, File_Error) {
	lines := strings.split_lines(string(data), context.temp_allocator)

	packages_dyn := make([dynamic]Package, context.temp_allocator)

	for line in lines {
		line := strings.trim_space(line)
		if len(line) == 0 {
			continue
		}

		pkg: Package
		err := json.unmarshal_string(line, &pkg)
		if err != nil {
			return nil, File_Error.Parsing_File
		}
		append(&packages_dyn, pkg)
	}

	return packages_dyn[:], nil
}

parse_yaml_file :: proc(data: []byte) -> ([]Package, File_Error) {
	// Placeholder for YAML parsing logic
	// TODO: Implement YAML parsing here using a suitable library or custom parser
	return nil, File_Error.Unsupported_Extension
}

parse_repo_file :: proc(file_path: string) -> ([]Package, File_Error) {
	if !os.exists(file_path) {
		return nil, File_Error.File_Not_Found
	}

	VALID_EXTENSIONS := []string{"json", "yaml", "yml", "jsonl"}
	extensions := strings.split(file_path, ".")
	extension := extensions[len(extensions) - 1]
	if !slice.contains(VALID_EXTENSIONS, extension) {
		err_msg := fmt.tprintfln("Unsupported file extension: %s", extension)
		return nil, File_Error.Unsupported_Extension
	}

	data, err := os.read_entire_file(file_path, context.temp_allocator)
	if err != nil {
		return nil, File_Error.Reading_File
	}

	if len(data) == 0 {
		return nil, File_Error.Empty_File
	}

	switch extension {
	case "json":
		return parse_json_file(data)
	case "jsonl":
		return parse_jsonl_file(data)
	case "yaml", "yml":
		return parse_yaml_file(data)
	}

	return nil, nil
}
