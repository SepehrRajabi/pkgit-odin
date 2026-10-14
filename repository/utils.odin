package repository

import "core:fmt"
import "core:os"
import "core:strings"
import "core:text/regex"


is_ascii_letters :: proc(s: string) -> bool {
	for i := 0; i < len(s); i += 1 {
		b := s[i]
		is_upper := b >= 'A' && b <= 'Z'
		is_lower := b >= 'a' && b <= 'z'

		if !is_upper && !is_lower {
			return false
		}
	}
	return true
}

URL_PATTERN :: `^https?://`
URL_REGEX: regex.Regular_Expression
IS_URL_REGEX_INITIALIZED: bool = false

initialize_url_regex :: proc() -> regex.Regular_Expression {
	if !IS_URL_REGEX_INITIALIZED {
		url_regex, err := regex.create(URL_PATTERN)
		if err != nil {
			fmt.println("Failed to compile URL regex:", err)
			os.exit(1)
		}
		URL_REGEX = url_regex
		IS_URL_REGEX_INITIALIZED = true
	}
	return URL_REGEX
}

Token :: struct {
	type:  string,
	value: union {
		int,
		string,
	},
}

lex_yaml :: proc(data: []byte) -> ([]Token, File_Error) {
	tokens := make([dynamic]Token, context.temp_allocator)

	lines := strings.split_lines(string(data), context.temp_allocator)
	for line in lines {
		if strings.trim_space(line) == "" || strings.starts_with(line, "#") {
			continue
		}

		stripped := strings.trim_left(line, " ")
		indent_count := len(line) - len(stripped)
		if indent_count != 0 {
			t := Token{"INDENT", indent_count}
			append(&tokens, t)
		}

		if strings.contains(stripped, ":") {
			parts := strings.split_n(stripped, ":", 2, context.temp_allocator)
			key := strings.trim_space(parts[0])
			value := strings.trim_space(parts[1])

			append(&tokens, Token{"KEY", key})
			append(&tokens, Token{"VALUE", value})
		} else {
			append(&tokens, Token{"VALUE", stripped})
		}
	}

	return tokens[:], File_Error.nil
}

create_splits :: proc(tokens: []Token) -> []int {
	indices := make([dynamic]int, context.temp_allocator)

	for i := 0; i < len(tokens) - 1; i += 1 {
		current := tokens[i]
		next := tokens[i + 1]

		hit_new_package :=
			current.type == "KEY" &&
			current.value.(string) != "" &&
			next.type == "VALUE" &&
			next.value.(string) == ""

		if hit_new_package {
			append(&indices, i)
		}
	}

	return indices[:]
}

parse_yaml_tokens_to_package :: proc(tokens: []Token) -> []Package {
	packages := make([dynamic]Package, context.temp_allocator)

	indecies := create_splits(tokens)
	for i := 0; i < len(indecies); i += 1 {
		pkg := Package{}

		start := indecies[i]
		end := len(tokens)
		if i + 1 < len(indecies) {
			end = indecies[i + 1]
		}
		split := tokens[start:end]

		update_package_fields(split, &pkg)
		append(&packages, pkg)
	}

	return packages[:]
}

update_package_fields :: proc(split: []Token, p: ^Package) -> ^Package {
	for i := 0; i + 1 < len(split); i += 1 {
		current := split[i]
		next := split[i + 1]
		if current.type != "KEY" || next.type != "VALUE" {
			continue
		}

		key := current.value.(string)
		value := next.value.(string)
		if value == "" && key != "url" && key != "build_command" {
			p.name = key
		}

		switch key {
		case "url":
			p.url = value
		case "build_command":
			p.build_command = value
		}
	}

	return p
}
