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
	tokens, err := lex_yaml(data)
	if err != nil {
		return nil, File_Error.Parsing_File
	}

	if len(tokens) == 0 {
		return nil, File_Error.Empty_File
	}

	return parse_yaml_tokens_to_package(tokens), File_Error.nil
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
